#!/usr/cisco/bin/perl

use strict;
use DBI;
use Env;
use lib "/usr/cisco/packages/dbdoracle/9.2.0";

$ENV{'ORACLE_HOME'} = '/usr/cisco/packages/dbdoracle/9.2.0';
my $data_source = 'dbi:Oracle:host=sjc-dbpl-bld.cisco.com;sid=PBAS;port=1521';
my $user = "IRE_CLIENT";
my $pass = "IRE_369";

if (scalar @ARGV == 0)
{
 print "Enter atleast one buildId to continue; Terminating! \n\n";
 exit 1;
}

my %buildId;

foreach (@ARGV)
{
 $buildId {$_} = "Place holder"; 
}

my $db = DBI->connect($data_source, $user, $pass, { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;
my $temp;

print "------------------------------------------\n\n";
foreach $temp (keys %buildId)
{
 my $query = qq{select REQUEST_DESC, BUILD_SERVER, NUM_IMAGE_LIST, NUM_IMAGE_LIST_BUILT, NUM_IMAGE_LIST_FAILED, LOGDIR from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where REQUEST_ID = '$temp' order by FREEZE_TIME desc};
 ##print "QUERY => $query\n";

 my $sth = $db->prepare($query) or die $DBI::errstr;
 $sth->execute() or die $DBI::errstr;
 my @ary = $sth->fetchrow_array;

 print "ReqId: \"$ary[0]\" \t BuildServer: $ary[1]\n";
 print "Total Images: $ary[2] \t\t Built: $ary[3] \t\t Failed: $ary[4]\n";
 print "LogDirectory: $ary[5]\n\n";
}
print "------------------------------------------\n";

$db->disconnect();

#print "Exit\n\n";


