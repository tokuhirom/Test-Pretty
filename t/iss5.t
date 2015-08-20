use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $tap = run_test('t/plx/iss5.plx');
exit_status_isnt(0);

my $result = parse_tap($tap);
isnt($result->passed, $result->plan, 'plan != passed tests');

done_testing;

