# NAME

Test::Pretty - Smile Precure!

# SYNOPSIS

    use Test::Pretty;

# DESCRIPTION

Test::Pretty is a prettifier for Test::More.

When you are writing a test case such as following:

    use strict;
    use warnings;
    use utf8;
    use Test::More;

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

This code outputs following result:

<div><img src="https://raw.github.com/tokuhirom/Test-Pretty/master/img/more.png"></div>

No, it's not readable. Test::Pretty makes this result to pretty.

You can enable Test::Pretty by

    use Test::Pretty;

Or just add following option to perl interpreter.
    

    -MTest::Pretty

After this, you can get a following pretty output.

<div><img src="https://raw.github.com/tokuhirom/Test-Pretty/master/img/pretty.png"></div>

And this module outputs TAP when $ENV{HARNESS\_ACTIVE} is true or under the win32.

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# THANKS TO

Some code was taken from [Test::Name::FromLine](https://metacpan.org/pod/Test::Name::FromLine), thanks cho45++

# SEE ALSO

[Acme::PrettyCure](https://metacpan.org/pod/Acme::PrettyCure)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
