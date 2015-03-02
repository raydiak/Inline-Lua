use Inline::Lua::Util;
use Lua::Raw;



role Inline::Lua::Object {

has $.lua = die "lua is a required attribute";
has $.ref;

method from-stack (:$keep, |args) {
    self.new(|args).ref-from-stack: :$keep;
}

method ref-from-stack (:$keep) {
    my $ref = $!lua.ref-from-stack: :$keep;
    self.unref;
    $!ref = $ref;

    self;
}

method get () {
    Lua::Raw::lua_rawgeti $!lua.state, 1, $!ref;

    self;
}

method unref () {
    if defined $!ref {
        $!lua.unref: $!ref;
        $!ref = Any;
    }

    self;
}

multi submethod DESTROY (|) {
    self.unref;
    nextsame;
}

} # close ::Object



class Inline::Lua::Function {
also does Inline::Lua::Object;
also is Block;
has $.arity = 0;
has $.count = Inf;
has $.signature = :(*@);

method call (*@args, :$stack) {
    self.get unless $stack;

    my $top = Lua::Raw::lua_gettop(self.lua.state) - 1;

    self.lua.values-to-lua: @args;

    ensure
        :e<Execution failed>,
        Lua::Raw::lua_pcall self.lua.state, +@args, -1, 0;

    self.lua.values-from-lua: Lua::Raw::lua_gettop(self.lua.state) - $top;
}

method postcircumfix:<( )> (|args) { self.call(|args) }

} # close ::Function



class Inline::Lua::TableObj {

has $.inline-lua-table;

multi submethod BUILD (:table($!inline-lua-table), |) {
    nextsame;
}

::?CLASS.HOW.add_fallback(::?CLASS, -> $, $ { True },
    method ($name) {
        -> $self, |args {
            my \val = $!inline-lua-table{$name};
            args<call> !eqv False && val ~~ Callable ??
                val.($!inline-lua-table, args.list) !!
                val;
        }
    }
);

} # close ::TableObj



class Inline::Lua::Table {
also does Inline::Lua::Object;
also does Positional;
also does Associative;

method of () { Mu }


### positional stuff

method elems (:$stack, :$leave = $stack) {
    self.get unless $stack;
    my $len = Lua::Raw::lua_objlen self.lua.state, -1;
    Lua::Raw::lua_settop self.lua.state, -2 unless $leave;
    $len;
}

method exists_pos ($i) { $i %% 1 && 0 < $i < self.elems }

method at_pos ($i, :$stack, :$leave = $stack) {
    self.get unless $stack;
    self.lua.value-to-lua: $i + 1;
    Lua::Raw::lua_gettable self.lua.state, -2;
    my \val = self.lua.value-from-lua;
    Lua::Raw::lua_settop self.lua.state, -2 unless $leave;
    val;
}

method list (:$stack, :$leave = $stack) {
    self.get unless $stack;
    my @vals;
    @vals[$_] = self.at_pos($_, :stack) for ^self.elems(:stack);
    Lua::Raw::lua_settop self.lua.state, -2 unless $leave;
    @vals;
}


### associative stuff

method at_key ($k, :$stack, :$leave = $stack) {
    self.get unless $stack;
    self.lua.value-to-lua: $k;
    Lua::Raw::lua_gettable self.lua.state, -2;
    my \val = self.lua.value-from-lua;
    Lua::Raw::lua_settop self.lua.state, -2 unless $leave;
    val;
}

method exists_key ($k, :$stack, :$leave = $stack) {
    self.get unless $stack;
    self.lua.value-to-lua: $k;
    Lua::Raw::lua_gettable self.lua.state, -2;
    my $ret = Lua::Raw::lua_isnil self.lua.state, -1;
    Lua::Raw::lua_settop self.lua.state, $leave ?? -2 !! -3;
    ?$ret;
}

method keys (:$stack, :$leave = $stack) {
    self.get unless $stack;
    my @ret;
    Lua::Raw::lua_pushnil self.lua.state;
    while Lua::Raw::lua_next self.lua.state, -2 {
        Lua::Raw::lua_settop self.lua.state, -2;
        @ret[+*] = self.lua.value-from-lua: :keep;
    }
    Lua::Raw::lua_settop self.lua.state, -2 unless $leave;
    @ret;
}

method kv (:$stack, :$leave = $stack) {
    self.get unless $stack;
    my @ret;
    Lua::Raw::lua_pushnil self.lua.state;
    while Lua::Raw::lua_next self.lua.state, -2 {
        my \v = self.lua.value-from-lua;
        my \k = self.lua.value-from-lua: :keep;
        @ret[+*] = k;
        @ret[+*] = v;
    }
    Lua::Raw::lua_settop self.lua.state, -2 unless $leave;
    @ret;
}

method pairs (:$stack, :$leave = $stack) {
    self.get unless $stack;
    my @ret;
    Lua::Raw::lua_pushnil self.lua.state;
    while Lua::Raw::lua_next self.lua.state, -2 {
        @ret[+*] = Pair.new:
            :value( self.lua.value-from-lua ),
            :key(   self.lua.value-from-lua: :keep );
    }
    Lua::Raw::lua_settop self.lua.state, -2 unless $leave;
    @ret;
}

method hash (:$stack, :$leave = $stack) {
    self.get unless $stack;
    my %ret{Any};
    Lua::Raw::lua_pushnil self.lua.state;
    while Lua::Raw::lua_next self.lua.state, -2 {
        my \v = self.lua.value-from-lua;
        my \k = self.lua.value-from-lua: :keep;
        %ret{k} = v;
    }
    Lua::Raw::lua_settop self.lua.state, -2 unless $leave;
    %ret;
}


### object stuff

method invoke ($method is copy, |args) {
    $method = self.at_key($method) unless $method ~~ Callable;
    $method(self, |args)
}

method sink () { self }

has $.obj handles ** = Inline::Lua::TableObj.new: table => self;


} # close ::Table



role LuaParent[$parent] is export {

has $!self = do {
    Lua::Raw::lua_createtable $parent.lua.state, 0, 0;
    Inline::Lua::Table.from-stack: :lua($parent.lua);
};

::?CLASS.HOW.add_fallback(::?CLASS, -> $, $ { True },
    method ($name) {
        -> $self, |args {
            $parent{$name}($!self, args.list);
        }
    }
);

} # close LuaParent





