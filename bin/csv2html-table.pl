#!/usr/bin/env perl

=head1 NAME

csv2html-table- Convert a CVS file into a HTML table

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

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com)

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

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
use English qw/ -no_match_vars /;
use CGI;
use Text::CSV_XS;

our $VERSION = 0.1;
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

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
        'version'
    ) or pod2usage(2);

    if ( $option{'version'} ) {
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
