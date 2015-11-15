#!/usr/cisco/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use DateTime;
use DBI;
use Env;
use lib "/usr/cisco/packages/dbdoracle/9.2.0";

$ENV{'ORACLE_HOME'} = '/usr/cisco/packages/dbdoracle/9.2.0';

my $noupdate = $ENV{'NO_UPDATE'} ;

my $data_source = 'dbi:Oracle:host=sjc-dbpl-bld.cisco.com;sid=PBAS;port=1521';
my $user = "IRE_CLIENT";
my $pass = "IRE_369";
my $db = DBI->connect($data_source, $user, $pass, { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;

my $dsn = 'DBI:SQLite:dbname=/users/sabind/CBAS_DB/cbas_build';
my $dbh_sqlite = DBI->connect( $dsn, "", "", { RaiseError => 1, AutoCommit => 1 } ) or die $!;

my ($list,$build,$help_msg,$no_mail);


use lib '/usr/cisco/packages/cisco-perllib';
use lib '/users/sabind/EXTERNAL_LIBS/perl_libs';
use lib '/users/sabind/EXTERNAL_LIBS/perl_libs/lib/site_perl/5.8.8';
use MIME::Lite;

GetOptions(
    "list|f:s" 	    => \$list,
    "help|h"        => \$help_msg,
    "build|b:s"     => \$build,
    "no-mail|nm"    => \$no_mail,
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

foreach my $id (@build_id) {
	my $query =  qq{select REQUEST_ID,REQUEST_DESC,REQUEST_TYPE,START_TIME,BUILD_SEQ_NUM,BUILD_SERVER,BUILD_DIR,LOGDIR,BRANCH_NAME,LABEL_NAME,NUM_IMAGE_LIST,NUM_IMAGE_LIST_BUILT,NUM_IMAGE_LIST_FAILED,END_TIME from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where BUILD_SEQ_NUM = ( select max(BUILD_SEQ_NUM) from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where REQUEST_ID = '$id')  and REQUEST_ID = '$id' and ROWNUM = 1 };
 	my $sth = $db->prepare($query) or die $DBI::errstr;
 	$sth->execute() or die $DBI::errstr;
	while( my $ref = $sth->fetchrow_hashref) {
		#my $key = $id.' [ '.$ref->{BRANCH_NAME}.' : '.$ref->{REQUEST_TYPE}.' ]';
		my $key = $id;
    	$result_set{$key} = $ref;
    	$result_set{$key}->{'PARTTION'} = &_get_partion($id);
    	#$result_set{$key}->{LAST_FINISHED} = &_last_run($ref->{END_TIME});
    	my $run_status;
    	if (defined $ref->{END_TIME}){
    		 $run_status = &_last_run($ref->{END_TIME}) if (defined $ref->{END_TIME});
    	}else{
    		 $run_status = &_last_run($ref->{START_TIME}) if (defined $ref->{START_TIME});
    	}
    	
    	my $status;
    	if ( defined $ref->{END_TIME} && ($ref->{NUM_IMAGE_LIST} eq $ref->{NUM_IMAGE_LIST_BUILT}) ){
    		$status = 'green:Sucessfully Completed !!:'.$ref->{NUM_IMAGE_LIST}.':'.$ref->{NUM_IMAGE_LIST_BUILT}.':'.$ref->{NUM_IMAGE_LIST_FAILED}.': ( Last Run >> '.$run_status.' )';
    	}elsif($ref->{NUM_IMAGE_LIST_FAILED} eq '0'  && ( ! defined  $ref->{END_TIME})){
    		$status = 'green:Sucessfully Running...:'.$ref->{NUM_IMAGE_LIST}.':'.$ref->{NUM_IMAGE_LIST_BUILT}.':'.$ref->{NUM_IMAGE_LIST_FAILED}.': ( Running Since >> '.$run_status.' )' ;
    	}elsif( $ref->{NUM_IMAGE_LIST_FAILED} ne '0'  && ( ! defined $ref->{END_TIME})){
    		$status = 'red:Failed !! Running...:'.$ref->{NUM_IMAGE_LIST}.':'.$ref->{NUM_IMAGE_LIST_BUILT}.':'.$ref->{NUM_IMAGE_LIST_FAILED}.':  ( Running Since >> '.$run_status.' )';
    	}elsif( $ref->{NUM_IMAGE_LIST_FAILED} ne '0' && ( defined $ref->{END_TIME})){
    		$status = 'red:Failed !! Run Completed.:'.$ref->{NUM_IMAGE_LIST}.':'.$ref->{NUM_IMAGE_LIST_BUILT}.':'.$ref->{NUM_IMAGE_LIST_FAILED}.':  ( Last Run >> '.$run_status.' )';
    	}else{
    		$status = 'red:Unknown:Status:PleaseCheck:!';
    	}    	
    	 #print "STATUS = $status\n";
    	 $result_set{$key}->{STATUS} = $status;
    	 delete $result_set{$key}->{REQUEST_ID} if exists ($result_set{$key}->{REQUEST_ID});
	}
}

sub _last_run{
	my ($end_time) = @_;
	my $time = $&  if ($end_time =~ /PM|AM/);
    my $last_finish  = substr $end_time, 0, 15;
    $last_finish .= ' '.$time;
    return $last_finish || 'NOT FOUND';
}


sub _get_partion{
	my ($build_id) = @_;
	chomp(my $patition = `cat /users/sabind/SCRIPTS/GIT_REPO/cbas_build_list | grep $build_id | cut -d ':' -f7`);
	$patition =~ s/\s+//;
	return $patition || 'NULL';
}
#print Dumper(\%result_set);

sub _get_date_time{
	my $scalar_date = scalar localtime(time);
	my @day = split(' ',$scalar_date);
	my $dt = DateTime->now(time_zone => 'local');
	my $date = $dt->strftime("%Y-%m-%d");
	return $day[3]
}

sub _dump_to_sqlite_db{
	my $date_time = _get_date_time();
	#print "\n Inside dump_to_sqlite  date_time = $date_time\n";
	foreach my $b_id (keys %result_set){
		my $value =  $result_set{$b_id}{LABEL_NAME};
		#my $sql_insert = qq{ INSERT INTO RUN_HIST VALUES (1, date('now'), '$date_time', '1', '$value','log1','build_log', 'test',100,50,1)};
			#$result_set{$b_id}{NUM_IMAGE_LIST_FAILED} = 1;
			my $sql_insert = qq{ INSERT  INTO RUN_HIST(ID,RUN_TIME,DATE,SEQ,LABEL_NAME,LOGDIR,BUILD_LOG,DESC,TOTAL_IMAGE,BUILT_IMAGE,FAILED_IMAGE) VALUES ($b_id, date('now'), '$date_time', 1, '$result_set{$b_id}{LABEL_NAME}','$result_set{$b_id}{LOGDIR}','$result_set{$b_id}{BUILD_DIR}', '$result_set{$b_id}{REQUEST_DESC}','$result_set{$b_id}{NUM_IMAGE_LIST}','$result_set{$b_id}{NUM_IMAGE_LIST_BUILT}','$result_set{$b_id}{NUM_IMAGE_LIST_FAILED}')};
			my $sth_insert = $dbh_sqlite->prepare($sql_insert);
			$sth_insert->execute();
			$sth_insert->finish() or die $DBI::errstr;
			unless ($result_set{$b_id}{NUM_IMAGE_LIST_FAILED}){
				 delete $result_set{$b_id};
			}else{
				 delete $result_set{$b_id}->{NUM_IMAGE_LIST_BUILT} if exists ($result_set{$b_id}->{NUM_IMAGE_LIST_BUILT});
		    	 delete $result_set{$b_id}->{NUM_IMAGE_LIST} if exists ($result_set{$b_id}->{NUM_IMAGE_LIST});
		    	 delete $result_set{$b_id}->{NUM_IMAGE_LIST_FAILED} if exists ($result_set{$b_id}->{NUM_IMAGE_LIST_FAILED});
		    	 delete $result_set{$b_id}->{BRANCH_NAME} if exists ($result_set{$b_id}->{BRANCH_NAME});
		    	 delete $result_set{$b_id}->{REQUEST_TYPE} if exists ($result_set{$b_id}->{REQUEST_TYPE});
		    	 delete $result_set{$b_id}->{END_TIME} if exists ($result_set{$b_id}->{END_TIME});
		    	 delete $result_set{$b_id}->{START_TIME} if exists ($result_set{$b_id}->{START_TIME});
			}
			
	}
}


&_dump_to_sqlite_db() unless($noupdate);
$db->disconnect();
print "-------------------END-----------------------\n\n";

#print Dumper(\%result_set);


if(%result_set){
	#print "hash present\n";
	&_genrate_data();
}

print "-------------------END-----------------------\n\n";
#=====================================================================================

sub _genrate_data{
	my $count = 0;
	my	$data = '<table cellpadding="1" cellspacing="1" border="1" width="70%">';
	foreach my $build_id (keys %result_set) {
		#$data .= '<tr style="font-size:15px;font-family:Sans-serif;background-color:#585858;"><td><strong style="font-size:15px;color:white;">&nbsp&nbspREQUEST ID <td><strong style="font-size:15px;color:white;">&nbsp&nbsp'.$build_id."\n";
		$count++;
		$data .= '<tr style="font-size:15px;background-color:#585858;"><td><strong style="font-size:15px;color:white;">&nbsp('.$count.'.)&nbspREQUEST ID <td><strong style="font-size:15px;color:white;">&nbsp&nbsp'.$build_id."\n";
	    #while (my ($key, $value) = each %{ $result_set{$build_id} } ) {
	   	foreach my $header ( sort {$b cmp $a} keys %{ $result_set{$build_id} } ) {
	   		my $value =  $result_set{$build_id}{$header} || 'NOT FOUND';
	        if($header eq 'STATUS'){
	        	my @data = split(':',$value);
	        	if($data[0] eq 'red'){
	        		$data .=  '<tr style="font-size:14px;background-color:#FFCC66;"><td><strong style="color:#151B8D";>&nbsp&nbsp'.$header .'<td><strong style="color:#CC0000;">&nbsp&nbsp'.$data[1].' Total Images: '.$data[2].', Built: '.$data[3].', Failed: '.$data[4].'&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.$data[5]."\n";
	        	}else{
	        		$data .=  '<tr style="font-size:14px;background-color:#FFCC66;"><td><strong style="color:#151B8D";>&nbsp&nbsp'.$header .'<td><strong style="color:#005C00;">&nbsp&nbsp'.$data[1].' Total Images: '.$data[2].', Built: '.$data[3].', Failed: '.$data[4].'&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp'.$data[5]."\n";	
	        	}
	        	next;
	        }
	                $data .=  '<tr strong style="font-size:12px;background-color:#F2F2F2"><td><strong>&nbsp&nbsp'.$header .'<td font-size:10px>&nbsp&nbsp'.$value."\n";
	    }
	}
	&mail( 'sabind', 'sabind', "CBAS Progress Report",$data ) unless($no_mail);
}

sub mail{

    my ( $from, $to, $subject,$HTML_data) = @_;
    chomp( $from, $to, $subject);

my $msg = MIME::Lite->new(
		 From    =>"$from\@cisco.com",
         To      =>"$to\@cisco.com",
         Subject =>"$subject",
         Type    =>'multipart/related'
    );
    $msg->attach(
        Type => 'text/html',
        Data => qq{
            		<body>
                	<strong>Hi $to</strong>,
					<p><p>
						This is the progress report of CBAS builds.
					<p><p><p><p><p>
					<strong><font color="#151B8D">Details:</font></strong>
					<br>
					$HTML_data
					</table>
					<br>
					<p><p><p><p>
 
					<strong><font color="#151B8D"> Thank You !!!</font></strong>
					<br>
					<br>
            </body>
        },
    );

    $msg->send();

}
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
