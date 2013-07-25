use strict;
use warnings;
use utf8;
use Test::More;

is(eval "die 'foo'", undef);
ok($@);

done_testing;
