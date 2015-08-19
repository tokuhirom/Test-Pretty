package t::Util;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;

use Test::More;
use File::Temp qw/ tempfile /;
use POSIX;
use TAP::Parser;

our @EXPORT = qw/run_test exit_status_is exit_status_isnt parse_tap/;

sub run_test {
    my $path = shift;

    local $ENV{HARNESS_ACTIVE} = 1;
    local $ENV{PERL_TEST_PRETTY_ENABLED} = 1;

    my ($tmp, $filename) = tempfile();
    close $tmp;

    my $pid = fork;
    die $! unless defined $pid;
    if ($pid) {
        waitpid($pid, 0);

        open my $fh, '<', $filename or die $!;
        my $out = do { local $/; <$fh> };
        close $fh;
        note 'x' x 80;
        note $out;
        note 'x' x 80;

        return $out;
    } else {
        # child
        open(STDOUT, ">", $filename) or die "Cannot redirect";
        open(STDERR, ">", $filename) or die "Cannot redirect";
        exec $^X, '-Ilib', '-MTest::Pretty', $path;
        die "Cannot exec";
    }
}

sub exit_status_is {
    my ($expected) = @_;

    if ($^O eq 'MSWin32') {
        is($?, $expected, 'got expected exit code of '.$expected);
    } else {
        ok(POSIX::WIFEXITED($?), 'existed normally');
        is(POSIX::WEXITSTATUS($?), $expected, 'got expected exit code of '.$expected);
    }
}

sub exit_status_isnt {
    my ($expected) = @_;

    if ($^O eq 'MSWin32') {
        isnt($?, $expected, 'didn\'t get exit code of '.$expected);
    } else {
        ok(POSIX::WIFEXITED($?), 'existed normally');
        isnt(POSIX::WEXITSTATUS($?), $expected, 'didn\'t get exit code of '.$expected);
    }
}

sub parse_tap {
    require Test::Pretty::Parser;
    my $tap = shift;
    my $parser = Test::Pretty::Parser->new({tap => $tap});
    1 while $parser->next;
    return $parser;
}

1;

