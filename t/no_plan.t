use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $tap = run_test('t/plx/no_plan.plx');
exit_status_is(0);

my $result = parse_tap($tap);
ok(!$result->has_problems, 'no problem');

done_testing;
