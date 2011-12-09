#!/usr/bin/env perl

# Created on: 2006-02-09 16:04:16
# Create by:  ivanw

use strict;
use warnings;

use Scalar::Util;
use List::Util;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;

use Text::CSV_XS;

our $VERSION = 0.1;

my %option = (
	win     => undef,
	out     => undef,
	man     => 0,
	help    => 0,
	verbose => 0,
	VERSION => 0,
);

pod2usage( -verbose => 1 ) unless @ARGV;

main();
exit(0);

sub main {

	Getopt::Long::Configure("bundling");
	GetOptions(
		\%option,
		'win|w',
		'out|o=s',
		'man|m',
		'help|h',
		'verbose|v!',
		'VERSION|V'
	) or pod2usage(2);
	my $file = pop @ARGV;

	print "psqlout2csv Version = $VERSION\n" and exit(1) if $option{VERSION};
	pod2usage( -verbose => 2 ) if $option{man};
	pod2usage( -verbose => 1 ) if $option{help};

	# do stuff here
	my $in_fh;
	my $out_fh;

	if ( $file eq '-' ) {
		$in_fh = *STDIN;
	}
	else {
		open $in_fh, '<', $file or die "Could not open '$file': $!";
	}

	if ( $option{out} ) {
		warn "Writing to '$option{out}'\n";
		open $out_fh, '>', $option{out} or die "Could not write to '$option{out}': $!";
	}
	else {
		$out_fh = *STDOUT;
	}

	my $line_no  = 0;
	my $columns  = 0;
	my $file_no  = 1;
	my $csv      = Text::CSV_XS->new( { eol => undef, binary => 1, } );
	my $split_re = qr/(?<=\s)\s*[|]/;

	while ( my $line = <$in_fh> ) {
		$line_no++;
		next if $line_no < 3 and $line !~ /[|]/;
		if ( $line =~ /[(] \s* \d+ \s* rows? [)] /xs ) {
			if ( $option{out} && $line_no > 1 ) {
				close $out_fh;
				my $file = $option{out};
				$file =~ s/([.]\w+)$/${file_no}$1/xs;
				open $out_fh, '>', $file or die "Could not write to '$file': $!";
				$file_no++;
				warn "Now writing to '$file'\n";
			}
			$line_no = -1;
			$columns = 0;
			next;
		}
		chomp $line;

		my @columns = split /$split_re/, $line;

		if ( not $columns ) {
			$columns = scalar @columns;
			warn "Columns = $columns\n" . join "\n", @columns if $option{verbose};
		}
		else {
			warn "col count = " . scalar(@columns) . "\n" if $option{verbose};
		}

		while ( @columns < $columns ) {
			warn "here" if $option{verbose};
			my $next_line = <$in_fh>;
			die "Could not create a full set of columns" unless $next_line;
			my @continued = split /$split_re/, $next_line;
			chomp $columns[-1];
			$columns[-1] .= "\\n" . shift @continued;
			push @columns, @continued;
		}

		# trim leading and trailing spaces
		for (@columns) {
			s/^\s*(.*?)\s*$/$1/;
		}

		my $status = $csv->combine(@columns);
		unless ($status) {
			die $csv->error_input();
		}
		print {$out_fh} $csv->string(), ( $option{win} ? "\r" : '' ) . "\n";
	}
}

__DATA__

=head1 NAME

psqlout2csv- <One-line description of commands purpose>

=head1 VERSION

This documentation refers to psqlout2csv version 0.1.

=head1 SYNOPSIS

   psqlout2csv [option] psql_output_file

 OPTIONS:
  -w --win          Out put \r\n instead of \n for windows use

  -V --VERSION       Prints the version information
  -v --verbose       Show more detailed option
  -h --help          Prints this help information
  -m --man           Prints the full documentation for psqlout2csv



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

Please report problems to Ivan Wills (ivanw@benon.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (<ivan.wills@gmail.com>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.


This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

