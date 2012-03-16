#!/usr/bin/env perl

# Created on: 2006-06-19 09:26:03
# Create by:  ivanw

use strict;
use warnings;
use Scalar::Util;
use List::Util;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper qw/Dumper/;
use Class::Date qw/now/;
use FindBin;
use DBI;

our $VERSION = 0.1;

my %option = (
    table    => '',
    column   => '',
    range    => '1M',
    add_only => 0,
    test     => 0,
    db_name  => '',
    db_user  => $ENV{USER},
    db_pass  => undef,
    db_host  => undef,
    db_port  => undef,
    verbose  => 0,
    man      => 0,
    help     => 0,
    VERSION  => 0,
);
my $db;
my $dbh;

pod2usage( -verbose => 1 ) unless @ARGV;

main();
exit(0);

sub main {

    Getopt::Long::Configure("bundling");
    GetOptions(
        \%option,
        'table|t=s',
        'column|c=s',
        'range|r=s',
        'add_only|a!',
        'test!',
        'db_name|db-name|n=s',
        'db_user|db-user|u=s',
        'db_pass|db-pass|u=s',
        'db_host|db-host|h=s',
        'db_port|db-port|p=s',
        'verbose|verbose|v!',
        'man',
        'help',
        'VERSION'
    ) or pod2usage(2);

    print "partition-table Version = $VERSION\n" and exit(1) if $option{VERSION};
    pod2usage( -verbose => 2 ) if $option{man};
    pod2usage( -verbose => 1 ) if $option{help} || !$option{db_name} || !$option{table} || !$option{column} || !$option{range} || !(Class::Date::Rel->new($option{range}));

    my $dsn = "dbi:Pg:database=$option{db_name}";
    $dsn .= ';host=' . $option{db_host} if $option{db_host};
    $dsn .= ';port=' . $option{db_port} if $option{db_port};
    $dbh = DBI->connect( $dsn, $option{db_user}, $option{db_pass}, { AutoCommit => 0, RaiseError => 1, PrintError => 1 } );

    # need to do some table introspection (need the column names and the earilest value of $option{column}
    my $now = now();
    $SIG{__DIE__} = sub { $dbh->rollback(); exit 10 };
    warn "TEST\n" if $option{test};

    my @columns;
    my $stmt = $dbh->column_info( undef, 'public', $option{table}, '' );
    $stmt->execute();
    while ( my $row = $stmt->fetchrow_hashref ) {
        push @columns, $row;
    }

    if ( $option{add_only} ) {
        my $indexes;

        # add next months table
        create_range( month => now() + $option{range}, cols => \@columns, );
    }
    else {
        my $indexes;

        # get the min and max times for the table
        my $row = $dbh->selectrow_hashref("SELECT MIN($option{column}), MAX($option{column}) FROM $option{table}");

        # get earilest date as a Class::Date object
        my $current = Class::Date->new( $row->{min} );

        # set now to a point in the future where we should have all dates and one extra range
        my $max = Class::Date->new( $row->{max} );
        $now = ( $now > $max ? $now : $max ) + $option{range} + $option{range};

        warn "Oldest date = $current\nNewest Date = $now\n";
        while ( $current < $now + $option{range} ) {
            create_range( month => $current, cols => \@columns, range => $row );

            $current += $option{range};
        }
        $dbh->rollback() if $option{test};
        $dbh->commit();

        #$dbh->do("VACUUM FULL ANALYZE $option{table}");

        my $min  = int( rand(60) );
        $min     = $min < 10 ? '0' . $min : $min;
        my $hour = int( rand(24) );
        $hour    = $hour < 10 ? '0' . $hour : $hour;
        $option{add_only} = 1;
        $option{verbose}  = 0;
        print "Don't forget to create cron job with:\n";
        print "$min\t$hour\t01\t*\t*\t$FindBin::Bin/$FindBin::Script " . join( ' ', map { !$option{$_} ? () : $_ !~ /add_only|test|verbose|man|help|VERSION/ ? "--$_ $option{$_}" : "--$_" } sort keys %option ) ."\n";
    }

}

sub create_range {
    my %vars      = @_;
    my $year      = $vars{month}->year();
    my $month     = $vars{month}->strftime('%m');
    my $new_table = $option{table} . '_' . $year . '_' . $month;
    my $insert    = $option{table} . '_insert_' . $year . '_' . $month;
    my $start     = $vars{month}->strftime('%Y-%m-01');
    my $end       = ( $vars{month} + $option{range} )->strftime('%Y-%m-01');
    my $where     = "$option{column} >= DATE '$start' AND $option{column} < DATE '$end'";
    my $time      = time;
    my $sql       = <<"SQL";
CREATE TABLE $new_table (
    CHECK ( $where )
) INHERITS ($option{table});
SQL
    print $sql if $option{verbose};
    return     if exists_table($new_table);

    print "CREATE $new_table\n" unless $option{verbose};
    $dbh->do($sql);

    # create insert rule
    my $new_cols  = 'NEW.' . join ', NEW.', map { $_->{COLUMN_NAME} } @{ $vars{cols} };
    my $col_names = join ', ', map { $_->{COLUMN_NAME} } @{ $vars{cols} };
    $sql = <<"SQL";
CREATE RULE $insert AS
ON INSERT TO $option{table} WHERE ( $where )
DO INSTEAD
    INSERT INTO $new_table ($col_names)
    VALUES ( $new_cols );
SQL
    print $sql if $option{verbose};
    $dbh->do($sql);

    # if not testing commit rule so that any new transactions should go into the new table
    unless ( $option{test} ) {
        $dbh->commit();
    }

    # copy the data from old to new table
    $sql = "SELECT * FROM $option{table} WHERE  $where;\n";
    print $sql if $option{verbose};
    my @rows;
    for my $row ( @{ $dbh->selectall_arrayref($sql) } ) {
        push @rows, join "\t", map { defined $_ ? $_ : '\N' } @$row;
    }

    # delete the data from old table
    $sql = "DELETE FROM $option{table} WHERE $where;\n";
    print $sql if $option{verbose};
    $dbh->do($sql);

    # Copy deleted data back into database
    $sql = "COPY $new_table FROM STDIN\n";
    print $sql if $option{verbose};
    $dbh->do($sql);
    for (@rows) {
        $dbh->pg_putline("$_\n");
    }
    $dbh->pg_endcopy();

    print "\n" . ( time - $time ) . "s\n" if $option{verbose};
}

my $exists_table_stmt;

sub exists_table {
    my $table = shift;
    my $schema;
    if ( $table =~ /[.]/ ) {
        ( $schema, $table ) = split /[.]/, $table;
    }
    else {
        $schema = 'public';
    }
    unless ($exists_table_stmt) {
        $exists_table_stmt = $dbh->prepare('SELECT COUNT(*) FROM pg_tables WHERE schemaname = ? AND tablename = ?');
    }
    my $found = $dbh->selectrow_hashref( $exists_table_stmt, undef, $schema, $table );
    return $found->{count};
}

__DATA__

=head1 NAME

partition-table - Partitions at table by date

=head1 VERSION

This documentation refers to partition-table version 0.1.

=head1 SYNOPSIS

   partition-table [option]

 OPTIONS:
  -t --table     The table to partition
  -c --column    The column to partition on
  -r --range     The date range egs 1M, 2M 1Y for one month, 2 months or 1 year
  -a --add-only  Create only new month partition tables
     --test      Do not commit any actions.

  -n --db-name   The name of the database
  -u --db-user   The user to connect as
  -p --db-pass   The password for the user
  -h --db-host   The database server (if not set will connect through sockets)
  -p --db-port   The database server's port

  -v --verbose   Show more detailed option
     --VERSION   Prints the version information
     --help      Prints this help information
     --man       Prints the full documentation for partition-table

=head1 DESCRIPTION

Partitioning PostgreSQL tables by date requires a lot of code especially if
your table already has data and you now need to partition it. This script
aims to help speed up that process.

=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 DEPENDENCIES

There may be issues with different versions of DBD::Pg in the way that it
handles COPY.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

=over 4

=item *

Currently this script leaves indexes on the parent table (which the child
tables inherit) but for more efficiency these should removed and created for
each child table.

=item *

This script also does not try to deal with the problems that occur with
foreign keys to this table. It is recommended that all foreign constraints keys
to the table to be partitioned be dropped before running this script. Not doing
so will almost certainly stop this script from working.

=back

=head1 AUTHOR

Ivan Wills - (ivanw@benon.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia 2077)
All rights reserved.

=cut
