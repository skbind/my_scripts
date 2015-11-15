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


use lib '/usr/cisco/packages/cisco-perllib';
use lib '/users/sabind/EXTERNAL_LIBS/perl_libs';
use lib '/users/sabind/EXTERNAL_LIBS/perl_libs/lib/site_perl/5.8.8';
use MIME::Lite::TT::HTML;

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
		next if ($_ =~ /^#/ || /^\s+/);
		$_ =~ s/\s+::.*$//;
		chomp;
		#print "||$_||\n";
 		push @build_id,$_;
	}
	close(FH);
}elsif($build){
	#print "BUILD:$build\n";
	foreach (split(',',$build)){
		$_ =~ s/^\s+|\s+$//;
		$_ =~ s/\s+$//;
		chomp;
		push @build_id,$_;
	}
}else{
	print "NO builds passed\n";
	print "Enter atleast one buildId to continue; Terminating! \n\n";
 	exit 1;
}
print "------------------------------------------\n\n";
#die;
my %result_set;
my $full_info ;
foreach my $id (@build_id) {
	my $query =  qq{select REQUEST_ID,REQUEST_DESC,REQUEST_TYPE,BUILD_SEQ_NUM,BUILD_SERVER,BUILD_DIR,LOGDIR,BRANCH_NAME,LABEL_NAME,NUM_IMAGE_LIST,NUM_IMAGE_LIST_BUILT,NUM_IMAGE_LIST_FAILED,START_TIME,END_TIME from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where BUILD_SEQ_NUM = ( select max(BUILD_SEQ_NUM) from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where REQUEST_ID = '$id')  and REQUEST_ID = '$id' and ROWNUM = 1 };
 	my $sth = $db->prepare($query) or die $DBI::errstr;
 	$sth->execute() or die $DBI::errstr;
	while( my $ref = $sth->fetchrow_hashref) {
    	$result_set{$ref->{REQUEST_ID}} = $ref;
    	$full_info = $ref;
    	$result_set{$id}->{'PARTTION'} = &_get_partion($id);
	}
}
#my $val = $result_set{'6444218'}->{REQUEST_DESC};
#print "\n VAL :: $val\n";
print Dumper(\%result_set);
$db->disconnect();
print "------------------------------------------\n\n";

my %hash_ref;

#&mail( 'sabind', 'sabind', "CBAS Progess Report" );

sub _get_partion{
	my ($build_id) = @_;
	chomp(my $patition = `cat /users/sabind/SCRIPTS/cbas_build_list | grep $build_id | cut -d ':' -f7`);
	$patition =~ s/\s+//;
	return $patition || 'NULL';
}

sub mail {

    my ( $from, $to, $subject) = @_;
    chomp( $from, $to, $subject);
    my %options = ();
    $options{INCLUDE_PATH} = "/users/sabind/SCRIPTS/email_templates";

    my $msg = MIME::Lite::TT::HTML->new(
        From        => "$from\@cisco.com",
        To          => "$to\@cisco.com",
        Subject     => "$subject",
        TimeZone    => 'Asia/Shanghai',
        Encoding    => 'quoted-printable',
        Template    => { html => "mail4.html.tt", },
        Charset     => 'utf8',
        TmplOptions => \%options,
        TmplParams  => \%$full_info,
    );

    $msg->send();

}

%hash_ref = (
                         'REQUEST_DESC' => '(6180676) v155_1_t_throttle NIGHTLY Build',
                         'END_TIME' => undef,
                         'BUILD_SEQ_NUM' => '117',
                         'START_TIME' => '15-JUN-15 03.21.00.000000 AM -07:00',
                         'NUM_IMAGE_LIST_BUILT' => '21',
                         'BUILD_DIR' => '/san2/CPY-v155_1_t_throttle.NIGHTLY_V155_1_T_THROTTLE-20150615_0321-117/vob/ios',
                         'BUILD_SERVER' => 'build-lnx-056',
                         'REQUEST_ID' => '6180676',
                         'LABEL_NAME' => 'NIGHTLY_V155_1_T_THROTTLE_201506150321',
                         'LOGDIR' => '/auto/beyond.build3/155t/logs/v155_1_t_throttle_Nightly//2015-06-15',
                         'REQUEST_TYPE' => 'NIGHTLY',
                         'BRANCH_NAME' => 'v155_1_t_throttle',
                         'NUM_IMAGE_LIST' => '69',
                         'NUM_IMAGE_LIST_FAILED' => '0'
          
        );

#=========================================================





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
