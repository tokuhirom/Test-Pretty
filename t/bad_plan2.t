use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $tap = run_test('t/plx/bad_plan2.plx');
exit_status_isnt(0);

my $result = parse_tap($tap);
ok($result->has_problems, 'has problems');

done_testing;

