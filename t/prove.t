use strict;
use warnings;
use utf8;
use Test::More;
use App::Prove;

my $prove = App::Prove->new();
$prove->process_args('--norc', '-Pretty', 't/00_compile.t');
ok($prove->run());

done_testing;

