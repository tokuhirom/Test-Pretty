package Test::Pretty;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.02';

use Test::Builder;
use Term::Encoding ();
use File::Spec ();
use Term::ANSIColor qw/colored/;
use Scope::Guard;

if (!$ENV{HARNESS_ACTIVE}) {
    no warnings 'redefine';
    *Test::Builder::subtest = \&_subtest;
    *Test::Builder::ok = \&_ok;
    *Test::Builder::done_testing = sub {
        # do nothing
    };
    my $builder = Test::Builder->new;
    $builder->no_ending(1);

    my $encoding = Term::Encoding::term_encoding();
    binmode $builder->output(), "encoding($encoding)";
    binmode $builder->failure_output(), "encoding($encoding)";
    binmode $builder->todo_output(), "encoding($encoding)";
}

use Cwd ();
our $BASE_DIR = Cwd::getcwd();
my %filecache;
my $get_src_line = sub {
    my ($filename, $lineno) = @_;
    $filename = File::Spec->rel2abs($filename, $BASE_DIR);
    my $lines = $filecache{$filename} ||= do {
        open my $fh, '<', $filename;
        [<$fh>]
    };
    my $line = $lines->[$lineno-1];
    $line =~ s/^\s+|\s+$//g;
    return $line;
};
sub _ok {
    my( $self, $test, $name ) = @_;

    my ($pkg, $filename, $line) = caller($Test::Builder::Level);
    my $src_line = $get_src_line->($filename, $line);

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
        $out .= colored(['red'], "\x{2716}");
        @$result{ 'ok', 'actual_ok' } = ( ( $self->in_todo ? 1 : 0 ), 0 );
    }
    else {
        $out .= colored(['green'], "\x{2713}");
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
    eval {
        $code->();
    };
}

1;
__END__

=encoding utf8

=head1 NAME

Test::Pretty - Yes! PrettyCure 5!

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

Yes, it's not readable. Test::Pretty makes this result to pretty.

You can enable Test::Pretty by

    use Test::Pretty;

Or just add following option to perl interpreter.
    
    -MTest::Pretty

After this, you can get a following prerty output.

=begin html

<div><img src="https://raw.github.com/tokuhirom/Test-Pretty/master/img/pretty.png"></div>

=end html

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
