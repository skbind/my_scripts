#!/usr/cisco/bin/perl5.8 -w 

use warnings;
use strict;

use lib '/usr/cisco/packages/cisco-perllib';
use lib "/usr/cisco/packages/dbdoracle/9.2.0";
#use lib '/usr/cisco/packages/perl/perl-5.8.8/lib/5.8.8';
#use lib '/usr/cisco/packages/perl/perl-5.8.8/lib/site_perl/5.8.8/i686-linux-thread-multi';
#use lib '/usr/cisco/packages/perl/perl-5.8.8/lib/site_perl/5.8.8';
#use lib '/usr/cisco/packages/perl/perl-5.8.8/lib/site_perl';

=pod
use lib '/users/sabind/LOCAL_INSTALLS/my_perl/lib/5.22.0';
use lib '/users/sabind/LOCAL_INSTALLS/my_perl/external_libs/lib/site_perl/5.22.0';
use lib '/users/sabind/LOCAL_INSTALLS/my_perl/lib';
use lib '/users/sabind/LOCAL_INSTALLS/my_perl/lib/site_perl/5.22.0';
use lib '/users/sabind/LOCAL_INSTALLS/my_perl/external_libs/lib/5.22.0/x86_64-linux';
use lib '/usr/cisco/packages/perl/perl-5.8.8/lib/5.8.8/i686-linux-thread-multi/auto';
use lib '/usr/cisco/packages/perl/perl-5.8.8/lib/5.8.8/i686-linux-thread-multi';

=cut
#use Data::Dumper;
use Getopt::Long;
use DBI;
use Env;
#use Mailer;

$ENV{'ORACLE_HOME'} = '/usr/cisco/packages/dbdoracle/9.2.0';
my $data_source = 'dbi:Oracle:host=sjc-dbpl-bld.cisco.com;sid=PBAS;port=1521';
my $user = "IRE_CLIENT";
my $pass = "IRE_369";
my $db = DBI->connect($data_source, $user, $pass, { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;
chomp(my $usr = `whoami`);
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
	#print "BUILD:$build\n";
	foreach (split(',',$build)){
		$_ =~ s/^\s+|\s+$//;
		$#_ =~ s/\s+$//;
		chomp;
		print "||$_||\n";
		push @build_id,$_;
	}
}else{
	print "NO builds passed\n";
	print "Enter atleast one buildId to continue; Terminating! \n\n";
 	exit 1;
}

print "------------------------------------------\n\n";
my %result_set;
my $full_info ;

foreach my $id (@build_id) {
	my $query =  qq{select REQUEST_ID,REQUEST_DESC,REQUEST_TYPE,BUILD_SEQ_NUM,BUILD_SERVER,BUILD_DIR,LOGDIR,BRANCH_NAME,LABEL_NAME,NUM_IMAGE_LIST,NUM_IMAGE_LIST_BUILT,NUM_IMAGE_LIST_FAILED,START_TIME,END_TIME from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where FREEZE_TIME = ( select max(FREEZE_TIME) from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where REQUEST_ID = '$id')  and REQUEST_ID = '$id' and ROWNUM = 1 };
 	my $sth = $db->prepare($query) or die $DBI::errstr;
 	$sth->execute() or die $DBI::errstr;
	while( my $ref = $sth->fetchrow_hashref) {
    	$result_set{$ref->{REQUEST_ID}} = $ref;
    	$full_info = $ref;
    	
	}
}
#my $val = $result_set{'6444218'}->{REQUEST_DESC};
#print "\n VAL :: $val\n";
$db->disconnect();
=pod
foreach ( keys %result_set){
	  foreach ( keys %result_set){
	  $full_info{$_} = $result_set{$_};
}
=cut
#print Dumper(\%result_set);
print "------------------------------------------\n\n";
#print Dumper(\%$full_info);
print "------------------------------------------\n\n";



use MIME::Lite;
### Create a new single-part message, to send a GIF file:

my $msg = MIME::Lite->new(
    From    => 'sabind@cisco.com',
    To      => 'sabind@cisco.com',
    Subject => 'A message with 2 parts...',
    Type    => 'multipart/mixed'
);


my $data = <<HERE;

CBAS RESULT:

   Constraints          Requirements                Availability
   ===========          ============                ============
   Working Dir        Already created                  
   Space                   $full_info->{REQUEST_DESC}    
   Writable                YES                         
   DISPLAY(ENV)            SET                         
   INFRA_HOME(ENV)         SET                         
   IS ChiMe() UP?          UP                         
   Logged into p4p-vg01    YES   
   
HERE
  
$msg->attach(
    Type     => 'TEXT',
    Data     => "$data",
);

#$msg->send();

use Mailer;


mail( $usr, $usr, "my subj", \%$full_info, 'mail4.html.tt' );

sub mail {

    my ( $from, $to, $subject, $hash_ref, $template ) = @_;
    chomp( $from, $to, $subject, $hash_ref, $template );
	print "heelo from mail\n";

    my %params  = %{$hash_ref};
    my %options = ();
    $options{INCLUDE_PATH} = "/users/sabind/SCRIPTS/email_templates";

    my $msg = MIME::Lite::TT::HTML->new(
        From        => "$from\@cisco.com",
        To          => "$to\@cisco.com",
        Subject     => "$subject",
        TimeZone    => 'Asia/Shanghai',
        Encoding    => 'quoted-printable',
        Template    => { html => "$template", },
        Charset     => 'utf8',
        TmplOptions => \%options,
        TmplParams  => \%params,
    );

    $msg->send();
    
}



