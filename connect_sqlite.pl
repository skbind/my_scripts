#!/usr/cisco/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use DBI;
use lib '/usr/cisco/packages/cisco-perllib';


#my $db = DBI->connect("dbi:SQLite:dbname=/users/sabind/CBAS_DB/cbas_build","","", { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;

my $dsn = 'DBI:SQLite:dbname=/users/sabind/CBAS_DB/cbas_build';
my $dbh = DBI->connect( $dsn, "", "", { RaiseError => 1, AutoCommit => 1 } ) or die $!;


use DateTime;

		my $scalar_date = scalar localtime(time);
		my @day = split(' ',$scalar_date);
		my $dt = DateTime->now(time_zone => 'local');
        my $date = $dt->strftime("%Y-%m-%d");
        print "scalar_date = $scalar_date :: day = $day[0] :: date = $date \n time = $day[3]\n";
       


=pod

2015-06-25 12:50:01
Thu Jun 25 18:55:24 IST 2015
scalar_date = Thu Jun 25 19:01:19 2015 :: day = Thu :: date = 25/06/2015


my $sql_insert = qq{insert or replace into TEST values(?,?)};
my $sth_insert = $dbh->prepare_cached($sql_insert);
my $sprint = 1;
my $date = 'sandy';

print "\n Inside dump_to_sqlite\n";

$sth_insert->execute($sprint,$date); 
$sth_insert->finish() or die $DBI::errstr;
print "\n AFTER dump_to_sqlite\n";
#$dbh->disconnect  or warn $dbh->errstr;

print "------------------------------------------\n";
=pod
my $query =  qq{select NAME from COMPANY where ID = 1};
my $sth = $db->prepare($query) or die $DBI::errstr;
$sth->execute() or die $DBI::errstr;
my $version = $sth->fetchrow_array();
print "VERSION: $version\n";
print "------------------------------------------\n";
$sth->finish() or die $DBI::errstr;
=cut
