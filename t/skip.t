use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $tap = run_test('t/plx/skip.plx');
exit_status_is(0);

my $result = parse_tap($tap);
is($result->passed, $result->plan, 'plan must be same');
ok(!$result->has_problems, 'has problems');

done_testing;

