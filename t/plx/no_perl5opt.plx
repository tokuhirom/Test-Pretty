use Test::More;
unlike($ENV{PERL5OPT} || '', qr/-MTest::Pretty/);
done_testing;
