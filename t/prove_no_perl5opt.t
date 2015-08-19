use strict;
use warnings;
use utf8;
use Test::More;
use App::Prove;

my $prove = App::Prove->new();
$prove->process_args('--norc', '--QUIET', '-Pretty', 't/plx/no_perl5opt.plx');
ok($prove->run(), 'prove runs w/ -Pretty');

done_testing;


