#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;

use lib 'lib';

use Test::Pretty;
use Test::More;
use Scope::Guard;


my $ORIG_BUILDER = $Test::Builder::Test;
{
    package Test::Pretty::Builder;
    use parent qw/Test::Builder/;

    sub done_testing {
        # do nothing.
    }


}

ok 1;
subtest 'foo' => sub {
    is 0, 0;
    subtest 'bar' => sub {
        is 0, 1;
    };
};
ok 0;
done_testing;
