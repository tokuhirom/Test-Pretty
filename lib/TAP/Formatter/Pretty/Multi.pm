package TAP::Formatter::Pretty::Multi;
use strict;
use warnings;
use utf8;

use TAP::Formatter::Base ();
use POSIX qw(strftime);
use parent qw(TAP::Formatter::Base);

sub open_test {
    my ( $self, $test, $parser ) = @_;

    my $class
      = $self->jobs > 1
      ? 'TAP::Formatter::Console::ParallelSession'
      : 'TAP::Formatter::Pretty::Multi::Session';

    eval "require $class"; ## no critic.
    $self->_croak($@) if $@;

    my $session = $class->new(
        {   name       => $test,
            formatter  => $self,
            parser     => $parser,
            show_count => $self->show_count,
        }
    );

    $session->header;

    return $session;
}

sub _set_colors {
    my ( $self, @colors ) = @_;
    if ( my $colorizer = $self->_colorizer ) {
        my $output_func = $self->{_output_func} ||= sub {
            $self->_output(@_);
        };
        $colorizer->set_color( $output_func, $_ ) for @colors;
    }
}

sub _output_success {
    my ( $self, $msg ) = @_;
    $self->_set_colors('green');
    my $has_newline = chomp $msg;
    $self->_output($msg);
    $self->_set_colors('reset');
    $self->_output($/) if $has_newline;
}

sub _failure_output {
    my $self = shift;
    $self->_set_colors('red');
    my $out = join '', @_;
    my $has_newline = chomp $out;
    $self->_output($out);
    $self->_set_colors('reset');
    $self->_output($/)
      if $has_newline;
}

sub _format_name {
    my ( $self, $test ) = @_;
    my $name = $test;
    my $periods = '=' x (( $self->_longest + 2 - length $test ));

    $self->_output("\n");
    $self->_set_colors('yellow');
    if ($self->timer) {
        my $stamp = $self->_format_now();
        $self->_set_colors('green');
        $self->_output("$stamp ");
        $self->_set_colors('yellow');
    }
    $self->_output("==> ");
    $self->_set_colors('cyan');
    $self->_output("$name");
    $self->_set_colors('yellow');
    $self->_output(" <$periods");
    $self->_set_colors('reset');
    $self->_output("\n");

    return ''; # as pretty format name has already been written
}

1;

