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

1;
