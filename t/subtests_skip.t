use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $tap = run_test('t/plx/subtests_skip.plx');
exit_status_is(0);

my $result = parse_tap($tap);
TODO: {
    local $TODO = 'plans are inaccurate';
    is( $result->passed, $result->plan, 'plan == passed tests' );
}
ok(!$result->has_problems, 'has no problems');

done_testing;

