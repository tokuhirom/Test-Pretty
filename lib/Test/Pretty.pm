package Test::Pretty;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.23';

use Test::Builder 0.82;
use Term::Encoding ();
use File::Spec ();
use Term::ANSIColor qw/colored/;
use Test::More ();
use Scope::Guard;
use Carp ();

use Cwd ();

my $SHOW_DUMMY_TAP;
my $TERM_ENCODING = Term::Encoding::term_encoding();
my $ENCODING_IS_UTF8 = $TERM_ENCODING =~ /^utf-?8$/i;

our $BASE_DIR = Cwd::getcwd();
my %filecache;
my $get_src_line = sub {
    my ($filename, $lineno) = @_;
    $filename = File::Spec->rel2abs($filename, $BASE_DIR);
    # read a source as utf-8... Yes. it's bad. but works for most of users.
    # I may need to remove binmode for STDOUT?
    my $lines = $filecache{$filename} ||= do {
        open my $fh, "<:encoding(utf-8)", $filename
            or return '';
        [<$fh>]
    };
    my $line = $lines->[$lineno-1];
    $line =~ s/^\s+|\s+$//g;
    return $line;
};

if ((!$ENV{HARNESS_ACTIVE} || $ENV{PERL_TEST_PRETTY_ENABLED})) {
    # make pretty
    no warnings 'redefine';
    *Test::Builder::subtest = \&_subtest;
    *Test::Builder::ok = \&_ok;
    *Test::Builder::done_testing = \&_done_testing;
    *Test::Builder::skip = \&_skip;
    *Test::Builder::skip_all = \&_skip_all;
    *Test::Builder::expected_tests = \&_expected_tests;

    my %plan_cmds = (
        no_plan     => \&Test::Builder::no_plan,
        skip_all    => \&_skip_all,
        tests       => \&__plan_tests,
    );
    *Test::Builder::plan = sub {
        my( $self, $cmd, $arg ) = @_;

        return unless $cmd;

        local $Test::Builder::Level = $Test::Builder::Level + 1;

        $self->croak("You tried to plan twice") if $self->{Have_Plan};

        if( my $method = $plan_cmds{$cmd} ) {
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            $self->$method($arg);
        }
        else {
            my @args = grep { defined } ( $cmd, $arg );
            $self->croak("plan() doesn't understand @args");
        }

        return 1;
    };

    my $builder = Test::Builder->new;
    $builder->no_ending(1);
    $builder->no_header(1); # plan

    binmode $builder->output(), "encoding($TERM_ENCODING)";
    binmode $builder->failure_output(), "encoding($TERM_ENCODING)";
    binmode $builder->todo_output(), "encoding($TERM_ENCODING)";

    if ($ENV{HARNESS_ACTIVE}) {
        $SHOW_DUMMY_TAP++;
    }
} else {
    no warnings 'redefine';
    my $ORIGINAL_ok = \&Test::Builder::ok;
    my @NAMES;

    $|++;

    my $builder = Test::Builder->new;
    binmode $builder->output(), "encoding($TERM_ENCODING)";
    binmode $builder->failure_output(), "encoding($TERM_ENCODING)";
    binmode $builder->todo_output(), "encoding($TERM_ENCODING)";

    my ($arrow_mark, $failed_mark);
    if ($ENCODING_IS_UTF8) {
        $arrow_mark = "\x{bb}";
        $failed_mark = " \x{2192} ";
    } else {
        $arrow_mark = ">>";
        $failed_mark = " x ";
    }

    *Test::Builder::subtest = sub {
        push @NAMES, $_[1];
        my $guard = Scope::Guard->new(sub {
            pop @NAMES;
        });
        $_[0]->note(colored(['cyan'], $arrow_mark x (@NAMES*2)) . " " . join(colored(['yellow'], $failed_mark), $NAMES[-1]));
        $_[2]->();
    };
    *Test::Builder::ok = sub {
        $_[2] ||= do {
            my ( $package, $filename, $line ) = caller($Test::Builder::Level);
            "L $line: " . $get_src_line->($filename, $line);
        };
        if (@NAMES) {
            $_[2] = "(" . join( '/', @NAMES)  . ") " . $_[2];
        }
        goto &$ORIGINAL_ok;
    };
}

END {
    my $builder = Test::Builder->new;
    my $real_exit_code = $?;

    # see Test::Builder::_ending
    if( !$builder->{Have_Plan} and $builder->{Curr_Test} ) {
        $builder->is_passing(0);
        $builder->diag("Tests were run but no plan was declared and done_testing() was not seen.");
    }

    if ($builder->{Have_Plan} && !$builder->{No_Plan}) {
        if ($builder->{Curr_Test} != $builder->{Expected_Tests}) {
            $builder->diag("Bad plan: $builder->{Curr_Test} != $builder->{Expected_Tests}");
            $builder->is_passing(0);
        }
    }
    if ($SHOW_DUMMY_TAP) {
        printf("\n%s\n", ($?==0 && $builder->is_passing) ? 'ok' : 'not ok');
    }
    if (!$real_exit_code) {
        if ($builder->is_passing) {
            ## no critic (Variables::RequireLocalizedPunctuationVars)
            $? = 0;
        } else {
            # TODO: exit status may be 'how many failed'
            ## no critic (Variables::RequireLocalizedPunctuationVars)
            $? = 1;
        }
    }
}

sub _skip_all {
    my ($self, $reason) = @_;
    printf("1..0 # SKIP %s\n", $reason);
    $SHOW_DUMMY_TAP = 0;
    exit 0;
}

sub _ok {
    my( $self, $test, $name ) = @_;

    my ($pkg, $filename, $line) = caller($Test::Builder::Level);
    my $src_line;
    if (defined($line)) {
        $src_line = $get_src_line->($filename, $line);
    } else {
        $self->diag(Carp::longmess("\$Test::Builder::Level is invalid. Testing library you are using is broken. : $Test::Builder::Level"));
        $src_line = '';
    }

    if ( $self->{Child_Name} and not $self->{In_Destroy} ) {
        $name = 'unnamed test' unless defined $name;
        $self->is_passing(0);
        $self->croak("Cannot run test ($name) with active children");
    }
    # $test might contain an object which we don't want to accidentally
    # store, so we turn it into a boolean.
    $test = $test ? 1 : 0;

    lock $self->{Curr_Test};
    $self->{Curr_Test}++;

    # In case $name is a string overloaded object, force it to stringify.
    $self->_unoverload_str( \$name );

    $self->diag(<<"ERR") if defined $name and $name =~ /^[\d\s]+$/;
    You named your test '$name'.  You shouldn't use numbers for your test names.
    Very confusing.
ERR

    # Capture the value of $TODO for the rest of this ok() call
    # so it can more easily be found by other routines.
    my $todo    = $self->todo();
    my $in_todo = $self->in_todo;
    local $self->{Todo} = $todo if $in_todo;

    $self->_unoverload_str( \$todo );

    my $out;
    my $result = &Test::Builder::share( {} );


    unless($test) {
        my $fail_char = $ENCODING_IS_UTF8 ? "\x{2716}" : "x";
        $out .= colored(['red'], $fail_char);
        @$result{ 'ok', 'actual_ok' } = ( ( $self->in_todo ? 1 : 0 ), 0 );
    }
    else {
        my $success_char = $ENCODING_IS_UTF8 ? "\x{2713}" : "o";
        $out .= colored(['green'], $success_char);
        @$result{ 'ok', 'actual_ok' } = ( 1, $test );
    }

    $name ||= "  L$line: $src_line";

    # $out .= " $self->{Curr_Test}" if $self->use_numbers;

    if( defined $name ) {
        $name =~ s|#|\\#|g;    # # in a name can confuse Test::Harness.
        $out .= colored(['BRIGHT_BLACK'], "  $name");
        $result->{name} = $name;
    }
    else {
        $result->{name} = '';
    }

    if( $self->in_todo ) {
        $out .= " # TODO $todo";
        $result->{reason} = $todo;
        $result->{type}   = 'todo';
    }
    else {
        $result->{reason} = '';
        $result->{type}   = '';
    }

    $self->{Test_Results}[ $self->{Curr_Test} - 1 ] = $result;
    $out .= "\n";

    $self->_print($out);

    unless($test) {
        my $msg = $self->in_todo ? "Failed (TODO)" : "Failed";
        $self->_print_to_fh( $self->_diag_fh, "\n" ) if $ENV{HARNESS_ACTIVE};

        my( undef, $file, $line ) = $self->caller;
        if( defined $name ) {
            $self->diag(qq[  $msg test '$name'\n]);
            $self->diag(qq[  at $file line $line.\n]);
        }
        else {
            $self->diag(qq[  $msg test at $file line $line.\n]);
        }
    }

    $self->is_passing(0) unless $test || $self->in_todo;

    # Check that we haven't violated the plan
    $self->_check_is_passing_plan();

    return $test ? 1 : 0;
}

sub _done_testing {
    # do nothing
    my $builder = Test::More->builder;
    $builder->{Have_Plan} = 1;
    $builder->{Done_Testing} = [caller];
    $builder->{Expected_Tests} = $builder->current_test;
}

sub _subtest {
    my ($self, $name, $code) = @_;
    my $builder = Test::Builder->new();
    my $orig_indent = $builder->_indent();
    my $guard = Scope::Guard->new(sub {
        $builder->_indent($orig_indent);
    });
    print {$builder->output} do {
        $builder->_indent() . "  $name\n";
    };
    $builder->_indent($orig_indent . '    ');
    my $curr_test = $builder->{Curr_Test};
    my $retval = do {
        local $builder->{Have_Plan}; # this is bad, but works.
        $code->();
    };
    if ($curr_test == $builder->{Curr_Test}) {
        # no tests run in subtest.
        $builder->diag("There is no test case in subtest");
        $builder->is_passing(0);
    }
    $retval;
}

sub __plan_tests {
    my ( $self, $arg ) = @_;

    if ($arg) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        return $self->expected_tests($arg);
    }
    elsif ( !defined $arg ) {
        $self->croak("Got an undefined number of tests");
    }
    else {
        $self->croak("You said to run 0 tests");
    }

    return;
}

sub _expected_tests {
    my $self = shift;
    my($max) = @_;

    if(@_) {
        $self->croak("Number of tests must be a positive integer.  You gave it '$max'")
          unless $max =~ /^\+?\d+$/;

        $self->{Expected_Tests} += $max;
        $self->{Have_Plan}      = 1;

        # $self->_output_plan($max) unless $self->no_header;
    }
    return $self->{Expected_Tests};
}

sub _skip {
    my ($self, $why) = @_;

    lock( $self->{Curr_Test} );
    $self->{Curr_Test}++;

    $self->{Test_Results}[ $self->{Curr_Test} - 1 ] = &Test::Builder::share(
        {
            'ok'      => 1,
            actual_ok => 1,
            name      => '',
            type      => 'skip',
            reason    => $why,
        }
    );

    $self->_print(colored(['yellow'], 'skip') . " $why");

    return 1;
}

1;
__END__

=encoding utf8

=head1 NAME

Test::Pretty - Smile Precure!

=head1 SYNOPSIS

  use Test::Pretty;

=head1 DESCRIPTION

Test::Pretty is a prettifier for Test::More.

When you are writing a test case such as following:

    use strict;
    use warnings;
    use utf8;
    use Test::More;

    subtest 'MessageFilter' => sub {
        my $filter = MessageFilter->new('foo');

        subtest 'should detect message with NG word' => sub {
            ok($filter->detect('hello from foo'));
        };
        subtest 'should not detect message without NG word' => sub {
            ok(!$filter->detect('hello world!'));
        };
    };

    done_testing;

This code outputs following result:

=begin html

<div><img src="https://raw.github.com/tokuhirom/Test-Pretty/master/img/more.png"></div>

=end html

No, it's not readable. Test::Pretty makes this result to pretty.

You can enable Test::Pretty by

    use Test::Pretty;

Or just add following option to perl interpreter.
    
    -MTest::Pretty

After this, you can get a following pretty output.

=begin html

<div><img src="https://raw.github.com/tokuhirom/Test-Pretty/master/img/pretty.png"></div>

=end html

And this module outputs TAP when $ENV{HARNESS_ACTIVE} is true or under the win32.

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 THANKS TO

Some code was taken from L<Test::Name::FromLine>, thanks cho45++

=head1 SEE ALSO

L<Acme::PrettyCure>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
