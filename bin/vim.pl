#!/usr/bin/env perl

# Created on: 2010-09-29 08:56:56
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Getopt::Alt qw/get_options/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Class;

our $VERSION = version->new('0.0.1');
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

main();
exit 0;

sub main {

    my ($opt, $cmd) = get_options(
        {
            sub_command => 1,
            default     => {
                max_time => 1,
            }
        },
        [
            'find|f+',
            'max_time|a=i',
            'skip|s=s',
            'O',
            'o',
            'test|t!',
            'verbose|v+',
        ]
    );
    unshift @ARGV, $cmd if $cmd;

    if ( $opt->find ) {
        my @dirs  = ( dir('.') );
        my @files = $dirs[0]->children;
        my $start = time;

        while ( my $file = shift @files ) {
            next if $opt->{skip} && $file =~ /$opt->{skip}/;
            last if time > $start + $opt->max_time;

            if ( -d $file ) {
                push @files, $file->children;
                push @dirs, $file;
            }
        }

        my %files;
        @files = ();
        for my $file (@ARGV) {
            my $found;
            if ( $file !~ /^-/ ) {
                for my $dir (@dirs) {
                    my $test = "$dir/$file";
                    my $count = @files;
                    if ( -f $test && !$files{$test} ) {
                        push @files, $test;
                        $files{$test}++;
                    }
                    push @files, grep { -f $_ && !$files{$_}++ } glob $test;
                    $found ||= $count != @files;
                }
            }
            push @files, $file if !$found;
        }
        @ARGV = @files;
    }

    my @files;
    my $current = dir('.')->absolute;
    my $home    = dir($ENV{HOME})->absolute;
    ARG:
    for my $arg (@ARGV) {
        next ARG if !-f $arg;
        my $file = file($arg)->absolute;
        next ARG if !$current->subsumes($file);

        push @files, $file;
    }

    # create ctags info
    if ( @files && $current ne $home && ( -d 'lib' || -d 'bin' ) ) {
        my $tags = file('tags');
        if ( ! -f $tags ) {
            create_tags($opt);
        }
        else {
            my $tag_mtime = $tags->stat->mtime;

            FILE:
            for my $file (@files) {
                next if $file->stat->mtime < $tag_mtime;
                unlink $tags;
                create_tags($opt);
                last FILE;
            }
        }
    }

    for my $vim_opt (qw/ o O /) {
        push @ARGV, "-$vim_opt" if $opt->$vim_opt;
    }

    $cmd = '/usr/bin/vim ' . join ' ',  map { shell_quote($_) } @ARGV;
    warn "$cmd\n" if $opt->verbose || $opt->test;

    return exec $cmd if !$opt->test;
}

sub shell_quote {
    my ($text) = @_;

    # check for unsafe shell characters
    return $text if $text !~ / [\s$|><;#] /xms;

    $text =~ s/'/'\\''/gxms;

    return "'$text'";
}

sub create_tags {
    my ($opt) = @_;
    my $tag = file('/usr', 'bin', 'ctags');
    return if !-x $tag;

    my @exclude = qw/blib _build Build tmp node_modules/;
    my $cmd = "$tag -R --exclude=" . join ' --exclude=', @exclude;

    warn "$cmd\n" if $opt->verbose || $opt->test;
    system $cmd if !$opt->test;

    return;
}

__DATA__

=head1 NAME

vim.pl - Vim helper

=head1 VERSION

This documentation refers to vim.pl version 0.1.

=head1 SYNOPSIS

   vim.pl (file [file ...])
   vim.pl (--find|-f) [-s|--skip dir] file_or_file_glob (file_or_file_glob|vim_option)*

 OPTIONS:
  -f --find     Find files/file globs
  -s --skip[=]regex
                Skip any matching directories
  -t --test     Don't run vim just show what would be run

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for vim.pl

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills

Patches are welcome.

=head1 AUTHOR

Ivan Wills

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Ivan Wills
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
