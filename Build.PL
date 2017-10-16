use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'App::Useful',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version      => '0.001',
    requires          => {
        'perl'                            => 'v5.14',
        'CHI'                             => 0,
        'Class::Date'                     => 0,
        'Config::Any'                     => 0,
        'Config::General'                 => 0,
        'DBI'                             => 0,
        'DBIx::Class::Schema::Loader'     => 0,
        'Data::Dump::Streamer'            => 0,
        'DateTime'                        => 0,
        'File::TypeCategories'            => 0,
        'File::Slurp'                     => 0,
        'File::Touch'                     => 0,
        'File::chdir'                     => 0,
        'Getopt::Alt'                     => '0.1.5',
        'HTTP::Cookies'                   => 0,
        'HTTP::Proxy'                     => 0,
        'HTTP::Proxy::HeaderFilter'       => 0,
        'HTTP::Recorder'                  => 0,
        'HTTP::Tiny::Mech'                => 0,
        'Hash::Merge'                     => 0,
        'IO::Socket::SSL'                 => 0,
        'JSON::XS'                        => 0,
        'List::MoreUtils'                 => 0,
        'MetaCPAN::API'                   => 0,
        'Moose'                           => 0,
        'Number::Bytes::Human'            => 0,
        'Path::Tiny'                      => 0,
        'Perl::MinimumVersion'            => 0,
        'Proc::ProcessTable'              => 0,
        'Syntax::Highlight::Engine::Kate' => 0,
        'Term::Size::Perl'                => 0,
        'Term::Title'                     => 0,
        'Text::CSV_XS'                    => 0,
        'Text::Table'                     => 0,
        'UI::Dialog'                      => 0,
        'VCS::Which'                      => 0,
        'WWW::Mechanize'                  => 0,
        'WWW::Mechanize::Cached'          => 0,
        'X11::Protocol::Ext::DPMS'        => 0,
        'YAML'                            => 0,
        'YAML::Syck'                      => 0,
    },
    configure_requires => {
        'Module::Build' => 0.38,
    },
    build_requires => {
        'Test::More'     => '0.88',
        'Test::Warnings' => '0.026',
    },
    recommends  => {
        'Gtk3::Notify'                    => 0,
        'Image::Resize'                   => 0,
        'Net::DBus'                       => 0,
        'Net::DBus::Reactor'              => 0,
        'Tidy'                            => 0,
        'Tidy::STDIN'                     => 0,
    },
    add_to_cleanup     => [ 'App-Useful-*' ],
    create_license     => 1,
    meta_merge         => {
        resources => {
            repository => 'git://github.com/ivanwills/App-Useful.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=App::Useful',
        },
    },
    dist_abstract => 'A bunch of useful scripts'
);

$builder->create_build_script();
