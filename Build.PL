use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name       => 'App::Usefull',
	license           => 'perl',
	dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
	dist_version      => '0.001',
	requires          => {
		'perl'             => 5.008,
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
