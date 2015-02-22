# Inline::Lua

This is a Perl 6 module which allows execution of Lua code from Perl 6 code.

## Status

This module currently supports passing and returning string, number, boolean,
table, and nil values. Functions, userdata, and any other types are not supported yet.

Tables returned from Lua are directly mapped to object hashes - no array
detection or index-adjustment exists.

Error reporting is crude, and the API is incomplete.

## Synopsis

    use Inline::Lua;
    my $L = Inline::Lua.new;
    my $fastfact = $L.run:
        'local args = {...}; local n = 1; for i = 2, args[1] do n = n * i end; return n',
        170;
    say $fastfact;

## Usage

### .new()

Creates, initializes, and returns a new Inline::Lua instance.

### .run(Str:D $code, \*@args)

Compiles $code, runs it with @args, and returns and resulting value(s).

## Contact

https://github.com/raydiak/Inline-Lua

raydiak@cyberuniverses.com

raydiak on #perl6 on irc.freenode.net

