#!/usr/bin/env perl

# Created on: 2008-03-15 06:25:15
# Create by:  ivan
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use FindBin qw/$Bin/;
use File::Find;
use Class::Date;
use File::Touch;

our $VERSION = version->new('0.0.1');
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

sub touch_files;

my %option = (
	verbose => 0,
	man     => 0,
	help    => 0,
	VERSION => 0,
);

main();
exit 0;

sub main {

	Getopt::Long::Configure('bundling');
	GetOptions(
		\%option,
		'all|a',
		'verbose|v+',
		'man',
		'help',
		'VERSION!',
	) or pod2usage(2);
	my @dirs = @ARGV;

	if ( $option{'VERSION'} ) {
		print "$name Version = $VERSION\n";
		exit 1;
	}
	elsif ( $option{'man'} ) {
		pod2usage( -verbose => 2 );
	}
	elsif ( $option{'help'} ) {
		pod2usage( -verbose => 1 );
	}

	# do stuff here
	for my $dir (@dirs) {
		find( \&touch_files, $dir );
	}

	return;
}

sub touch_files {

	my $file = $File::Find::name;

	# skip internal svn files
	return if $file =~ m{/[.]svn/};

	# check that the file is unmodified
	my $mod = `svn st $_`;
	chomp $mod;

	return if $mod && !$option{all};

	my $last = `svn log $_ 2> /dev/null | head -2 | tail -1`;
	my ( $rev, $name, $time ) = $last =~ m{ ^ r(\d+) \s+ [|] \s+ ([^|]+) \s+ [|] \s+ ( \d\d\d\d-\d\d-\d\d \s \d\d:\d\d:\d\d \s [+-]\d\d\d\d ) }xms;
	$time = Class::Date->new($time);

	my $touch = File::Touch->new( mtime => $time->epoch );
	eval{ $touch->touch($_) };

	return;
}

__DATA__

=head1 NAME

svntouch - Sets the modification times for files to the last time that they were changed in
subversion.

=head1 VERSION

This documentation refers to svntouch version 0.1.

=head1 SYNOPSIS

   svntouch [option]

 OPTIONS:
  -a --all     Touch all files even if locally modified

  -v --verbose Show more detailed option
     --version Prints the version information
     --help    Prints this help information
     --man     Prints the full documentation for svntouch

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
