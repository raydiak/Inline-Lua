use v6;

use Test;

plan 4;

use Inline::Lua;

ok 1, 'Module loads successfully';

my $L;

isa_ok $L = Inline::Lua.new, Inline::Lua, '.new() works';

lives_ok { $L.run('return') }, '.run() works';

ok $L.run(
    'local args = {...}; local n = 1; for i = 2, args[1] do n = n * i end; return n',
    170 ) > 1e300,
    'README example works';

done;
