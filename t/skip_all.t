use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $tap = run_test('t/plx/skip_all.plx');
exit_status_is(0);

my $result = parse_tap($tap);
ok($result->skip_all, 'got skip all');
ok(!$result->has_problems, 'has problems');

done_testing;

