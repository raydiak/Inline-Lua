#!/usr/bin/env perl6

constant $root = $?FILE.IO.parent.parent;
use lib $root.child: 'lib';
use lib $root.child('blib').child: 'lib';

use Inline::Lua;

sub perlintsum (int $c) {
    my int $n = 0;
    loop (my int $i = 1; $i <= $c; $i = $i + 1) {
        $n = $n + $i;
    }
    $n;
};

sub perlnumsum (num $c) {
    my num $n = 0e0;
    loop (my num $i = 1e0; $i <= $c; $i = $i + 1e0) {
        $n = $n + $i;
    }
    $n;
};

my &luasum = Inline::Lua.new(:!auto).run: Q:to/ENDLUA/;
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

my $i = @*ARGS ?? +@*ARGS[0] !! 1;

say "lua...";
%t<lua>.push: now;
say luasum $i;
%t<lua>.push: now;

say "perlint...";
%t<perlint>.push: now;
say perlintsum $i.Int;
%t<perlint>.push: now;

say "perlnum...";
%t<perlnum>.push: now;
say perlnumsum $i.Num;
%t<perlnum>.push: now;

say '';
for %t {
    say "$_.key(): { [R-] |@(.value) }";
}

