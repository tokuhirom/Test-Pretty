use strict;
use warnings;

use Test::More;
use Test::Pretty;

diag "Test::More: $Test::More::VERSION";
diag "Test::Prerty: $Test::Pretty::VERSION";
diag "Perl: $]";

subtest 'Test' => sub {
    pass 'A';
};

done_testing;

