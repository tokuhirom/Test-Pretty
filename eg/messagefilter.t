use strict;
use warnings;
use utf8;
use Test::More;

{
    package MessageFilter;
    sub new {
        my ($class, $word) = @_;
        bless \$word, $class;
    }
    sub detect {
        my ($self, $str) = @_;
        return index($str, $$self) >= 0;
    }
}

subtest 'MessageFilter' => sub {
    my $filter = MessageFilter->new('foo');

    subtest 'should detect message with NG word' => sub {
        ok($filter->detect('hello from foo'));
    };
    subtest 'should not detect message without NG word' => sub {
        ok(!$filter->detect('hello world!'));
    };
};

done_testing;
