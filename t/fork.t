use strict;
use warnings;
use utf8;
use Test::Pretty;
use Test::More;

ok 1;
my $pid = fork();
die "Cannot fork: $!" if not defined $pid;
if ($pid == 0) {
    # child
    exit;
} else {
    # parent
    waitpid $pid, 0;
    is($?, 0);
}

done_testing;

