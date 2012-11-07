package TAP::Formatter::Pretty::Single;
use strict;
use warnings;
use POSIX qw(strftime);

use parent qw(TAP::Formatter::Base);
use TAP::Formatter::Pretty::Single::Session;

sub open_test {
    my ( $self, $test, $parser ) = @_;

    if ($self->jobs > 1) {
        die "This formatter does not support parallel testing";
    }

    my $session = TAP::Formatter::Pretty::Single::Session->new(
        {   name       => $test,
            formatter  => $self,
            parser     => $parser,
            show_count => $self->show_count,
        }
    );

    return $session;
}

sub summary {
    my ( $self, $aggregate, $interrupted ) = @_;
    $self->_output($/);
}

1;
