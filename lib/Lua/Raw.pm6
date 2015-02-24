module Lua::Raw;

use NativeCall;

# forked from https://github.com/niner/Inline-Python/blob/a56127508d0dc47313bde38cfacc18e599471a50/lib/Inline/Python.pm6#L10-25 ; nine++
sub native (Sub $sub) {
    state $lib //=
        defined(my $envlib = %*ENV<PERL6_LUA_RAW_LIBRARY>) ??
            $envlib !!
            do {
                my $l = %*ENV<PERL6_LUA_RAW_VERSION>;
                $l //= '5.1';
                $l = 'jit-5.1' if $l.lc eq 'jit';
                warn "Attempting to use unsupported Lua version '$l'; this is likely to fail"
                    if $l ∉ <5.1 jit-5.1>;
                $l = "lua$l";
                $l = 'lib' ~ $l unless $*VM.config<dll> ~~ /dll/;
                $l;
            };

    trait_mod:<is>($sub, :native($lib));
}

our sub luaL_newstate ()
    returns OpaquePointer
    is export {...}
    native(&luaL_newstate);

our sub luaL_openlibs (
    OpaquePointer $ )
    is export {...}
    native(&luaL_openlibs);

our sub luaL_loadstring (
    OpaquePointer $,
    Str $ )
    returns int32
    is export {...}
    native(&luaL_loadstring);

our sub lua_pcall (
    OpaquePointer $,
    int32 $,
    int32 $,
    int32 $ )
    returns int32
    is export {...}
    native(&lua_pcall);

our sub lua_type (
    OpaquePointer $,
    int32 $ )
    returns int32
    is export {...}
    native(&lua_type);

our sub lua_typename (
    OpaquePointer $,
    int32 $ )
    returns Str
    is export {...}
    native(&lua_typename);

our sub lua_toboolean (
    OpaquePointer $,
    int32 $ )
    returns int32
    is export {...}
    native(&lua_toboolean);

our sub lua_tonumber (
    OpaquePointer $,
    int32 $ )
    returns num64
    is export {...}
    native(&lua_tonumber);

our sub lua_tolstring (
    OpaquePointer $,
    int32 $,
    OpaquePointer $ = OpaquePointer )
    returns Str
    is export {...}
    native(&lua_tolstring);

our sub lua_gettop (
    OpaquePointer $ )
    returns int32
    is export {...}
    native(&lua_gettop);

our sub lua_settop (
    OpaquePointer $,
    int32 $ )
    is export {...}
    native(&lua_settop);

our sub lua_next (
    OpaquePointer $,
    int32 $ )
    returns int32
    is export {...}
    native(&lua_next);

our sub lua_pushnil (
    OpaquePointer $ )
    is export {...}
    native(&lua_pushnil);

our sub lua_pushnumber (
    OpaquePointer $,
    num64 $ )
    is export {...}
    native(&lua_pushnumber);

our sub lua_pushstring (
    OpaquePointer $,
    Str $ )
    is export {...}
    native(&lua_pushstring);

our sub lua_pushboolean (
    OpaquePointer $,
    int32 $ )
    is export {...}
    native(&lua_pushboolean);

our sub lua_createtable (
    OpaquePointer $,
    int32 $ = 0,
    int32 $ = 0 )
    is export {...}
    native(&lua_createtable);

our sub lua_rawset (
    OpaquePointer $,
    int32 $ )
    is export {...}
    native(&lua_rawset);

our sub lua_getfield (
    OpaquePointer $,
    int32 $,
    Str $ )
    is export {...}
    native(&lua_getfield);

our sub lua_setfield (
    OpaquePointer $,
    int32 $,
    Str $ )
    is export {...}
    native(&lua_setfield);

our %LUA_STATUS is export =
    1 => 'YIELD',
    2 => 'ERRRUN',
    3 => 'ERRSYNTAX',
    4 => 'ERRMEM',
    5 => 'ERRERR';

our %LUA_INDEX is export =
    REGISTRY => -10000,
    ENVIRON => -10001,
    GLOBALS => -10002;

