unit class Lua::Raw;

use NativeCall;

our sub luaL_newstate ()
    returns Pointer[void]
{...}

our sub luaL_openlibs (
    Pointer $ )
{...}

our sub luaL_loadstring (
    Pointer $,
    Str $ )
    returns int32
{...}

our sub lua_pcall (
    Pointer $,
    int32 $,
    int32 $,
    int32 $ )
    returns int32
{...}

our sub lua_type (
    Pointer $,
    int32 $ )
    returns int32
{...}

our sub lua_typename (
    Pointer $,
    int32 $ )
    returns Str
{...}

our sub lua_toboolean (
    Pointer $,
    int32 $ )
    returns int32
{...}

our sub lua_tonumber (
    Pointer $,
    int32 $ )
    returns num64
{...}

our sub lua_tolstring (
    Pointer $,
    int32 $,
    Pointer $ ) # = Pointer[void] breaks here, TODO reduce and report
    returns Str
{...}

our sub lua_gettop (
    Pointer $ )
    returns int32
{...}

our sub lua_settop (
    Pointer $,
    int32 $ )
{...}

our sub lua_next (
    Pointer $,
    int32 $ )
    returns int32
{...}

our sub lua_pushnil (
    Pointer $ )
{...}

our sub lua_pushnumber (
    Pointer $,
    num64 $ )
{...}

our sub lua_pushstring (
    Pointer $,
    Str $ )
{...}

our sub lua_pushboolean (
    Pointer $,
    int32 $ )
{...}

our sub lua_pushlightuserdata (
    Pointer $,
    Pointer $ )
{...}

our sub lua_createtable (
    Pointer $,
    int32 $,
    int32 $ )
{...}

our sub lua_rawgeti (
    Pointer $,
    int32 $,
    int32 $ )
{...}

our sub lua_rawset (
    Pointer $,
    int32 $ )
{...}

our sub lua_getfield (
    Pointer $,
    int32 $,
    Str $ )
{...}

our sub lua_setfield (
    Pointer $,
    int32 $,
    Str $ )
{...}

our sub luaL_ref (
    Pointer $,
    int32 $ )
    returns int32
{...}

our sub luaL_unref (
    Pointer $,
    int32 $,
    int32 $ )
{...}

our sub lua_topointer (
    Pointer $,
    int32 $ )
    returns Pointer[void]
{...}

our sub lua_objlen (
    Pointer $,
    int32 $ )
    returns int32
{...}

our sub lua_gettable (
    Pointer $,
    int32 $ )
{...}

our sub lua_settable (
    Pointer $,
    int32 $ )
{...}

our %.LUA_STATUS =
    1 => 'YIELD',
    2 => 'ERRRUN',
    3 => 'ERRSYNTAX',
    4 => 'ERRMEM',
    5 => 'ERRERR';

our %.LUA_INDEX =
    REGISTRY => -10000,
    ENVIRON => -10001,
    GLOBALS => -10002;

has $.lua;
has $.lib = do {
    my $lib = ($!lua //= '5.1');
    $lib = 'jit-5.1' if $lib.uc eq 'JIT';
    warn "Attempting to use unsupported Lua version '$lib'; this is likely to fail"
        unless $lib eq <5.1 jit-5.1>.any;
    $lib = "lua$lib";
};
# different distros use different numbering schemes
    # e.g. liblua5.1.so.0 (debian) vs liblua5.1.so.5.1 (arch)
    # so don't use explicit library version numbers
#has $.lib-ver = $!lib eq 'luajit-5.1' ?? v2 !! v0;

# mainly make this private to omit from .raku
has %!subs = do {
    my %subs;
    for Lua::Raw:: {
        my $name = .value.name;
        next unless $name ~~ /^ luaL?_/;
        my $sub = .value;
        next unless $sub ~~ Sub;
        $sub .= clone;
        trait_mod:<is>($sub, :native(self.lib));#, self.lib-ver));
        %subs{$name} = $sub;
    };
    %subs;
};
# TODO reduce and report, this now shoves the whole array into the first key
#    Lua::Raw::.grep({ .key ~~ /^ \&luaL?_/ })».value.map: {
#        # runtime NativeCall technique forked from Inline::Python
#        $_.name => trait_mod:<is>($_.clone, :native(self.lib));
#    };

method sink () { self }
method FALLBACK ($name, |args) { %!subs{$name}(|args) }


