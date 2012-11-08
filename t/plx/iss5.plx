use strict;
use warnings;

use Test::More;

subtest 'hoge' => sub {
    ok 1;

    die;

    ok 2;
};

done_testing;
