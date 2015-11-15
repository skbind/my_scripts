#!/usr/cisco/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use DBI;
use Env;
use lib "/usr/cisco/packages/dbdoracle/9.2.0";
use lib '/usr/cisco/packages/cisco-perllib';

$ENV{'ORACLE_HOME'} = '/usr/cisco/packages/dbdoracle/9.2.0';
my $data_source = 'dbi:Oracle:host=sjc-dbpl-bld.cisco.com;sid=PBAS;port=1521';
my $user = "IRE_CLIENT";
my $pass = "IRE_369";
my $db = DBI->connect($data_source, $user, $pass, { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;

my ($branch,$help_msg);
GetOptions(
    "help|h"        => \$help_msg,
    "branch|b:s"     => \$branch,
) or die " Error \n";

if ($help_msg) {
    system("/usr/cisco/bin/perldoc -t $0 ");
    exit 0;
}


print "------------------------------------------\n";
my $query =  qq{select RELEASE_NUM from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where FREEZE_TIME = ( select max(FREEZE_TIME) from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where branch_name like '%$branch%' and REQUEST_TYPE = 'RENUMBER')  and branch_name like '%$branch%' and REQUEST_TYPE = 'RENUMBER' and ROWNUM = 1};
my $sth = $db->prepare($query) or die $DBI::errstr;
$sth->execute() or die $DBI::errstr;
my $version = $sth->fetchrow_array();
print "VERSION: $version\n";
print "------------------------------------------\n";
$sth->finish() or die $DBI::errstr;
$db->disconnect  or warn $db->errstr;

