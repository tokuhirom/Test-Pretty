use utf8;
use strict;
use warnings;
use Test::More;

eval "is(filename_is_eval(__FILE__), 1, "
    . "'eval(...) should pick up eval filename')";
is( $@, '', 'no eval error on previous test' );

done_testing;

sub filename_is_eval($) {
    my $filename = shift;
    return 0 unless defined $filename;

    return !!( $filename =~ /^\(eval \d+\)|-e$/
        || $filename =~ /^sub \S+::\S+/ );
}
