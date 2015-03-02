class Inline::Lua;

use Lua::Raw;
#Lua::Raw::init;
use Inline::Lua::Util;
use Inline::Lua::Object;

has $.state = self.new-state;
has $.index = self.new-index;
has %.refcount;
has %.ptrref;

method new-state () {
    my $L = Lua::Raw::luaL_newstate;
    Lua::Raw::luaL_openlibs $L;

    $L;
}

method new-index () {
    Lua::Raw::lua_createtable $!state, 0, 0;
    Lua::Raw::lua_gettop $!state;
}

method ref-to-stack ($ref) {
    Lua::Raw::lua_rawgeti $!state, $!index, $ref;
}

method ref-from-stack (:$keep, :$weak) {
    my $ptr = Lua::Raw::lua_topointer $!state, -1;
    my $ref := %!ptrref{+$ptr};

    if !defined $ref {
        $ref = Lua::Raw::luaL_ref $!state, $!index;
        Lua::Raw::lua_rawgeti $!state, $!index, $ref if $keep;
    } else {
        Lua::Raw::lua_settop $!state, -2 unless $keep;
    }

    %!refcount{$ref}++ unless $weak;

    $ref;
}

method unref ($ref) {
    unless --%!refcount{$ref} {
        %!refcount{$ref} :delete;
        Lua::Raw::luaL_unref $!state, $!index, $ref;
    }
}

method get-global (Str:D $name, :$func is copy) {
    self!get-global: $name;
    self.value-from-lua;
}

method !get-global (Str:D $name) {
    my constant $global-index = %Lua::Raw::LUA_INDEX<GLOBALS>;
    Lua::Raw::lua_getfield $!state, $global-index, $name;
}

method set-global (Str:D $name, $val) {
    self.value-to-lua: $val;
    self!set-global: $name;
}

method !set-global (Str:D $name) {
    my constant $global-index = %Lua::Raw::LUA_INDEX<GLOBALS>;
    Lua::Raw::lua_setfield $!state, $global-index, $name;
}

method run (Str:D $code, *@args) {
    ensure
        :e<Compilation failed>,
        Lua::Raw::luaL_loadstring $!state, $code;

    self!call: @args;
}

method call (Str:D $name, *@args) {
    self!get-global: $name, :func;
    self!call: @args;
}

method !call (*@args) {
    # - 1 excludes the function we're about to pop via pcall
    my $top = Lua::Raw::lua_gettop($!state) - 1;

    self.values-to-lua: @args;

    ensure
        :e<Execution failed>,
        Lua::Raw::lua_pcall $!state, +@args, -1, 0;

    self.values-from-lua: Lua::Raw::lua_gettop($!state) - $top;
}

method values-from-lua (Int:D $count, |args) {
    $count == 1 ??
        self.value-from-lua(|args)
    !!
        (^$count).map({ self.value-from-lua(|args) }).reverse # won't work with :keep
    if $count;
}

method value-from-lua (:$keep) {
    $_ = Lua::Raw::lua_typename $!state, Lua::Raw::lua_type $!state, -1;

    when 'table' { Inline::Lua::Table.from-stack: :lua(self), :$keep }
    when 'function' { Inline::Lua::Function.from-stack: :lua(self), :$keep }

    my $val = do {
        when 'boolean' { ?Lua::Raw::lua_toboolean $!state, -1 }
        when 'number'  { +Lua::Raw::lua_tonumber  $!state, -1 }
        when 'string'  { ~Lua::Raw::lua_tolstring  $!state, -1 }
        when 'nil'     { Any }
        Failure;
    };

    Lua::Raw::lua_settop $!state, -2 unless $keep;

    fail "Converting Lua $_ values to Perl is NYI" if $val ~~ Failure;

    $val;
}

method values-to-lua (*@vals) {
    self.value-to-lua: $_ for @vals;
}

method value-to-lua ($_) {
    when !.defined { Lua::Raw::lua_pushnil $!state }
    when Bool { Lua::Raw::lua_pushboolean $!state, $_.Num }
    when Inline::Lua::TableObj { $_.inline-lua-table.get }
    when Inline::Lua::Object { $_.get }
    when Positional | Associative {
        Lua::Raw::lua_createtable $!state, 0, 0;
        if $_ ~~ Positional {
            my $key = 1;
            for .list {
                self.value-to-lua: $key++;
                self.value-to-lua: $_;
                Lua::Raw::lua_rawset $!state, -3;
            }
        }
        if $_ ~~ Associative {
            for .pairs {
                self.value-to-lua: .key;
                self.value-to-lua: .value;
                Lua::Raw::lua_rawset $!state, -3;
            }
        }
    }
    when Numeric { Lua::Raw::lua_pushnumber $!state, Num($_) }
    when Stringy { Lua::Raw::lua_pushstring $!state, ~$_ }

    fail "Converting $_.WHAT().^name() values to Lua is NYI";
}

