#!/usr/bin/env perl

# Created on: 2008-03-27 10:35:12
# Create by:  ivanw
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;
use Data::Dump::Streamer qw/Dump/;
use English qw/ -no_match_vars /;

our $VERSION = version->new('0.0.1');
my ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;

my %option = (
    player  => $ENV{'PLAYER_PAUSE_PLAYER'} || 'rhythmbox',
    changer => $ENV{'PLAYER_PAUSE_CHANGER'},
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
        'player|p=s',
        'changer|c=s',
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
    if ( $option{'changer'} ) {
        loader($option{'changer'});
    }
    else {
        eval{ loader('dbus') };
        if ($EVAL_ERROR) {
            eval{ loader('x11') };
            if ($EVAL_ERROR) {
                die "You need to install eather Net::DBus or X11::Protocol\n";
            }
            $option{'changer'} = 'x11';
        }
        else {
            $option{'changer'} = 'dbus';
        }
    }
    loader($option{'player'});

    start($option{'changer'});

    return;
}

sub start {
    my ($changer) = @_;

    if ( $changer eq 'dbus' ) {
        require Net::DBus;
        require Net::DBus::Reactor;

        Dump my $bus = Net::DBus->find;
        die;
        Dump my $screensaver = $bus->get_service("org.gnome.ScreenSaver");

        my $screensaver_object = $screensaver->get_object("/org/gnome/ScreenSaver", "org.gnome.ScreenSaver");
        Dump $screensaver_object;
        $screensaver_object->connect_to_signal('ActiveChanged', \&ActiveChanged );
        die "end";

        warn my $reactor = Net::DBus::Reactor->main();
        warn is_playing(player($option{player})) ? "is currently playing" : "is currently stopped";
        $reactor->run();
    }
    elsif ( $changer eq 'x11' ) {
        require X11::Protocol::Ext::DPMS;

        my $x = X11::Protocol->new();
        $x->init_extension('DPMS');

        my $power_level = '';
        while (1) {
            my $old_pl = $power_level;
            ($power_level, undef) = $x->DPMSInfo();
            if( $old_pl eq 'DPMSModeOn' && $power_level ne 'DPMSModeOn' ) {
                ActiveChanged(1);
            }
            elsif ( $power_level eq 'DPMSModeOn' && $old_pl ne 'DPMSModeOn' ) {
                ActiveChanged(0);
            }
        }
    }

    return;
}

{
    my $was_playing = 0;

    sub ActiveChanged {
        my ($active) = @_;
        warn "Detected a state change!\n";
        my $player = player($option{player});

        if ($active && is_playing($player)) {
            $was_playing = 1;
              $player->can('pause')     ? $player->pause()
            : $player->can('playPause') ? $player->playPause(1)
            :                             die "Can't pause or playPause!\n";
        }
        elsif ($was_playing) {
            $was_playing = 0;
              $player->can('play')      ? $player->play()
            : $player->can('playPause') ? $player->playPause(0)
            :                             die "Can't play or playPause!\n";
        }

        return;
    }
}

{
    my $player;
    my $count;

    sub player {
        my ($player) = @_;

        if ($player eq 'mpd') {
            warn "Pausing MPD\n" if ( $option{verbose} && !$count++ ) || $option{verbose} > 1;
            $player = eval{ Audio::MPD->new() };

            if ($EVAL_ERROR) {
                die "Please start MPD\n";
            }
        }
        elsif ($player eq 'amarok') {
            warn "Pausing Amarok\n" if ( $option{verbose} && !$count++ ) || $option{verbose} > 1;
            $player = DCOP::Amarok::Player->new();
        }
        elsif ($player eq 'rhythmbox') {
            warn "Pausing for Rhythmbox\n" if ( $option{verbose} && !$count++ ) || $option{verbose} > 1;
            my $bus = Net::DBus->find;
            my $rhythmbox = $bus->get_service("org.gnome.Rhythmbox");

            $player = $rhythmbox->get_object("/org/gnome/Rhythmbox/Player", "org.gnome.Rhythmbox.Player");
        }

        return $player;
    }
}

sub is_playing {
    my ($player) = @_;

    if ($option{'player'} eq 'mpd') {
        my $status = $player->status();
        return $status->state() eq 'play';
    }
    elsif ($option{'player'} eq 'amarok') {
        return $player->status() == 2;
    }
    elsif ($option{'player'} eq 'rhythmbox') {
        return $player->getPlaying();
    }
    else {
        die "$option{'player'} does not have a method to determine if it is currently playing!\n";
    }

    return;
}

sub loader {
    my ($load) = @_;

    my $module =
          $load eq 'mpd'       ? 'Audio::MPD'
        : $load eq 'amarok'    ? 'DCOP::Amarok::Player'
        : $load eq 'rhythmbox' ? 'Net::DBus'
        : $load eq 'dbus'      ? 'Net::DBus'
        : $load eq 'x11'       ? 'X11::Protocol'
        :                        die "Unknown type $load!\n";
    my $file = $module;
    $file =~ s{::}{/}xms;
    $file .= '.pm';

    eval{ require $file };
    if ($EVAL_ERROR) {
        die "Please install $module\n";
    }

    return;
}

__DATA__

=head1 NAME

player-pause - Pauses music players when the screen saver starts.

=head1 VERSION

This documentation refers to player-pause version 0.1.

=head1 SYNOPSIS

   player-pause [option]

 OPTIONS:
  -p --player=mpd|amarok|rhythmbox
               Sets the player to pause when the screen saver starts
  -c --changer=dbus|x11
               Sets the method for determining that the that the screen
               saver has started. Will try to use dbus then x11 if not
               specified.
               - dbus: checks weather the Gnome screen savers has started
               - x11: checks with X11 weather the screen saver has started

  -v --verbose Show more detailed option
     --version Prints the version information
     --help    Prints this help information
     --man     Prints the full documentation for player-pause

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

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
