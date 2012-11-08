use strict;
use warnings;
use Test::More;

my $out = `$^X -Ilib -MTest::Pretty t/plx/typester.plx`;
like $out, qr/1はOKなはず！/;

done_testing;

