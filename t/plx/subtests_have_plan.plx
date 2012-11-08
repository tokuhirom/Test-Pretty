use strict;
use warnings;
use utf8;
use Test::More;

subtest 'x' => sub {
    plan tests => 4;
    ok 1 for 1..4;
};

subtest 'y' => sub {
    plan tests => 4;
    ok 1 for 1..4;
};

done_testing;

