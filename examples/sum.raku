#!/usr/bin/env raku

use lib $?FILE.IO.parent.parent.child: 'lib';

use Inline::Lua;

sub rakuintsum (int $c) {
    my int $n = 0;
    loop (my int $i = 1; $i <= $c; $i = $i + 1) {
        $n = $n + $i;
    }
    $n;
};

sub rakunumsum (num $c) {
    my num $n = 0e0;
    loop (my num $i = 1e0; $i <= $c; $i = $i + 1e0) {
        $n = $n + $i;
    }
    $n;
};

sub rakunum64sum (num64 $c) {
    my num64 $n = 0e0;
    loop (my num64 $i = 1e0; $i <= $c; $i = $i + 1e0) {
        $n = $n + $i;
    }
    $n;
};

my &luasum = Inline::Lua.new().run: Q:to/ENDLUA/;
    function sum (c)
        local n = 0
        for i = 1, c do
            n = n + i
        end

        return n
    end

    return sum
ENDLUA

my %t;

my $i = @*ARGS ?? +@*ARGS[0] !! 1e7;

say "lua...";
%t<lua>.push: now;
say luasum $i;
%t<lua>.push: now;

say "rakuint...";
%t<rakuint>.push: now;
say rakuintsum $i.Int;
%t<rakuint>.push: now;

say "rakunum...";
%t<rakunum>.push: now;
say rakunumsum $i.Num;
%t<rakunum>.push: now;

say "rakunum64...";
%t<rakunum64>.push: now;
say rakunum64sum $i.Num;
%t<rakunum64>.push: now;

say '';
for %t {
    say "$_.key(): { [R-] |@(.value) }";
}

