module Inline::Lua::Util;
#use Lua::Raw;

sub ensure ($code, :$e is copy) is export {
    if $code {
        #my $msg = "Error $code %Lua::Raw::LUA_STATUS{$code}";
        my $msg = "Error $code";
        fail $e ?? "$e\n$msg" !! $msg;
    }
}

