#!/usr/bin/env perl

# Created on: 2006-05-31 13:04:55
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
use Path::Class;
use File::CodeSearch::Files;

our $VERSION = version->new('0.0.1');
my ($name) = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

my %option = (
    files   => 1,
    follow  => 0,
    verbose => 0,
    man     => 0,
    help    => 0,
    VERSION => 0,
);
my %join = (
    start => '+-+ ',
    mid   => '--',
    end   => '__',
);
my $files;
sub say;

main();
exit 0;

sub main {

    Getopt::Long::Configure('bundling');
    GetOptions(
        \%option,
        'all|a!',
        'dirfirst|d!',
        'files!',
        'symlinks|follow|l!',
        'exclude|e=s@',
        'include|i=s@',
        'exclude_type|exclude-type|E=s@',
        'include_type|include-type|I=s@',
        'narrow|n',
        'verbose|v!',
        'man',
        'help',
        'VERSION'
    ) or pod2usage(2);

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

    if ($option{narrow}) {
        %join = (
            start => '++ ',
            mid   => '-',
            end   => '_',
        );
    }

    $files = File::CodeSearch::Files->new(%option);

    my @files = @ARGV ? @ARGV : qw/./;

    for my $file (@files) {
        my $start = start($file);
        list( file => dir($file), line_start => $start );
    }
}

sub list {
    my %args = @_;

    if ( -d $args{file} ) {
        #my @files = grep { $files->file_ok($_) } $args{file}->children;
        my @files = $args{file}->children;

        if ( $option{dirfirst} ) {
            @files = sort {
                  -f "$args{file}/$a" && -f "$args{file}/$b" ? $a cmp $b
                : -d "$args{file}/$a" && -d "$args{file}/$b" ? $a cmp $b
                : -d "$args{file}/$a" && -f "$args{file}/$b" ? -1
                : -f "$args{file}/$a" && -d "$args{file}/$b" ?  1
                :                                               0
            } @files;
        }
        else {
            @files = sort @files;
        }

        # remove hidden files unless option all used
        if ( !$option{all} ) {
            @files = grep { !/^[.]/xms } @files;
        }

        # remove non directories unless requested to keep them
        if ( !$option{files} ) {
            @files = grep { -d "$args{file}/$_" } @files;
        }

        FILE:
        for ( my $i = 0; $i < @files; $i++ ) {
            my $file = $files[$i];

            if ( -d $file && ($option{follow} || !-l $file) ) {
                say $args{line_start} . $join{start} . ( $option{verbose} ? $file : $file->dir_list(-1) );
                list(
                    file       => $file,
                    line_start => $args{line_start} . ( $i == @files - 1 ? ' ' : '|' ) . ( $option{narrow} ? '' : ' ' ),
                );
            }
            else {
                say $args{line_start} . '|' . ( $i == @files - 1 ? $join{end} : $join{mid} ) . ' ' . ( $option{verbose} ? $file : $file->basename );
            }
        }
    }
    else {

        say $args{line_start}. '- '. $args{file};
    }
}

sub say {
    print @_, "\n";
}

sub start {
    my ($file) = @_;
    my @parts = split m{/}, $file;
    my $start = '';

    if ( @parts == 1 || $option{verbose} ) {
        say $file;
        return $option{narrow} ? '' : ' ';
    }

    for my $part (@parts) {
        say $start, $part;
        $start = '   ' if !$start && !$option{narrow};
        $start = ( ' ' x ( ( length $start ) + 2 - length $join{start} ) ) . $join{start};
    }

    return ' ' x ( ( length $start ) - $option{narrow} - length  $join{start} );
}

__DATA__

=head1 NAME

hlist - A pritty hirachal directory listing

=head1 VERSION

This documentation refers to hlist version 0.1.

=head1 SYNOPSIS

   hlist [option]

 OPTIONS:
  -a --all       Show all files including files starting with a dot (.)
  -d --dirsfirst Shows directories first
     --nofiles   Show only the directory structure
  -l --follow    Follow sim-links
  -e --exclude=regex
                 Exclude files & directories matching the regex

  -v --verbose   Show more detailed option
     --VERSION   Prints the version information
     --help      Prints this help information
     --man       Prints the full documentation for hlist

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

Copyright (c) 2006 Ivan Wills (14 Mullion Cl, Hornsby Heights, NSW, Australia, 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
