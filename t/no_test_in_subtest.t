use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $tap = run_test('t/plx/no_test_in_subtest.plx');
exit_status_isnt(0);

my $result = parse_tap($tap);
isnt($result->passed, $result->plan, 'plan != passed tests');

done_testing;

