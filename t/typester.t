use strict;
use warnings;
use Test::More;
use t::Util;

my $out = run_test('t/plx/typester.plx');
like $out, qr/1はOKなはず！/;

done_testing;

