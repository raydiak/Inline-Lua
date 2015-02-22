# Inline::Lua

This is a Perl 6 module which allows execution of Lua code from Perl 6 code.

## Requirements

Lua 5.1 is currently the only supported version. This allows LuaJIT to be used
as well, though no public option exists yet to load LuaJIT instead of Lua.
Support for other versions of Lua is planned.

Any Rakudo backend with a NativeCall implementation is expected to work, but
testing has only been done under MoarVM on x86-64 Linux.

## Status

Inline::Lua currently supports passing and returning string, number, boolean,
table, and nil values. Functions, userdata, and any other types are not
supported yet.

Tables returned from Lua are directly mapped to object hashes; there is no
array detection or index-adjustment.

Error reporting is crude, and the API is incomplete.

## Synopsis

    use Inline::Lua;
    my $L = Inline::Lua.new;

    my $quicksum = $L.run: q:to/END/, 1e8;
        local args = {...}
        local n = 0

        for i = 1, args[1] do
            n = n + i
        end

        return n
    END

    say $quicksum;

## Usage

### .new()

Creates, initializes, and returns a new Inline::Lua instance.

### .run(Str:D $code, \*@args)

Compiles $code, runs it with @args, and returns and resulting value(s).

## Contact

https://github.com/raydiak/Inline-Lua

raydiak@cyberuniverses.com

raydiak on #perl6 on irc.freenode.net

