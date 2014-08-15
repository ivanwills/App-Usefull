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

rhymbox-ctrl - Control a running rhythmbox instance

=head1 VERSION

This documentation refers to rhymbox-ctrl version 0.1.

=head1 SYNOPSIS

   rhymbox-ctrl [option]

 OPTIONS:
  -o --other         other option

  -v --verbose       Show more detailed option
     --VERSION       Prints the version information
     --help          Prints this help information
     --man           Prints the full documentation for rhymbox-ctrl

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
