package t::Util;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;

use Test::More;
use File::Temp;
use POSIX;
use TAP::Parser;

our @EXPORT = qw/run_test exit_status_is exit_status_isnt parse_tap/;

sub run_test {
    my $path = shift;

    local $ENV{HARNESS_ACTIVE} = 1;
    local $ENV{PERL_TEST_PRETTY_ENABLED} = 1;

    my $tmp = File::Temp->new;

    my $pid = fork;
    die $! unless defined $pid;
    if ($pid) {
        waitpid($pid, 0);

        open my $fh, '<', $tmp->filename or die $!;
        my $out = do { local $/; <$fh> };
        note 'x' x 80;
        note $out;
        note 'x' x 80;

        return $out;
    } else {
        # child
        open(STDOUT, ">&", $tmp) or die "Cannot redirect";
        open(STDERR, ">&", $tmp) or die "Cannot redirect";
        exec $^X, '-Ilib', '-MTest::Pretty', $path;
        die "Cannot exec";
    }
}

sub exit_status_is {
    my ($expected) = @_;

    ok(POSIX::WIFEXITED($?));
    is(POSIX::WEXITSTATUS($?), $expected);
}

sub exit_status_isnt {
    my ($expected) = @_;

    ok(POSIX::WIFEXITED($?));
    isnt(POSIX::WEXITSTATUS($?), $expected);
}

sub parse_tap {
    require Test::Pretty::Parser;
    my $tap = shift;
    my $parser = Test::Pretty::Parser->new({tap => $tap});
    1 while $parser->next;
    return $parser;
}

1;

