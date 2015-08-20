use strict;
use warnings;
use Test::More;
use t::Util;
use Term::Encoding;

my $TERM_ENCODING = Term::Encoding::term_encoding();
my $ENCODING_IS_UTF8 = $TERM_ENCODING =~ /^utf-?8$/i;

plan skip_all => 'This test can run on utf-8 system' unless $ENCODING_IS_UTF8;

my $out = run_test('t/plx/typester.plx');
like $out, qr/1はOKなはず！/, 'found utf8 characters via line comment';

done_testing;

