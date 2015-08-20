use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $tap = run_test('t/plx/subtest_ok.plx');
exit_status_is(0);

my $result = parse_tap($tap);
is($result->passed, $result->plan, 'all planned tests pass');

done_testing;

