#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

my @poddirs = -d path($0)->parent->subdir('../blib') ? qw/ blib / : qw/ lib bin /;
all_pod_files_ok( all_pod_files( @poddirs ) );

