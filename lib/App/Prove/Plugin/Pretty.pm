package App::Prove::Plugin::Pretty;
use strict;
use warnings;
use utf8;

sub load {
    my ($class, $p) = @_;

    my $app = $p->{app_prove};
    # make pretty output for testing only one file.
    if (@{$app->argv} == 1 && -f $app->argv->[0]) {
        unless ($app->quiet || $app->really_quiet) {
            $app->verbose(1);
        }
        $app->formatter('TAP::Formatter::Pretty::Single');
        $app->harness('Test::Pretty::Harness');
        $ENV{PERL_TEST_PRETTY_ENABLED} = 1;
    } elsif ($app->verbose) {
    # make pretty output for verbose multiple file test.
        $app->formatter('TAP::Formatter::Pretty::Multi');
        $app->harness('Test::Pretty::Harness');
        $ENV{PERL_TEST_PRETTY_ENABLED} = 1;
    } else {
        # do nothing.
    }
}

1;
__END__

=encoding utf-8

=for stopwords .proverc

=head1 NAME

App::Prove::Plugin::Pretty - Test::Pretty plugin for prove

=head1 SYNOPSIS

    prove -PPretty t/01_simple.t

=head1 DESCRIPTION

This is a plugin for prove. This plugin enables Test::Pretty on your test script.

This plugin only affects if prove running for only one test case.

=head1 HINT

I recommend to add C<< -PPretty >> to your .proverc. It makes testing life is better.

