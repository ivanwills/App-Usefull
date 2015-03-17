#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

if ( not $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test.  Set TEST_AUTHOR environment variable to a true value to run.';
    plan( skip_all => $msg );
}

# check that Test::Spelling is installed
eval { require Test::Spelling; Test::Spelling->import() };

# now check that the spell command is installed
my $found;
for my $dir ( split /:/, $ENV{PATH} ) {
    next if !-d $dir;
    next if !-x "$dir/spell";

    $found = 1;
    last;
}

plan skip_all => "Test::Spelling required for testing POD spelling" if $@;
plan skip_all => "spell command required for testing POD spelling" if !$found;

add_stopwords(qw/
    NSW
    Hornsby
    avg
    bigfiles
    chkfacl
    cmdaliaser
    conf
    configs
    csv
    ctrl
    cvs
    devmode
    devremote
    Diff
    diffdir
    duuser
    eg
    fdiff
    gitrev
    hlist
    html
    http
    httprecorder
    img
    iwills
    myget
    ossh
    pingfind
    PostgreSQL
    pre
    psqlout
    rhymbox
    stddev
    STDOUT
    svn
    svntouch
    url
    vims
    Wynter
    mssh
    ssh
    GIT's
    HEREDOCS
    evaled
    ie
    perlmodver
    xargs
    yargs
    du
    duhs
    hs
    hl
    incsearch
    fv
    pmver
    vrc
    yml
    tidyup
    cpanm
    iNotify
    rhythmbox
    chkspell
    pl
    colour
    df
    itop
    psql
    pmwhich
    com
    npmjs
    nodedoc
    cp
    fspot
    swapfiles
    jshint
    jshtml
/);
all_pod_files_spelling_ok();
