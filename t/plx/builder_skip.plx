use strict;
use Test::More;

plan tests => 5;

ok 1;

SKIP: {
    for (1..4) {
        Test::Builder->new->skip('Ah, skip me!');
    }
}

