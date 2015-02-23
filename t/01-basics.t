use v6;

use Test;

plan 6;

use Inline::Lua;

ok 1, 'Module loads successfully';

my $L;

isa_ok $L = Inline::Lua.new, Inline::Lua, '.new() works';

lives_ok { $L.run('return') }, '.run() works';

{
    my $answer = 5e13 + 5e6;

    my $code = q:to/END/;
        local args = {...}
        local n = 0

        for i = 1, args[1] do
            n = n + i
        end

        return n
    END
    my ($arg, $sum) = 1e7; # arg reduced by e1 from README

    $sum = $L.run: $code, $arg;
    ok $sum == $answer, 'README example #1 works';

    my $func = "function sum (...)\n $code\n end";
    $L.run: $func;
    $sum = $L.call: 'sum', $arg;
    ok $sum == $answer, 'README example #2 works';

    my &sum = $L.get-global: 'sum';
    $sum = sum $arg;
    ok $sum == $answer, 'README example #3 works';
}

done;
