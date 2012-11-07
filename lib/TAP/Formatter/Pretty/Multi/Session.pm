package TAP::Formatter::Pretty::Multi::Session;
use strict;
use warnings;
use utf8;
use parent qw/TAP::Formatter::Session/;

my @ACCESSOR;

BEGIN {
    my @CLOSURE_BINDING = qw( header result clear_for_close close_test );

    for my $method (@CLOSURE_BINDING) {
        no strict 'refs';
        *$method = sub {
            my $self = shift;
            return ( $self->{_closures} ||= $self->_closures )->{$method}
              ->(@_);
        };
    }
}

sub _get_output_result {
    my $self = shift;

    my @color_map = (
        {   test => sub { $_->is_test && !$_->is_ok },
            colors => ['red'],
        },
        {   test => sub { $_->is_test && $_->has_skip },
            colors => [
                'white',
                'on_blue'
            ],
        },
        {   test => sub { $_->is_test && $_->has_todo },
            colors => ['yellow'],
        },
    );

    my $formatter = $self->formatter;
    my $parser    = $self->parser;

    return $formatter->_colorizer
      ? sub {
        my $result = shift;
        for my $col (@color_map) {
            local $_ = $result;
            if ( $col->{test}->() ) {
                $formatter->_set_colors( @{ $col->{colors} } );
                last;
            }
        }
        $formatter->_output( $self->_format_for_output($result) );
        $formatter->_set_colors('reset');
      }
      : sub {
        $formatter->_output( $self->_format_for_output(shift) );
      };
}

sub _closures {
    my $self = shift;

    my $parser     = $self->parser;
    my $formatter  = $self->formatter;
    my $pretty     = $formatter->_format_name( $self->name );
    my $show_count = $self->show_count;

    my $really_quiet = $formatter->really_quiet;
    my $quiet        = $formatter->quiet;
    my $verbose      = $formatter->verbose;
    my $directives   = $formatter->directives;
    my $failures     = $formatter->failures;
    my $comments     = $formatter->comments;

    my $output_result = $self->_get_output_result;

    my $output          = '_output';
    my $plan            = '';
    my $newline_printed = 0;

    my $last_status_printed = 0;

    return {
        header => sub {
            $formatter->_output($pretty)
              unless $really_quiet;
        },

        result => sub {
            my $result = shift;

            if ( $result->is_bailout ) {
                $formatter->_failure_output(
                        "Bailout called.  Further testing stopped:  "
                      . $result->explanation
                      . "\n" );
            }

            return if $really_quiet;

            my $is_test = $result->is_test;

            # These are used in close_test - but only if $really_quiet
            # is false - so it's safe to only set them here unless that
            # relationship changes.

            if ( !$plan ) {
                my $planned = $parser->tests_planned || '?';
                $plan = "/$planned ";
            }
            $output = $formatter->_get_output_method($parser);

            if ( $show_count and $is_test ) {
                my $number = $result->number;
                my $now    = CORE::time;

                # Print status roughly once per second.
                # We will always get the first number as a side effect of
                # $last_status_printed starting with the value 0, which $now
                # will never be. (Unless someone sets their clock to 1970)
                if ( $last_status_printed != $now ) {
                    $formatter->$output("\r$pretty$number$plan");
                    $last_status_printed = $now;
                }
            }

            if (!$quiet
                && (   $verbose
                    || ( $is_test && $failures && !$result->is_ok )
                    || ( $comments   && $result->is_comment )
                    || ( $directives && $result->has_directive ) )
              )
            {
                unless ($newline_printed) {
                    $formatter->_output("\n");
                    $newline_printed = 1;
                }
                $output_result->($result);
                $formatter->_output("\n");
            }
        },

        clear_for_close => sub {
            my $spaces
              = ' ' x length( '.' . $pretty . $plan . $parser->tests_run );
            $formatter->$output("\r$spaces");
        },

        close_test => sub {
            if ( $show_count && !$really_quiet ) {
                $self->clear_for_close;
                $formatter->$output("\r$pretty");
            }

            # Avoid circular references
            $self->parser(undef);
            $self->{_closures} = {};

            return if $really_quiet;

            if ( my $skip_all = $parser->skip_all ) {
                $formatter->_output("skipped: $skip_all\n");
            }
            elsif ( $parser->has_problems ) {
                $self->_output_test_failure($parser);
            }
            else {
                my $time_report = '';
                if ( $formatter->timer ) {
                    my $start_time = $parser->start_time;
                    my $end_time   = $parser->end_time;
                    if ( defined $start_time and defined $end_time ) {
                        my $elapsed = $end_time - $start_time;
                        $time_report
                          = $self->time_is_hires
                          ? sprintf( ' %8d ms', $elapsed * 1000 )
                          : sprintf( ' %8s s', $elapsed || '<1' );
                    }
                    $formatter->_output( $self->_make_ok_line($time_report) );
                }
            }
        },
    };
}

sub _output_test_failure {
    my ( $self, $parser ) = @_;
    my $formatter = $self->formatter;
    return if $formatter->really_quiet;

    my $tests_run     = $parser->tests_run;
    my $tests_planned = $parser->tests_planned;

    my $total
      = defined $tests_planned
      ? $tests_planned
      : $tests_run;

    my $passed = $parser->passed;

    # The total number of fails includes any tests that were planned but
    # didn't run
    my $failed = $parser->failed + $total - $tests_run;
    my $exit   = $parser->exit;

    if ( my $exit = $parser->exit ) {
        my $wstat = $parser->wait;
        my $status = sprintf( "%d (wstat %d, 0x%x)", $exit, $wstat, $wstat );
        $formatter->_failure_output("Dubious, test returned $status\n");
    }

    if ( $failed == 0 ) {
#       $formatter->_failure_output(
#           $total
#           ? "All $total subtests passed "
#           : 'No subtests run '
#       );
    }
    else {
        $formatter->_failure_output("Failed $failed/$total subtests ");
        if ( !$total ) {
            $formatter->_failure_output("\nNo tests run!");
        }
    }

    if ( my $skipped = $parser->skipped ) {
        $passed -= $skipped;
        my $test = 'subtest' . ( $skipped != 1 ? 's' : '' );
        $formatter->_output(
            "\n\t(less $skipped skipped $test: $passed okay)");
    }

    if ( my $failed = $parser->todo_passed ) {
        my $test = $failed > 1 ? 'tests' : 'test';
        $formatter->_output(
            "\n\t($failed TODO $test unexpectedly succeeded)");
    }

#   $formatter->_output("\n");
}

1;

