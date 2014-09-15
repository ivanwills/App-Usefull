#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use File::Spec;

my $base = file($0)->parent->parent;
my $lib  = $base->subdir('lib');
my @files = $lib->children;

while ( my $file = shift @files ) {
    if ( -d $file ) {
        push @files, $file->children;
    }
    elsif ( $file =~ /[.]pm$/ ) {
        require_ok $file;
    }
}

my $perl = File::Spec->rel2abs($^X);
my $bin = $base->subdir('bin');
@files = $bin->children;

my $perl = File::Spec->rel2abs($^X);
while ( my $file = shift @files ) {
    if ( -d $file ) {
        push @files, $file->children;
    }
    elsif ( $file !~ /[.]sw[ponx]$/ ) {
        my ($bang) = $file->slurp;
        next if $bang !~ /perl/;
        ok !(system $perl, qw/-Ilib -c /, $file), "$file compiles";
    }
}

diag( "Testing App::Useful $App::Useful::VERSION, Perl $], $^X" );
done_testing();
