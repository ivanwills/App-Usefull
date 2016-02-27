#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;
use File::Spec;

use_ok('App::Useful');

my $base = path($0)->parent->parent;
my $lib  = $base->child('lib');
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
my $bin = $base->child('bin');
@files = $bin->children;

my %skippable = (
    'bin/img-resize' => 'Image/Resize.pm',
    'bin/posture'    => 'Gtk3/Notify.pm',
    'bin/img-size'   => 'Image/Resize.pm',
);
while ( my $file = shift @files ) {
    if ( -d $file ) {
        push @files, $file->children;
    }
    elsif ( $file !~ /[.]sw[ponx]$/ ) {
        my ($bang) = $file->slurp;
        next if $bang !~ /perl/;
        if ( $skippable{$file} && !eval { require $skippable{$file} } ) {
            next;
        }
        ok !(system $perl, qw/-Ilib -c /, $file), "$file compiles";
    }
}

diag( "Testing App::Useful $App::Useful::VERSION, Perl $], $^X" );
done_testing();
