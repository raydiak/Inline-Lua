unit class Inline::Lua;

use NativeCall;
use Lua::Raw;
use Inline::Lua::Object;

our $.default-lua = Any;

has $.raw = die 'raw is required';
has $.state = self.new-state;
has $.index = self.new-index;
has %.refcount;
has %.ptrref;

method new (Bool :$auto, Str :$lua, Str :$lib, :$raw is copy, |args) {
    my $new;
    if !$raw && $auto !eqv False && ($lib, $lua)».defined.none {
        $new = try { self.new: :lua<JIT>, |args };
        $new //= self.new: :!auto, |args;
    } else {
        if !$raw {
            my %raw-args = (:$lua, :$lib).grep: *.value.defined;
            $raw = Lua::Raw.new: |%raw-args;
        }
        $new = Inline::Lua.bless: :$raw, |args;
    }
    Inline::Lua.default-lua //= $new;
}

method new-state () {
    my $L = $!raw.luaL_newstate;
    $!raw.luaL_openlibs: $L;

    $L;
}

method new-index () {
    $!raw.lua_createtable: $!state, 0, 0;
    $!raw.lua_gettop: $!state;
}

method ref-to-stack ($ref) {
    $!raw.lua_rawgeti: $!state, $!index, $ref;
}

method ref-from-stack (:$keep, :$weak, :$ptr is copy) {
    $ptr //= $!raw.lua_topointer: $!state, -1;
    my $ref := %!ptrref{+$ptr};

    if !defined $ref {
        $ref = $!raw.luaL_ref: $!state, $!index;
        $!raw.lua_rawgeti: $!state, $!index, $ref if $keep;
    } else {
        $!raw.lua_settop: $!state, -2 unless $keep;
    }

    %!refcount{$ref}++ unless $weak;

    $ref;
}

method unref ($ref) {
    unless --%!refcount{$ref} {
        %!refcount{$ref} :delete;
        $!raw.luaL_unref: $!state, $!index, $ref;
    }
}

method require (Str:D $name, :$set) {
    state &lua-require //= self.get-global: 'require';

    my $table = lua-require $name;

    self.set-global: $name, $table if $set eqv True;

    $table;
}

method get-global (Str:D $name) {
    self!get-global: $name;
    self.value-from-lua;
}

method !get-global (Str:D $name) {
    $!raw.lua_getfield: $!state, $!raw.LUA_INDEX<GLOBALS>, $name;
}

method set-global (Str:D $name, $val) {
    self.value-to-lua: $val;
    self!set-global: $name;
}

method !set-global (Str:D $name) {
    $!raw.lua_setfield: $!state, $!raw.LUA_INDEX<GLOBALS>, $name;
}

method run (Str:D $code, **@args) {
    self.ensure:
        :e<Compilation failed>,
        $!raw.luaL_loadstring: $!state, $code;

    self!call: @args;
}

method call (Str:D $name, **@args) {
    self!get-global: $name;
    self!call: @args;
}

method !call (@args) {
    # - 1 excludes the function we're about to pop via pcall
    my $top = $!raw.lua_gettop($!state) - 1;

    self.values-to-lua: @args;

    self.ensure:
        :e<Execution failed>,
        $!raw.lua_pcall: $!state, +@args, -1, 0;

    self.values-from-lua: $!raw.lua_gettop($!state) - $top;
}

method values-from-lua (Int:D $count, |args) {
    if $count == 1 {
        self.value-from-lua(|args)
    } elsif $count > 1 {
        (^$count).map({ self.value-from-lua(|args) }).reverse # won't work with :keep
    }
}

method value-from-lua (:$keep) {
    my $type = $!raw.lua_type: $!state, -1;
    $_ = $!raw.lua_typename: $!state, $type;

    when 'table' { Inline::Lua::Table.new: :lua(self), :stack, :$keep }
    when 'function' { Inline::Lua::Function.new: :lua(self), :stack, :$keep }
    when $_ ~~ 'userdata' && $type != 2 { # light userdata is not an object
        Inline::Lua::Userdata.new: :lua(self), :stack, :$keep }
    when 'cdata' { Inline::Lua::Cdata.new: :lua(self), :stack, :$keep }

    my $val = do {
        when 'boolean' { ?$!raw.lua_toboolean: $!state, -1 }
        when 'number'  { +$!raw.lua_tonumber:  $!state, -1 }
        when 'string'  { ~$!raw.lua_tolstring:  $!state, -1, Pointer[void] }
        when 'userdata' { $!raw.lua_topointer: $!state, -1 }
        when 'nil'     { Any }
        Failure;
    };

    $!raw.lua_settop: $!state, -2 unless $keep;

    fail "Converting Lua $_ values to Raku is NYI" if $val ~~ Failure;

    $val;
}

method values-to-lua (@vals) {
    self.value-to-lua: $_ for @vals;
}

method value-to-lua ($_) {
    when !.defined { $!raw.lua_pushnil: $!state }
    when Bool { $!raw.lua_pushboolean: $!state, Int($_) }
    when Inline::Lua::WrapperObj { $_.inline-lua-object.get }
    when Inline::Lua::Object { $_.get }
    when Positional | Associative {
        $!raw.lua_createtable: $!state, 0, 0;
        if $_ ~~ Positional {
            my $key = 1;
            for .list {
                self.value-to-lua: $key++;
                self.value-to-lua: $_;
                $!raw.lua_rawset: $!state, -3;
            }
        }
        if $_ ~~ Associative {
            for .pairs {
                self.value-to-lua: .key;
                self.value-to-lua: .value;
                $!raw.lua_rawset: $!state, -3;
            }
        }
    }
    when Pointer { $!raw.lua_pushlightuserdata: $!state, $_ }
    when Numeric { $!raw.lua_pushnumber: $!state, Num($_) }
    when Stringy { $!raw.lua_pushstring: $!state, ~$_ }

    fail "Converting $_.WHAT().^name() values to Lua is NYI";
}

method ensure ($code, :$e is copy) {
    if $code {
        my $msg = "Error $code $!raw.LUA_STATUS(){$code}";
        fail $e ?? "$e\n$msg" !! $msg;
    }
}

role LuaParent[Str:D $parent] is export {
    method sink () { self }
    method FALLBACK (|args) {
        Inline::Lua.default-lua.get-global($parent).invoke: |args;
    }
}

multi sub EVAL(Cool $code, Str :$lang where { ($lang // '') eq 'Lua' }, PseudoStash :$context) is export {
    my $lua = Inline::Lua.default-lua // Inline::Lua.new;
    $lua.run($code);
}

#`[[[ has problems, one being that $parent is needed at compose time
role LuaParent[Inline::Lua::Table:D $parent] {
    method sink () { self }
    method FALLBACK (|args) {
        $parent.invoke: |args;
    }
}
#]]]


