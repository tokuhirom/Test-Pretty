use strict;
use warnings;

package Test::Pretty::Harness;
use parent qw/TAP::Harness/;

# inject parser_class as Test::Pretty::Parser.
sub new {
    my $class = shift;
    my $arg_for = shift;
    $arg_for->{parser_class} = 'Test::Pretty::Parser';
    return $class->SUPER::new($arg_for);
}

package # hide from pause
    Test::Pretty::Parser;
use parent qw/TAP::Parser/;

# Test::Pretty outputs 1 test results without plan line.
sub plan { 1 }

1;
