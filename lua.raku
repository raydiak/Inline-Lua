#!/usr/bin/env raku

# This script acts roughly like lua <file> or lua -e <code> and probably
# isn't very useful outside of testing during development

use lib $?FILE.IO.parent.child: 'lib';

use Inline::Lua;

sub MAIN (Str $file is copy, *@args, Bool :$jit, Bool :$e) {
    my $L = do given $jit { # JIT selection
        when $_ eqv True { Inline::Lua.new: :lua<JIT> } # yes
        when $_ eqv False { Inline::Lua.new: :!auto } # no
        Inline::Lua.new # detect
    };

    $file = $file.IO.slurp unless $e;

    my @results = $L.run: $file, @args;

    given +@results {
        when 0 { }
        when 1 {
            say "--- Returned @results[0].raku()";
        }
        default {
            say "--- Returned\n{ @results».raku.join("\n").indent(4) }";
        }
    }

    True;
}


