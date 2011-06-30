#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

plan skip_all => 'Have to work out how to test pod of bin files';
# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
