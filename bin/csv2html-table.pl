#!/usr/bin/env perl

=head1 NAME

csv2html-table- <One-line description of commands purpose>

=head1 VERSION

This documentation refers to csv2html-table version 0.1.

=head1 SYNOPSIS

   csv2html-table [options] file.csv

 OPTIONS:
  -i --indent        The type of indentation to use (set to an empty string to
                     disable)
  -l --level         The level of indentation to start with

  -V --VERSION       Prints the version information
  -v --verbose       Show more detailed option
  -h --help          Prints this help information
  -m --man           Prints the full documentation for csv2html-table



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

Please report problems to <Maintainer name(s)> (<contact address>)

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)
<Author name(s)> - (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

# Created on: 2005-12-11 21:46:39
# Create by:  ivan

use strict;
use warnings;

use Scalar::Util;
use List::Util;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;
use CGI;
use Text::CSV_XS;

our $VERSION = 0.1;

my %option = (
    indent  => "\t",
    level   => 0,
    man     => 0,
    help    => 0,
    verbose => 0,
    VERSION => 0,
);

pod2usage( -verbose => 1 ) unless @ARGV;

main();
exit(0);

sub main {
    my $file;
    $file = pop @ARGV if -f $ARGV[-1] or $ARGV[-1] eq '-';

    Getopt::Long::Configure("bundling");
    GetOptions(
        \%option,
        'indent|i=s',
        'level|l=i',
        'man|m',
        'help|h',
        'verbose|v!',
        'VERSION|V'
    ) or pod2usage(2);

    print "csv2html-table Version = $VERSION" and exit(1) if $option{VERSION};
    pod2usage( -verbose => 2 ) if $option{man};
    pod2usage( -verbose => 1 ) if $option{help} or not $file;

    # do stuff here
    my $cgi = new CGI();
    my $csv = new Text::CSV_XS();
    open my $file_h, '<', $file or die "Could not open the file $file: $!";

    print $option{indent} x $option{level}, $cgi->start_table(), "\n";

    while ( my $line = <$file_h> ) {
        if ( $csv->parse($line) ) {
            print $option{indent} x ( $option{level} + 1 ), $cgi->start_Tr(), "\n";
            for my $column ( $csv->fields() ) {
                $column =~ s{&}{&amp;}gxs;
                $column =~ s{<}{&lt;}gxs;
                $column =~ s{>}{&gt;}gxs;
                print $option{indent} x ( $option{level} + 2 ), $cgi->td($column), "\n";
            }
            print $option{indent} x ( $option{level} + 1 ), $cgi->end_Tr(), "\n";
        }
    }

    print $option{indent} x $option{level}, $cgi->end_table(), "\n";
}

__DATA__
