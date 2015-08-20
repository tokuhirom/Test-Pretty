use strict;
use warnings;
use utf8;
use Test::Pretty;
use Test::More;

SKIP: {
    $^O eq 'MSWin32'
        and skip 'This is known to crash on Windows. See Issue #26', 1;

    ok 1;

    my $pid = fork();
    die "Cannot fork: $!" if not defined $pid;
    if ($pid == 0) {
        # child
        exit;
    } else {
        # parent
        waitpid $pid, 0;
        is($?, 0, 'parent returns zero exit code');
    }
}

done_testing;

