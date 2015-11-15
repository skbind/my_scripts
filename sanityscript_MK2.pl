#!/usr/cisco/bin/perl
 
# Copyright (c) 2012-2013 by cisco Systems, Inc.
# All rights reserved.
 
# ===========================================================================
# 
# 	==> This script is used to submit the images to Basic Sanities for CBAS Builds 
# 	==> Copy the kitchen sink images to the Extended archive location.
# 	==> The Script will be run as a postprocess task for CBAS builds.
# 	==> Email will be sent to isbuweb 
#		if the sanities failed to submit OR
# 		If it fails to copy the Images to Extended archive location.
# ===========================================================================
# Created March 2013, Supraja Muppala

use strict;
use warnings;
use Switch;
use Getopt::Long;
use Mail::Sendmail;
use File::Basename;

sub executeTest;
sub checkSubmissionStatus;
sub scanTestLog;
sub copyToExtendedArchive;
sub usage;

my $DEBUG=0;
my ($opt_cfg, $logdir, $action, $opt_help,$opt_testing);
my ($branchtag,$key,$val, %grep_table, %imagelist, $branch_name, $Date, @subdirs, $buildmaster,  $archive_dir, $builddir, $version, $rtag, $archdir, $test_subject, $test_msgbody, $sesarchivedir,  $seslogdir);

#below variables are defined in the sanitydatafile.$branch file
our ( $branch_notification, $c2k_notification, %imagelist, @extarchiveimagelist, $extendedarchivedir, $error_email_to, $email_from, $sesbuildfile, $sesbuildmail );


#check the input arguments
if ( not scalar @ARGV) {&usage(1)};
GetOptions (    "cfg=s"         => \$opt_cfg, 
		"ldir=s"	=> \$logdir,
		"action:s"	=> \$action,
		"t|test"	=> \$opt_testing,,
                "h|help"        => \$opt_help 
           ) or &usage(1); 
if($opt_help){
	usage(0);
}

# only two arguments passed with this script.
#-cfg /users/integ/build_scripts/datafile_MK2.sanity # datafile to read.
# -ldir $RT_LOGDIR 


my $script_name=`basename $0`;
chomp $script_name;
#check if the sanity datafile is specified in the argument
if( not $opt_cfg){
	my $msgbody="ERROR: Specify the datafile.\$branch config file using -cfg option";
	print "$msgbody\n";
	my $subject="$script_name: Datafile missing while Invoking the Sanity Submission script";
	if (not $opt_testing) { send_mail($subject,$msgbody) } ;
	exit(1);
}	
#check if the sanity datafile exists
if( ! -f $opt_cfg){
	my $msgbody="ERROR: $opt_cfg datafile file does not exist";
	print "$msgbody\n";
	my $subject="$script_name: Datafile doesn't exist in the specified directory";
	if (not $opt_testing) { send_mail($subject,$msgbody) } ;
	exit(1);
}
#check if the logdir is specified as input arugment
if( not $logdir){
        my $msgbody="ERROR: Specify the logdir using -ldir option";
        print "$msgbody\n";
        my $subject="$script_name: Logdir is missing while Invoking the Sanity Submission script";
	if (not $opt_testing) { send_mail($subject,$msgbody) } ;
        exit(1);
}
#check if the logdir exists
if( ! -d $logdir){
        my $msgbody="ERROR: $logdir logdir does not exist";
        print "$msgbody\n";
        my $subject="$script_name: Logdir doesn't exist";
	if (not $opt_testing) { send_mail($subject,$msgbody) } ;
        exit(1);
}
#if optional arugment $action is not specified then all the functionalities are enabled using "all"
if( not $action){
	$action = "all";
	print "\$action is set to $action\n";
}

#
# Note the external datafile is called in here
#
require $opt_cfg;


#
#lets get the required variables from the $RT_LOGDIR/user_env.log
#
# this is a STATIC file should be present in all CBAS build log directories
my $userenv_log = "user_env.log";
$Date=`date +%y%m%d`; 
chomp $Date;
print $Date;
print "extended archive location is $extendedarchivedir\n";
chomp $extendedarchivedir;
print "logdir is $logdir\n";
$branchtag=`grep -w "RT_BRANCH_NAME" $logdir/$userenv_log|awk -F \= '{print \$2}'`;
chomp $branchtag;
print "Branch Name: $branchtag\n";
$archive_dir=`grep -w "RT_ARCHIVE_DIR_BIN" $logdir/$userenv_log|awk -F \= '{print \$2}'`;
chomp $archive_dir;
$version=`grep -w "RT_VERSION_ID" $logdir/$userenv_log|awk -F \= '{print \$2}'`;
chomp $version;
$rtag=basename($archive_dir);
chomp $rtag;
print "rtag is $rtag\n";
$archdir=`grep -w "RT_ARCHIVE_DIR" $logdir/$userenv_log|awk -F \= '{print \$2}'`;
chomp($archdir);
$builddir=`grep -w "RT_BUILD_DIR" $logdir/build_env.log|awk -F \= '{print \$2}'`;
print "Build Directory is $builddir\n";
chomp($builddir);
$test_subject="$Date $branchtag Sanity Test Submission(s) failed for below images";
#====================== MAIN STARTS ======================================================
switch($action){
	case "sanity"{
			sanitySubmission();
	}
	case "extarchive"{
			checkExtendedArchive();
			copyToExtendedArchive();
	}
	case "c2kversion"{
			getc2kVersion();				
	}
	case "buildsesut"{
			buildsesimages();				
	}
	case "changePerm"{
			changePerm();
	}
	case "all"{
			sanitySubmission();
			checkExtendedArchive();
			copyToExtendedArchive();
			changePerm();
			getc2kVersion();				
	}
	else{
			print "Invalid action $action selected\n";
	}
}
#====================== MAIN ENDS ======================================================

sub sanitySubmission{
    if( -e "$logdir/testsubmission.log" ){
        print "$logdir/testsubmission.log file exists\n";
    }
    else{
        system("touch $logdir/testsubmission.log");
    }
    foreach my $key ( keys %imagelist ){
	if( !-e "$archive_dir/$key.$rtag" ){
		print "$key image doesn't exist Will contibue withe next image\n";
		next;
	}
	print "sanities needed for the image $key are:\n ";
	foreach ( @{$imagelist{$key}} ) {
        	push(my @sanity_test,$_);
        	for ( my $i=0;$i<=$#sanity_test;$i++){
               		switch($sanity_test[$i]){
                        	 #print "$sanity_test[$i]\n";
				 #my sanitytest=$sanity_test[$i]; 	
                      		 case "basic-sanity"{
                                                        my $h_option="0";
                                                        executeTest($h_option,$key,"basic-sanity");
                                 	            }
                         	 case "basic-sanity-ha"{
                                                        my $h_option="1";
                                                        executeTest($h_option,$key,"basic-sanity-ha");
                       		                       }
                         	 case "basic-sanity-quad-sup"{
                                                        my $h_option="quad-sup";
                                                        executeTest($h_option,$key,"basic-sanity-quad-sup");
                                                     }
                        	 case "basic-sanity-quad-sso"{
                                                        my $h_option="quad-sso";
                                                        executeTest($h_option,$key,"basic-sanity-quad-sso");
                                                     }
                        	 case "basic-sanity-vsl"{
                                                        my $h_option="vsl";
                                                        executeTest($h_option,$key,"basic-sanity-vsl");
                                	               }
                     		 case "basic-sanity-fex"{
                                                        my $h_option="fex_combo";
                                                        executeTest($h_option,$key,"basic-sanity-fex");
                                 	              }
                     		 case "basic-sanity-napper"{
                                                        my $h_option="nappar";
                                                        executeTest($h_option,$key,"basic-sanity-napper");
                                 	              }
                        	 else{
                                                        print "Invalid sanitytest option submitted \n";
                            	 }
               	      }
                }
      	        pop(@sanity_test);
                print "\n====================================================\n"; 
        }
    }
    #if any of the above test submissions failed they are captured in the checkSubmissionStatus
    # $test_msgbody gets values in checkSubmissionStatus
    if(defined $test_msgbody){
   	 send_mail($test_subject,$test_msgbody);	
    }	
}
#================================================================================================================================================================
sub executeTest{
	my $h_option=shift;
	my $image=shift;
	my $test=shift;
	print "test submitted = $test\n";
	my $test_cmd="/auto/hss-native/basic-sanity.pl -i $archive_dir/$image.$rtag -b $branchtag -r $branch_notification -d nightly -H $h_option";
	`echo $test_cmd >> $logdir/testsubmission.log`;
	print "Following Test Command Submitted ....................\n $test_cmd\n";
	my $submit_test=`/auto/hss-native/basic-sanity.pl -i $archive_dir/$image.$rtag -b $branchtag -r $branch_notification -d nightly -H $h_option 2>&1`;
	print "value of submit_test in ExecuteTest $submit_test\n";
	if(grep(/Already/i,$submit_test)){
		print "Test got submitted already \n";
	}
	else{
	  	open FH, ">> $logdir/testsubmission.log";	
		foreach(split(/\n/,$submit_test)){
			print FH $_."\n";
		}
	}
	close FH;
        checkSubmissionStatus($image,$test,$submit_test);
	scanTestLog();
}
#====================================================================================================================================
sub checkSubmissionStatus{
	my $image=shift;
	my $test=shift;
	my $submit_test=shift;
	my @submissionfaillist;
	if((grep(/EARMS ID/,$submit_test))||(grep(/Earms ID/,$submit_test))){
		print  "$Date $image $test test Submission IS SUCCESSFUL\n";
	}
        else{
		my $failed_img_test="$test sanity submission failed for $image\n";
                push(@submissionfaillist,$failed_img_test);
		push(@submissionfaillist,$submit_test);
                foreach my $img(@submissionfaillist){
                	$test_msgbody="\n$test_msgbody$img\n";
                }
	}
}
#=====================================================================================================================================
sub scanTestLog{
	#my $cmd = "/ws/isbb/mk1_pi/scripts/scan_log.pl $logdir/testsubmission.log > $logdir/testscan.$Date.log";
	my $cmd = "/auto/elb_build/autobuild/background_builds/common/scan_log.pl $logdir/testsubmission.log > $logdir/testscan.$Date.log";
	print "$cmd\n";
	system($cmd);
}
#=====================================================================================================================================
sub copyToExtendedArchive{
	checkDiskSpace();
	my @cpfailarray;
	my $subject;
	my $msgbody="";
        my @subdir=("bin","sun","sym");
	my $dir;
	foreach $dir (@subdir){
		print "==========================================================\n";
		chomp $dir;
		my $exarchive="${extendedarchivedir}/${dir}";
		print "\nextended archive is $exarchive\n";
		chdir $exarchive;
		if( -d $rtag ){
			print "directory exists";
		}
		else{
		        print "Creating $rtag directory in extended archive area\n";
                        `mkdir $rtag`;
		}	 
		my $arch_dir="$archdir/$dir/$rtag";
		print "$arch_dir\n";
	        foreach my $image (@extarchiveimagelist){
			chdir $arch_dir;
			my @act_image=`ls|grep $image`;
			my @chk_image=`ls|grep $image 2>&1 1>/dev/null`;
			if($? != 0 ){
				push(@cpfailarray,$image);
				$subject="$Date $branchtag Following Image(s) doesn't exist in archive location";
			} 
			else{ 
				chomp(@act_image);
				print "act_image is @act_image\n" if $DEBUG; 
				foreach my $img (@act_image){
					if( -e "$img" ){
						my $cmd="cp -p $img $exarchive/$rtag";
						my $status=`$cmd 2>&1 1>/dev/null`;
						print "status: $status" if $DEBUG;
						if( $? == 0 ){
							print "$cmd ... SUCCESS\n";
						}
						else{
							print "$cmd  ... FAILED\n";
							my $var="$img failed to copy to $exarchive";
							push(@cpfailarray,$var);
							push(@cpfailarray,$status);
							$subject="$Date $branchtag Following Images Failed to copy to Extended archive";
						}		
						
					}
					else{
						print "$img doesn't exist in archive location\n";
					}
				}
			}
		}
	}
	foreach my $img(@cpfailarray){
		$msgbody="$msgbody$img\n";
	}
	if(defined $msgbody){
		send_mail($subject,$msgbody);
	}
}
sub checkExtendedArchive {
	if( ! -d $extendedarchivedir){
		my $msgbody="ERROR: $extendedarchivedir Extended archive directory does not exist";
       		print "$msgbody\n";
      		my $subject="Extended Archive Directory doesn't exist";
		if (not $opt_testing) { send_mail($subject,$msgbody) } ;
		exit(1);
	}
}
#======================== checking for disk space for extended archive ==================
sub checkDiskSpace{
	my $space=`df -h $extendedarchivedir`;
	my @used=split(/ /,$space);
	print "used space is  $used[46]\n";
	my $used_space=substr($used[46],0,2);
	if ($used_space >= 90){	
                my $subject="$Date $branchtag";
		my $msgbody="$extendedarchivedir is $used[46] full. Please Cleanup the archive";
		send_mail($subject,$msgbody);
	}
}
sub getc2kVersion{
	my $c2kimage=`grep "c6800ia" "$builddir/sys/const/native-si/fex_version_mgmt.c"|awk -F , '{print $1}'`;
	#my $c2kimage2=`grep "c2960x" "$builddir/sys/const/native-si/fex_version_mgmt.c"|awk -F , '{print $1}'`;
	my $c2kimage3=`grep "c3560cx" "$builddir/sys/const/native-si/fex_version_mgmt.c"|awk -F , '{print $1}'`;
        my $subject="$Date $branchtag $rtag c2kimage bundled version"; 
	##my $msgbody="C2K image bundled into this build is : $c2kimage $c2kimage2 $c2kimage3";
	my $msgbody="C2K image bundled into this build:\n $c2kimage $c2kimage3";
        send_mail($subject,$msgbody,$c2k_notification); 
}
#=========================================================================================
sub send_mail{
	my $subject=shift;
	my $msgbody=shift;		
	my $email_to=shift;
	if(!defined($error_email_to)){
		$error_email_to="smuppala\@cisco.com";
	}
	$error_email_to=$email_to;
	if(!defined($email_from)){
		$email_from="integ\@cisco.com";
	}
	my %mail = (   To      =>  "$error_email_to",
	               From    =>  "$email_from",
		       Subject =>  "$subject",	
	               Message =>  "$msgbody"
	            );

	sendmail(%mail) or warn $Mail::Sendmail::error;
	#lets comments this for now
	#print "\nOK. Log says:\n", $Mail::Sendmail::log;
}
#=========================================================================================
sub usage{
	my $exit_value = shift;
        print "\nUsage: $0 --cfg < datafile.branch > -ldir < RT_LOGDIR >
                --action [ sanity  | extarchive ] \n\n";
        print " -action : optional: either sanity, extarchive  \n";
        print "         : if nothing is specified then it does everything \n"; 
        print " -ldir current build log directory name\n";
        print " -cfg  sanity datafile\n";
        print " -h|?|help prints this usage\n\n";
	exit $exit_value;
}
sub buildsesimages{
	print "Entering postbuild process to build sessut images\n";
        $sesarchivedir="$archive_dir/SESUT";
	$seslogdir="$logdir/SESUT";
	if( -d $seslogdir ){
                print "$seslogdir directory exists\n";
        }
        else{
        	print "Creating $seslogdir directory in log directory\n";
                `mkdir $seslogdir`;
        }
        if( -d $sesarchivedir ){
		print "$sesarchivedir Directory Exists\n";	
	}
	else{
        	print "Creating $seslogdir directory in log directory\n";
        	`mkdir $sesarchivedir`;
	}
	my $bld_dir="$builddir/sys";
	chdir $bld_dir;
	print "pwd is: $bld_dir\n";
        print  "seslogdir is set to:  $seslogdir\n";
        print "Run sesutnb";
        my $cmd="/auto/ses/bin/sesutnb -imagefile $sesbuildfile -logdir $seslogdir -imagedir $sesarchivedir -nightly -mailto $sesbuildmail";
        my $status=`$cmd 2>&1 1>/dev/null`;
        print "status: $status" if $DEBUG;
        if( $? == 0 ){
        	print "$cmd ... SUCCESS\n";
        }
        else{
        	print "$cmd  ... FAILED\n";
                #push(@cpfailarray,$status);
                my $subject="$Date $branchtag sesut build failed";
		send_mail($subject,$status);
        }
}
sub changePerm{
	my $arc_dir="$archive_dir/.3DES";
	print "arc_dir is $arc_dir\n";
	chdir $arc_dir or die "cann't change directory";
	`chmod 755 "c6880x-adventerprisek9_dbg-mz.SSA.$rtag"`; 
	print "Changing the permission of the Terminator image \n";
	if($? == 0){
		print "successfully changed the permissions\n";
	}
}
