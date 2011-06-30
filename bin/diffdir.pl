#!/usr/bin/env perl

# Created on: 2008-03-13 15:48:46
# Create by:  ivanw
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
use Path::Class;

our $VERSION = version->new('0.0.1');
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

my %option = (
    exclude => '(?:[.]bzr|[.]svn|CVS|RCS|,v|[~-]$|[.]rpmnew|[.]git|[.]sw[op]$|[.]netrwhist$)|/(?:blib|_build)/|/(?:tags|Build|MYMETA.yml|Debian_CPANTS.txt|[.]vimtagsdisplay)$',
    cmd     => 'diff',
    cp      => 0,
    join    => 0,
    script  => 0,
    link    => 0,
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
        'exclude|e=s',
        'cmd|command|c=s',
        'script|s!',
        'cp|cp-missing|m!',
        'same|same-files|S',
        'link|symlink|l!',
        'join|j',
        'follow|f!',
        'ignore-space-change|b',
        'ignore-all-space|w',
        'missing_dirs|missing-dirs|d!',
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
    my %files;
    for my $dir (@dirs) {
        # remove any trailing slashes
        $dir =~ s{/$}{}xms;
        $dir = dir $dir;

        # get the list of all files in the dir
        my @files    = get_files($dir);
        $files{$dir} = { map { s{^$dir/}{}; $_ => 1 } sort @files };
    }

    my %uniq;
    for my $dir ( keys %files ) {
        for my $file ( keys %{$files{$dir}} ) {
            $uniq{$file}++;
        }
    }

    my @messages;
    for my $file ( sort keys %uniq ) {
        warn "diff $dirs[0]/$file $dirs[1]/$file\n" if $option{verbose};
        my $ok = 1;
        my @mesg;
        my @found;
        for my $dir ( keys %files ) {
            if ( !exists $files{$dir}{$file} ) {
                if ( $option{'script'} || $option{'cp'} ) {
                    my $cmd = $option{'cp'} ? 'cp' : $option{'cmd'};
                    if (!@found) {
                        for my $found (keys %files) {
                            next if !-e "$found/$file";
                            push @found, $found;
                        }
                    }
                    for my $found (@found) {
                        file($dir,$file)->parent->mkpath if $option{missing_dirs};
                        push @mesg, "$cmd $found/$file $dir/$file";
                    }
                }
                else {
                    push @mesg, "$dir missing";
                }
                $ok = 0;
            }
            else {
                for my $found (@found) {
                    my $diff = diff("$dir/$file", "$found/$file");

                    if ($diff) {
                        push @mesg, $diff;
                        if ($option{join}) {
                            my $file1 = $file;
                            $file1 =~ s/([.]\w+)$/.1$1/xms;
                            my $file2 = $file;
                            $file2 =~ s/([.]\w+)$/.2$1/xms;

                            if ($file1 ne $file2) {
                                my ($dir_start, $dir_end);
                                my ($found_start, $found_end);

                                if ($dir =~ m{/}) {
                                    ($dir_start, $dir_end) = $dir =~ m{^(.*)/([^/]+)/?$};
                                }
                                else {
                                    $dir_end = $dir;
                                }
                                if ($dir =~ m{/}) {
                                    ($found_start, $found_end) = $found =~ m{^(.*)/([^/]+)/?$};
                                }
                                else {
                                    $found_end = $found;
                                }

                                my $dest = $dir_start ? "$dir_start/$dir_end\_$found_end" : "$dir_end\_$found_end";

                                system "mkdir $dest" if !-d $dest;
                                system "cp $dir/$file   $dest/$file1" if -d $dest;
                                system "cp $found/$file $dest/$file2" if -d $dest;
                            }
                        }
                        $ok = 0;
                    }
                    elsif ($option{same}) {
                        print "$file\n";
                    }
                }

                push @found, $dir;
            }
        }

        if ( !$ok ) {
            push @messages, { file => $file, messages => \@mesg };
        }
    }

    return if $option{same};

    if ( $option{'script'} ) {
        for my $msg ( @messages ) {
            print join "\n", @{$msg->{messages}};
            print "\n";
        }
        return;
    }

    my $length = 8;
    for my $msg ( @messages ) {
        if ( length $msg->{file} > $length ) {
            $length = length $msg->{file};
        }
    }
    $length++;

    for my $msg ( @messages ) {
        print $msg->{file} . ' ' x ($length - length $msg->{file});
        print join "\t", @{ $msg->{'messages'} };
        print "\n";
    }

    return;
}

sub diff {
    my ($file1, $file2) = @_;

    return if !$option{link} && (-l $file1 || -l $file2);

    $file1 =~ s/'/'\\''/gxms;
    $file1 = "'$file1'";
    $file2 =~ s/'/'\\''/gxms;
    $file2 = "'$file2'";

    my $cmd  = '/usr/bin/diff';
    if ( $option{'ignore-space-change'} ) {
        $cmd .= ' --ignore-space-change';
    }
    if ( $option{'ignore-all-space'} ) {
        $cmd .= ' --ignore-all-space';
    }
    $cmd  .= " $file1 $file2";
    my $diff = `$cmd`;

    if ($diff) {
        warn "$option{cmd} $file1 $file2\n" if $option{verbose};
        return "$option{cmd} $file1 $file2";
    }

    return;
}

sub get_files {
    my ($dir, $skip_missing) = @_;
    my @found;

    die "The directory '$dir' does not exist!\n" if !$skip_missing && !-d $dir;
    warn "$dir\n" if $option{verbose};

    FILE:
    for my $file ( $dir->children ) {
        next FILE if $file =~ /^[.].*[.]sw[p-z]$|^[.](?:svn|bzr|git)$/;
        next FILE if $option{exclude} && $file =~ /$option{exclude}/;

        if ( -d $file && ($option{follow} || !-l $file) ) {
            push @found, get_files($file, 1);
        }
        elsif ( !-d $file ) {
            push @found, $file;
        }
    }

    return @found;
}

__DATA__

=head1 NAME

diffdir - Compares two or more directories for files that differ

=head1 VERSION

This documentation refers to diffdir version 0.1.

=head1 SYNOPSIS

   diffdir [option]

 OPTIONS:
  -e --exclude=re Elclude any file or directory that matches this regular
                  expression
  -s --script     Produce a script of actions
  -c --cmd=string Use this command instead of diff in the listing.
  -m --cp-missing Create a copy statement for missing files rather than
                  telling which directory it was missing from
  -S --same-files Show the same files instead of different files
  -j --join       Combines the file into a thrid baised on the original directory names.
  -b  --ignore-space-change
                  Ignore changes in the amount of white space.
  -w  --ignore-all-space
                  Ignore all white space.
  -d --missing-dirs
                  Create directories that are missing (makes copying of missing files simpler)

  -v --verbose    Show more detailed option
     --version    Prints the version information
     --help       Prints this help information
     --man        Prints the full documentation for diffdir

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

Ivan Wills - (ivanw@benon.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
