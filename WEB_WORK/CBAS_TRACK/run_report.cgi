#!/usr/cisco/bin/perl

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);
use Time::localtime;
use DBI;
use Date::Calc qw/Delta_DHMS/;
use Date::Calc qw/Delta_Days/;
use Data::Dumper;

#my $dsn = 'DBI:SQLite:dbname=/users/sabind/CBAS_DB/cbas_build';
#my $dbh_sqlite = DBI->connect( $dsn, "", "", { RaiseError => 1, AutoCommit => 1 } ) or die $!;

$|=1;

my $cgi = CGI->new();

    print $cgi->header();
    print $cgi->start_html(
              -title => 'Run Report',);
&func();
sub func {

    print $cgi->start_div();
    print $cgi->start_table();
    print $cgi->Tr($cgi->th({colspan => 1},['Integrator','RnD','RID','CL','Source']));
    
    my @arr = (1..5);
    print $cgi->Tr(\@arr);
    print $cgi->end_table();
    print $cgi->end_div();

}


print $cgi->end_html();
