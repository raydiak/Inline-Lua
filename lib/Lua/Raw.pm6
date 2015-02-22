module Lua::Raw;

use NativeCall;

my $lib;
BEGIN {
    $lib = $*VM.config<dll> ~~ /dll/ ??
        'lua5.1' !! 'liblua5.1';
        #'luajit-5.1' !! 'libluajit-5.1';
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

our %LUA_STATUS is export =
    1 => 'YIELD',
    2 => 'ERRRUN',
    3 => 'ERRSYNTAX',
    4 => 'ERRMEM',
    5 => 'ERRERR';

