requires 'Carp';
requires 'Scope::Guard';
requires 'TAP::Harness';
requires 'Term::ANSIColor', '3.02';
requires 'Term::Encoding';
requires 'Test::Builder', '0.82';
requires 'File::Temp';
requires 'TAP::Formatter::Base';
requires 'TAP::Formatter::Session';
requires 'TAP::Parser';
requires 'autodie';
requires 'parent';
requires 'perl', '5.008001';
requires 'Test::More', '0.98';

on test => sub {
    requires 'Test::Requires';
    requires 'App::Prove';
};
