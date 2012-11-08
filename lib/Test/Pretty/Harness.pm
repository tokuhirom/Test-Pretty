use strict;
use warnings;

package Test::Pretty::Harness;
use parent qw/TAP::Harness/;

# inject parser_class as Test::Pretty::Parser.
sub new {
    my $class = shift;
    my $arg_for = shift;
    $arg_for->{parser_class} = 'Test::Pretty::Parser';
    $arg_for->{switches} = ['-MTest::Pretty'];
    my $self = $class->SUPER::new($arg_for);
    return $self;
}

1;
