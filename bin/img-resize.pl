#!/usr/bin/env perl

# Created on: 2008-05-24 11:22:01
# Create by:  ivan
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
use File::stat;
use Image::Resize;

our $VERSION = version->new('0.0.1');
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

my %option = (
	in      => "$ENV{HOME}/Photos/in",
	out     => "$ENV{HOME}/Photos/out",
	delete  => 1,
	width   => 700,
	height  => undef,
	verbose => 0,
	man     => 0,
	help    => 0,
	VERSION => 0,
);

main();
exit 0;

sub main {

	Getopt::Long::Configure('bundling');
	GetOptions(
		\%option,
		'in|i=s',
		'out|o=s',
		'delete|d!',
		'width|w=i',
		'height|h=i',
		'verbose|v+',
		'man',
		'help',
		'VERSION!',
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

	# do stuff here
	my @images = get_images();

	for my $image (@images) {
		print "$image\n" if $option{verbose};
		resize_image($image);
	}

	return;
}

sub resize_image {

	my $image = shift;

	# create the resize object
	my $ir     = Image::Resize->new("$option{in}/$image");
	my $height = $ir->height();
	my $width  = $ir->width();

	my ($new_height, $new_width) = ($option{height}, $option{width});
	my $ratio_image = $height / $width;
	my $ratio_new   = $new_height / $new_width;

	if ($ratio_image < $ratio_new) {
		$new_height *= $ratio_image / $ratio_new;
	}
	else {
		$new_width *= $ratio_new / $ratio_image;
	}

	# resize the image baised on the supplied width
	my $gd = $ir->resize( $new_width, $new_height );
	#<image xlink:href="01.jpg" x="11.88" y="59.0391990778516" height="157.484192634561" width="273.24"/>

	# write the image to the output directory
	open my $out, '>', "$option{out}/$image" or die "Could not write resized image to $option{out}/$image: $OS_ERROR\n";
	print {$out} $gd->jpeg;
	close $out;

	# set the output image creation and modification times to that of the
	# input image
	system "touch -r $option{in}/$image $option{out}/$image";

	# delete the input image if requested
	if ($option{delete}) {
		unlink "$option{in}/$image";
	}

	return;
}

sub get_images{

	# open and read in all files in the input directory
	opendir my $dir, $option{in} or die "Could not open the directory $option{in} for reading: $OS_ERROR\n";
	my @files = grep { $_ ne q{.} && $_ ne q{..} } readdir $dir;
	closedir $dir;
	my @images;

	# check all files are image files
	IMAGE:
	for my $image (@files) {
		print "$image\n" if $option{verbose};
		next IMAGE if $image !~ /[.](jpe?g|png|gif)$/ixms;

		# check if a file of the same name exists in the output directory
		# that it does not have the same modified as the input image
		if ( -e "$option{out}/$image" ) {
			my $in_st  = stat "$option{in}/$image";
			my $out_st = stat "$option{out}/$image";

			next IMAGE if $in_st->mtime == $out_st->mtime;
		}

		# add the file to the list of images
		push @images, $image;
	}

	return @images;
}

__DATA__

=head1 NAME

img-resize - Resized images all found in a directory and puts the resized
images into a new directory

=head1 VERSION

This documentation refers to img-resize version 0.1.

=head1 SYNOPSIS

   img-resize [option]

 OPTIONS:
  -i --in=dir     Directory containing images to be resized
  -o --out=dir    Output file directory for resized images
  -h --height=int New image height maximum
  -w --width=ing  New image width maximum
     --nodelete   Don't delete the original files after resizing

  -v --verbose    Show more detailed option
     --version    Prints the version information
     --help       Prints this help information
     --man        Prints the full documentation for img-resize

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

Copyright (c) 2008 Ivan Wills (101 Miles St Bald Hills QLD Australia 4036).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
