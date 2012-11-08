package Test::Pretty::Parser;
use strict;
use warnings;
use utf8;
use parent qw/TAP::Parser/;

# Test::Pretty outputs 1 test results without plan line.
sub plan { 1 }

1;

