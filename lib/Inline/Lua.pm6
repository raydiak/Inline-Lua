class Inline::Lua;

use Lua::Raw;

has $!L = self!build_state;

method !build_state () {
    my $L = luaL_newstate;
    luaL_openlibs $L;

    $L;
}

method run (Str:D $code, *@args) {
    my $top = lua_gettop $!L;

    ensure
        :e<Compilation failed>,
        luaL_loadstring $!L, $code;

    self.value-to-lua: $_ for @args;

    ensure
        :e<Execution failed>,
        lua_pcall $!L, +@args, -1, 0;

    my @return;
    my $elems = lua_gettop($!L) - $top;
    
    if $elems > 1 {
        @return.push: self.value-to-perl($top + $_) for 1..$elems;
        lua_settop $!L, $top;
    } elsif $elems == 1 {
        @return = self.value-to-perl: $top + 1;
        lua_settop $!L, $top;
    }

    return |@return;
}

method value-to-perl (Int:D $i is copy) {
    $i = lua_gettop($!L) + $i + 1 if $i < 0;
    $_ = lua_typename $!L, lua_type $!L, $i;

    when 'boolean' { ?lua_toboolean $!L, $i };
    when 'number'  { +lua_tonumber  $!L, $i };
    when 'string'  { ~lua_tolstring  $!L, $i };
    when 'table' {
        my %table := :{};
        lua_pushnil $!L;
        while lua_next $!L, $i {
          my $key = self.value-to-perl(-2);
          my $value = self.value-to-perl(-1);
          %table{$key} = $value;
          lua_settop $!L, -2;
        }
        return $%table;
    };

    fail "Converting Lua $_ values to Perl is NYI";
}

method value-to-lua ($_) {
    when !.defined { lua_pushnil $!L }
    when Bool { lua_pushboolean $!L, $_.Num }
    when Positional | Associative {
        my $positional = ($_ ~~ Positional);
        lua_createtable $!L, 0, 0;
        for .pairs {
            my $key = .key;
            $key = $key + 1 if $positional && $key ~~ Int;
            self.value-to-lua: $key;
            self.value-to-lua: .value;
            lua_rawset $!L, -3;
        }
    }
    when Numeric { lua_pushnumber $!L, $_.Num }
    when Stringy { lua_pushstring $!L, ~$_ }

    fail "Converting $_.WHAT().name() values to Lua is NYI";
}

sub ensure ($code, :$e is copy) {
    if $code {
        my $msg = "Error $code %LUA_STATUS{$code}";
        fail $e ?? "$e\n$msg" !! $msg;
    }
}

