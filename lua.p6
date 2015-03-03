#!/usr/bin/env perl6

constant $root = $?FILE.IO.parent;
use lib $root.child('lib');
use lib $root.child('blib').child('lib');

use Inline::Lua;

sub MAIN (Str $file is copy, *@args, Bool :$jit, Bool :$e) {
    my $L = Inline::Lua.new: :lua($jit ?? 'JIT' !! '5.1');

    $file = $file.IO.slurp unless $e;

    my @results = $L.run: $file, @args;

    given +@results {
        when 0 { }
        when 1 {
            say "--- Returned @results[0].perl()";
        }
        default {
            say "--- Returned\n{ @results».perl.join("\n").indent(4) }";
        }
    }

    True;
}


