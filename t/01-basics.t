use v6;

use Test;

plan 4;

use Inline::Lua;

ok 1, 'Module loads successfully';

my $L;

isa_ok $L = Inline::Lua.new, Inline::Lua, '.new() works';

lives_ok { $L.run('return') }, '.run() works';

ok $L.run(q:to/END/, 1e8) == 5e15 + 5e7,
        local args = {...}
        local n = 0

        for i = 1, args[1] do
            n = n + i
        end

        return n
    END
    'README example works';

done;
