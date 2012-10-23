use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl => '5.010001',
        'parent'                        => '0',
        'Term::Encoding' => 0,
        'Term::ANSIColor' => 0,
        'Scope::Guard' => 0,
        'Carp' => 0,
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Test-Pretty',
    module_name => 'Test::Pretty',

    # script_files => [''],

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,
   
    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
