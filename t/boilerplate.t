#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Data::Dumper qw/Dumper/;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    die Dumper \%violated if %violated;
    for my $test (keys %regex) {
        ok !$violated{$test}, $test or diag "$test appears on lines @{$violated{$_}}";
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    subtest $module => sub {
        not_in_file_ok($module =>
            'the great new $MODULENAME' => qr/ - The great new /,
            'boilerplate description'   => qr/Quick summary of what the module/,
            'stub function definition'  => qr/sub\s+function[12]/,
            'module description'        => qr/One-line description of module/,
            'description'               => qr/A full description of the module/,
            'subs / methods'            => qr/section listing the public components/,
            'diagnostics'               => qr/A list of every error and warning message/,
            'config and environment'    => qr/A full explanation of any configuration/,
            'dependencies'              => qr/A list of all of the other modules that this module relies upon/,
            'incompatible'              => qr/any modules that this module cannot be used/,
            'bugs and limitations'      => qr/A list of known problems/,
            'contact details'           => qr/<contact address>/,
        );
    };
}

subtest 'README' => sub {
    not_in_file_ok((-f 'README' ? 'README' : 'README.pod') =>
        "The README is used..."       => qr/The README is used/,
        "'version information here'"  => qr/to provide version information/,
    );
};

subtest 'Changes' => sub {
    not_in_file_ok(Changes =>
        "placeholder date/time"       => qr(Date/time)
    );
};

module_boilerplate_ok('bin/bigfiles');
module_boilerplate_ok('bin/blame-line');
module_boilerplate_ok('bin/builder');
module_boilerplate_ok('bin/char2line');
module_boilerplate_ok('bin/chkspell');
module_boilerplate_ok('bin/cmdaliaser');
module_boilerplate_ok('bin/coder');
module_boilerplate_ok('bin/csv2html-table.pl');
module_boilerplate_ok('bin/df-colour');
module_boilerplate_ok('bin/duhs');
module_boilerplate_ok('bin/duuser');
module_boilerplate_ok('bin/fdiff');
module_boilerplate_ok('bin/fspot-cp');
module_boilerplate_ok('bin/highlight');
module_boilerplate_ok('bin/hl');
module_boilerplate_ok('bin/hlist');
module_boilerplate_ok('bin/html-cleaner');
module_boilerplate_ok('bin/httprecorder');
module_boilerplate_ok('bin/img-resize');
module_boilerplate_ok('bin/img-size');
module_boilerplate_ok('bin/incsearch');
module_boilerplate_ok('bin/itop');
module_boilerplate_ok('bin/jshtml');
module_boilerplate_ok('bin/lines');
module_boilerplate_ok('bin/module-dependencies');
module_boilerplate_ok('bin/myget');
module_boilerplate_ok('bin/nodedoc');
module_boilerplate_ok('bin/partition-table.pl');
module_boilerplate_ok('bin/pingfind');
module_boilerplate_ok('bin/player-alarm');
module_boilerplate_ok('bin/player-pause.pl');
module_boilerplate_ok('bin/pmver');
module_boilerplate_ok('bin/pmwhich');
module_boilerplate_ok('bin/posture');
module_boilerplate_ok('bin/psqlout2csv.pl');
module_boilerplate_ok('bin/rhythmbox-ctl.pl');
module_boilerplate_ok('bin/schema-loader');
module_boilerplate_ok('bin/set-title');
module_boilerplate_ok('bin/ssh-forwards');
module_boilerplate_ok('bin/ssh-to');
module_boilerplate_ok('bin/stop-watch');
module_boilerplate_ok('bin/suggest-tests');
module_boilerplate_ok('bin/swapfiles');
module_boilerplate_ok('bin/tidyup');
module_boilerplate_ok('bin/v');
module_boilerplate_ok('bin/validate_json');
module_boilerplate_ok('bin/vims');
module_boilerplate_ok('bin/yargs');
module_boilerplate_ok('lib/App/Useful.pm');
done_testing();
