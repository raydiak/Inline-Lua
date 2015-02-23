module Lua::Raw;

use NativeCall;

my $lib;

BEGIN {
    if my $envlib = %*ENV<PERL6_LUA_RAW_LIBRARY> {
        $lib = $envlib;
    } else {
        $lib = (my $ver = %*ENV<PERL6_LUA_RAW_VERSION>) ??
            $ver !! '5.1';
        $lib = 'jit-5.1' if $lib eq 'jit';
        warn "Attempting to use unsupported Lua version '$lib'; this is likely to fail"
            if $lib ∉ <5.1 jit-5.1>;
        $lib = "lua$lib";
        $lib = 'lib' ~ $lib unless $*VM.config<dll> ~~ /dll/;
    }
}

our sub luaL_newstate ()
    returns OpaquePointer
    is native($lib)
    is export
{*}

our sub luaL_openlibs (
    OpaquePointer $ )
    is native($lib)
    is export
{*}

our sub luaL_loadstring (
    OpaquePointer $,
    Str $ )
    returns int32
    is native($lib)
    is export
{*}

our sub lua_pcall (
    OpaquePointer $,
    int32 $,
    int32 $,
    int32 $ )
    returns int32
    is native($lib)
    is export
{*}

our sub lua_type (
    OpaquePointer $,
    int32 $ )
    returns int32
    is native($lib)
    is export
{*}

our sub lua_typename (
    OpaquePointer $,
    int32 $ )
    returns Str
    is native($lib)
    is export
{*}

our sub lua_toboolean (
    OpaquePointer $,
    int32 $ )
    returns int32
    is native($lib)
    is export
{*}

our sub lua_tonumber (
    OpaquePointer $,
    int32 $ )
    returns num64
    is native($lib)
    is export
{*}

our sub lua_tolstring (
    OpaquePointer $,
    int32 $,
    OpaquePointer $ = OpaquePointer )
    returns Str
    is native($lib)
    is export
{*}

our sub lua_gettop (
    OpaquePointer $ )
    returns int32
    is native($lib)
    is export
{*}

our sub lua_settop (
    OpaquePointer $,
    int32 $ )
    is native($lib)
    is export
{*}

our sub lua_next (
    OpaquePointer $,
    int32 $ )
    returns int32
    is native($lib)
    is export
{*}

our sub lua_pushnil (
    OpaquePointer $ )
    is native($lib)
    is export
{*}

our sub lua_pushnumber (
    OpaquePointer $,
    num64 $ )
    is native($lib)
    is export
{*}

our sub lua_pushstring (
    OpaquePointer $,
    Str $ )
    is native($lib)
    is export
{*}

our sub lua_pushboolean (
    OpaquePointer $,
    int32 $ )
    is native($lib)
    is export
{*}

our sub lua_createtable (
    OpaquePointer $,
    int32 $ = 0,
    int32 $ = 0 )
    is native($lib)
    is export
{*}

our sub lua_rawset (
    OpaquePointer $,
    int32 $ )
    is native($lib)
    is export
{*}

our sub lua_getfield (
    OpaquePointer $,
    int32 $,
    Str $ )
    is native($lib)
    is export
{*}

our sub lua_setfield (
    OpaquePointer $,
    int32 $,
    Str $ )
    is native($lib)
    is export
{*}

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

