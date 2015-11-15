#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use DBI;
use lib "/usr/cisco/packages/dbdoracle/9.2.0";
$ENV{'ORACLE_HOME'} = '/usr/cisco/packages/dbdoracle/9.2.0';

$|=1;


my $data_source = 'dbi:Oracle:host=sjc-dbpl-bld.cisco.com;sid=PBAS;port=1521';
my $user = "IRE_CLIENT";
my $pass = "IRE_369";

my $db = DBI->connect($data_source, $user, $pass, { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;
$db->{LongReadLen} = 66000;
$db->{LongTruncOk} = 1;

my %result_set;
my @rid = ('6536310');
my @r_data;
my $sth;
foreach my $id  (@rid){
	chop $id if($id !~ /\d$/);
	my $query =  qq{select LABEL_NAME,IMAGE_LIST,NUM_IMAGE_LIST_BUILT,NUM_IMAGE_LIST_FAILED from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where BUILD_SEQ_NUM = ( select max(BUILD_SEQ_NUM) from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where REQUEST_ID = '$id' ) and REQUEST_ID = '$id' };
 	$sth = $db->prepare($query) or die $DBI::errstr;
 	$sth->execute() or die $DBI::errstr;
	$result_set{$id} =  $sth->fetchrow_hashref();
}
print Dumper(\%result_set);