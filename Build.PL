use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::Usefull',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version      => '0.001',
    requires          => {
        'perl'                            => 5.008,
        'Class::Date'                     => 0,
        'Config::General'                 => 0,
        'DBI'                             => 0,
        'DBIx::Class::Schema::Loader'     => 0,
        'DDS'                             => 0,
        'File::chdir'                     => 0,
        'File::CodeSearch::Files'         => 0,
        'File::Slurp'                     => 0,
        'File::Touch'                     => 0,
        'Getopt::Alt'                     => 0,
        'HTTP::Proxy'                     => 0,
        'HTTP::Recorder'                  => 0,
        'Image::Resize'                   => 0,
        'JSON'                            => 0,
        'List::MoreUtils'                 => 0,
        'Module::CoreList'                => 0,
        'Net::DBus'                       => 0,
        'Net::DBus::Reactor'              => 0,
        'Number::Bytes::Human'            => 0,
        'Path::Class'                     => 0,
        'Perl::Critic::Bangs'             => 0,
        'Perl::MinimumVersion'            => 0,
        'Proc::ProcessTable'              => 0,
        'Syntax::Highlight::Engine::Kate' => 0,
        'Template'                        => 0,
        'Template::Provider::FromDATA'    => 0,
        'Term::Title'                     => 0,
        'Text::CSV_XS'                    => 0,
        'Text::Table'                     => 0,
        'UI::Dialog'                      => 0,
        'VCS::Which'                      => 0,
        'version'                         => 0,
        'WWW::Mechanize'                  => 0,
        'X11::Protocol::Ext::DPMS'        => 0,
        'YAML'                            => 0,
        'YAML::Syck'                      => 0,
    },
    build_requires => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
    },
    add_to_cleanup     => [ 'App-Usefull-*' ],
    create_makefile_pl => 'traditional',
    create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/App-Usefull.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::Usefull',
        },
    },
);

$builder->create_build_script();
