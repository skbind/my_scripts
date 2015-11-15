#!/usr/cisco/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use DBI;
use Env;
use lib "/usr/cisco/packages/dbdoracle/9.2.0";

$ENV{'ORACLE_HOME'} = '/usr/cisco/packages/dbdoracle/9.2.0';
my $data_source = 'dbi:Oracle:host=sjc-dbpl-bld.cisco.com;sid=PBAS;port=1521';
my $user = "IRE_CLIENT";
my $pass = "IRE_369";
my $db = DBI->connect($data_source, $user, $pass, { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;

my ($list,$build,$help_msg);

GetOptions(
    "list|f:s" 	    => \$list,
    "help|h"        => \$help_msg,
    "build|b:s"     => \$build,
) or die " Error \n";

if ($help_msg) {
    system("/usr/cisco/bin/perldoc -t $0 ");
    exit 0;
}

my @build_id;
if($build && $list){
	print "\n[ -b] and [ -f] both are mutually exclusive switches !!!\n For more details please see help\n";
    exit 0;	
}elsif ( $list && -f $list) {
	open (FH,"<$list") or die "Can't open the file: $list\n";
	foreach (<FH>){
		chomp;
 		push @build_id,$_;
	}
}elsif($build){
	print "BUILD:$build\n";
}else{
	print "NO builds passed\n";
	print "Enter atleast one buildId to continue; Terminating! \n\n";
 	exit 1;
}

print "------------------------------------------\n\n";
my %result_set;
foreach my $id (@build_id) {
	my $query =  qq{select REQUEST_ID,REQUEST_DESC,REQUEST_TYPE,BUILD_SEQ_NUM,BUILD_SERVER,BUILD_DIR,LOGDIR,BRANCH_NAME,LABEL_NAME,NUM_IMAGE_LIST,NUM_IMAGE_LIST_BUILT,NUM_IMAGE_LIST_FAILED,START_TIME,END_TIME from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where FREEZE_TIME = ( select max(FREEZE_TIME) from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where REQUEST_ID = '$id')  and REQUEST_ID = '$id' and ROWNUM = 1 };
 	my $sth = $db->prepare($query) or die $DBI::errstr;
 	$sth->execute() or die $DBI::errstr;
	while( my $ref = $sth->fetchrow_hashref) {
    	$result_set{$ref->{REQUEST_ID}} = $ref;
	}
}
my $val = $result_set{'6444218'}->{REQUEST_DESC};
#print "\n VAL :: $val\n";
print Dumper(\%result_set);
$db->disconnect();
print "------------------------------------------\n\n";


=head1 NAME

build_moniter.pl - This script is to get early notification about build failure.

=head1 SYNOPSIS

build_moniter.pl script can be invoked like this:


=item B<build_moniter.pl [OPTIONS]>

=over 8
All options:

build_moniter.pl          [-list of f]
						  [-build or b]
			              [-help or -h]

=back
=head2 DESCRIPTION

=head3 [-list]

File which contains list of builds. 

The path to which files will be soft linked from testcase directory.

=head3 [-build ]

Comma seperated builds passed as argument

=head1 EXAMPLES

1)

>build_moniter.pl -b 6180676,6180612

2)

>build_moniter.pl -f file_name