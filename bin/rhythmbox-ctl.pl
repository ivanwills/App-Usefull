#!/usr/bin/env perl

# Created on: 2008-02-29 13:13:50
# Create by:  ivanw
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Scalar::Util;
use List::Util;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use FindBin qw/$Bin/;
use Net::DBus;

our $VERSION = version->new('0.0.1');
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

my %option = (
	out     => undef,
	verbose => 0,
	man     => 0,
	help    => 0,
	VERSION => 0,
);

if ( !@ARGV ) {
	pod2usage( -verbose => 1 );
}

main();
exit 0;

sub main {

	Getopt::Long::Configure('bundling');
	GetOptions(
		\%option,
		'out|o=s',
		'verbose|v+',
		'man',
		'help',
		'VERSION!',
	) or pod2usage(2);
	#my $file = join ' ', @ARGV;

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
	my $bus = Net::DBus->find;
	my $service = $bus->get_service("org.gnome.Rhythmbox");

	my $object = $service->get_object("/org/gnome/Rhythmbox/Player");
	foreach (@{$object->ListNames}) {
		print "$_\n";
	}

	return;
}

__DATA__

=head1 NAME

rhymbox-ctrl - <One-line description of commands purpose>

=head1 VERSION

This documentation refers to rhymbox-ctrl version 0.1.

=head1 SYNOPSIS

   rhymbox-ctrl [option]

 OPTIONS:
  -o --other         other option

  -v --verbose       Show more detailed option
     --version       Prints the version information
     --help          Prints this help information
     --man           Prints the full documentation for rhymbox-ctrl



=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.

These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module
provides.

Name the section accordingly.

In an object-oriented module, this section should begin with a sentence (of the
form "An object of this class represents ...") to give the reader a high-level
context to help them understand the methods that are subsequently described.

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
