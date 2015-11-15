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
use List::MoreUtils qw{ all };

sub executeTest;
sub checkSubmissionStatus;
sub scanTestLog;
sub copyToExtendedArchive;
sub usage;

my $DEBUG=0;
my ($opt_cfg, $logdir, $bundleLog, $action, $opt_help,$opt_testing, @actions);
my ($branchtag, $key, $val, $FH, $basedir, %grep_table, %imagelist, $img_file, $branch_name, $Date, $buildmaster,  $archive_dir, $builddir, $version, $rtag, $archdir, $test_subject, $test_msgbody, @sanity_image, $submit_test, $test_cmd, @submitimages, $sesarchivedir,  $seslogdir, @submited_imgs);

#below variables are defined in the datafile.$branch file
our ( $branch_notification, $buildtype, $c2k_notification, %imagelist, @extarchiveimagelist, $extendedarchivedir, $error_email_to, $email_from, @sanityimages,$sesbuildfile, $sesbuildmail, $img, $img2, $ver_mgmt_file, $file_path);

$action="all";

#check the input arguments
if ( not scalar @ARGV) {&usage(1)};
GetOptions (    "cfg=s"         => \$opt_cfg, 
		"ldir=s"	=> \$logdir,
		"v=s"           => \$version,
		"bindir=s"      => \$archive_dir,
		"b=s"           => \$branchtag, 
		"bldir=s"	=> \$builddir,
		"action:s"	=> \$action,
		"blog:s"        => \$bundleLog,
		"t|test"	=> \$opt_testing,
                "h|help"        => \$opt_help 
           ) or &usage(1); 
if($opt_help){
	usage(0);
}
@actions=split(/[, :]/,$action);
#foreach my $act(@actions){ print "actions specified are $act\n"};
my $script_name=basename($0);
chomp $script_name;
print "script name is: $script_name\n";
#check if the sanity datafile is specified in the argument
if( not $opt_cfg){
	my $msgbody="ERROR: Specify the datafile.\$branch config file using -cfg option";
	print "$msgbody\n";
	my $subject="$script_name: Datafile missing while Invoking the Sanity Submission script";
	if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
	exit(1);
}	
#check if the sanity datafile exists
if( ! -f $opt_cfg){
	my $msgbody="ERROR: $opt_cfg datafile file does not exist";
	print "$msgbody\n";
	my $subject="$script_name: Datafile doesn't exist in the specified directory";
	if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
	exit(1);
}
#check if the version is specified as input argument
if( not $version){
        my $msgbody="ERROR: Specify the version using -v option";
        print "$msgbody\n";
        my $subject="$script_name: version is missing while Invoking the Sanity Submission script";
        if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
        exit(1);
}
#check if the archive bin directory is specified as input arugment
if( not $archive_dir){
        my $msgbody="ERROR: Specify the archive bin directory using -bindir option";
        print "$msgbody\n";
        my $subject="$script_name: archive bindir is missing while Invoking the Sanity Submission script";
        if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
        exit(1);
}
#check if the archive_dir exists
if( ! -d $archive_dir){
        my $msgbody="ERROR: $archive_dir archive directory does not exist";
        print "$msgbody\n";
        my $subject="$script_name: archive_dir doesn't exist";
        if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
        exit(1);
}
#check if the branchtag is specified as input arugment
if( not $branchtag){
        my $msgbody="ERROR: Specify the branchtag using -b option";
        print "$msgbody\n";
        my $subject="$script_name: branchtag is missing while Invoking the Sanity Submission script";
        if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
        exit(1);
}
#check if the builddir is specified as input arugment
if( not $builddir){
        my $msgbody="ERROR: Specify the builddir using -bldir option";
        print "$msgbody\n";
        my $subject="$script_name: blddir is missing while Invoking the Sanity Submission script";
        if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
        exit(1);
}
#check if the builddir exists
if( ! -d $builddir){
        my $msgbody="ERROR: $builddir builddir does not exist";
        print "$msgbody\n";
        my $subject="$script_name: builddir doesn't exist";
        if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
        exit(1);
}
#check if the logdir is specified as input arugment
if( not $logdir){
        my $msgbody="ERROR: Specify the logdir using -ldir option";
        print "$msgbody\n";
        my $subject="$script_name: Logdir is missing while Invoking the Sanity Submission script";
	if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
        exit(1);
}
#check if the logdir exists
if( ! -d $logdir){
        my $msgbody="ERROR: $logdir logdir does not exist";
        print "$msgbody\n";
        my $subject="$script_name: Logdir doesn't exist";
	if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
        exit(1);
}

#check if the bundle script log file is specified as input arugment
if( not $bundleLog){
        my $msgbody="WARNING: Bundle script log file name (-blog) is missing from the input arguments";
        print "$msgbody\n";

        #Only a warning - no need to send email for this nor exit!
        #my $subject="$script_name: Bundle script log file name is missing";
        #if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
        #exit(1);
}


#
# Note the external datafile is called in here
#
require $opt_cfg;

# this is a STATIC file should be present in all CBAS build log directories
$Date=`date +%y%m%d`; 
chomp $Date;
#print $Date;
print "extended archive location is: $extendedarchivedir\n";
chomp $extendedarchivedir;
print "logdir is: $logdir\n";
print "Branch Name: $branchtag\n";
print "archive dir is: $archive_dir\n";
print "version is: $version\n";
$rtag=basename($archive_dir);
$basedir=dirname($archive_dir);
$archdir=dirname($basedir);
#chomp $rtag;
print "rtag is: $rtag\n";
print "archdir is: $archdir\n";
$img_file="$logdir/submitedImgs.log";
if(!-e $img_file){
	system("touch $logdir/submitedImgs.log");
	open($FH,">>",$img_file) or die "cann't open the file for writing\n";
	print $FH "dummy\n";
}
else{
	print "$logdir/submitedImgs.log file exists\n";
}
open($FH,"<",$img_file) or die "cann't open the file\n";
while(<$FH>){
	chomp;
       	push(@submited_imgs,$_);
}
print "submitted Imges are @submited_imgs\n";
$test_subject="$Date $branchtag Sanity Test Submission(s) failed for below images";
#====================== MAIN STARTS ======================================================
foreach my $action (@actions){
	switch($action){
		case "sanity"{
				sanitySubmission();
		}
		case "extarchive"{
				changePerm();
				checkExtendedArchive();
				copyToExtendedArchive();
		}
		case "c2kversion"{
				getc2kVersion();				
		}
		case "sesut"{
				buildsesimages();
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
}
#====================== MAIN ENDS ======================================================

sub sanitySubmission{
    if( -e "$logdir/testsubmission.test.log" ){
        print "$logdir/testsubmission.test.log file exists\n";
    }
    else{
        system("touch $logdir/testsubmission.test.log");
    }
    foreach my $key ( @sanityimages ){
	print "key is $key\n";
	if( !-e "$archive_dir/$key.$rtag" ){
		print "$key image doesn't exist Will continue with next image\n";
		next;
	}
	if(( -e "$archive_dir/$key.$rtag" ) && ( all {$_ ne $key} @submited_imgs )){
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
                     		 	case "basic-sanity-fex-combo"{
                                        	                my $h_option="fex_combo";
                                                	        executeTest($h_option,$key,"basic-sanity-fex-combo");
                                 	              		}
                     		 	case "basic-sanity-fex"{
                                        	                my $h_option="fex";
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
		open($FH,">>",$img_file) or die "cann't open the file $img_file\n";
		print $FH "$key\n";
	}		
    }
    #if any of the above test submissions failed they are captured in the checkSubmissionStatus
    # $test_msgbody gets values in checkSubmissionStatus
    if(defined $test_msgbody){
   	 send_mail($test_subject,$test_msgbody,$error_email_to);	
    }	
}
#================================================================================================================================================================
sub executeTest{
	my $h_option=shift;
	my $image=shift;
	my $test=shift;
	print "test submitted = $test\n";
	my $test_cmd="/auto/hss-native/basic-sanity.pl -i $archive_dir/$image.$rtag -b $branchtag -r $branch_notification -d nightly -H $h_option";
	open($FH,">>","$logdir/testsubmission.test.log") or die "cann't open the file $logdir/testsubmission.test.log\n";
	print $FH "$test_cmd\n";
	print "Following Test Command Submitted ....................\n $test_cmd\n";
	my $submit_test=`/auto/hss-native/basic-sanity.pl -i $archive_dir/$image.$rtag -b $branchtag -r $branch_notification -d nightly -H $h_option 2>&1`;
	print "value of submit_test in ExecuteTest $submit_test\n";
	if(grep(/Already/i,$submit_test)){
		print "Test got submitted already \n";
	}
	else{
	  	open($FH,">>","$logdir/testsubmission.test.log") or die "cann't open the file $logdir/testsubmission.test.log\n";	
		foreach(split(/\n/,$submit_test)){
			print $FH "$_.\n";
		}
	}
	close $FH;
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
                	$test_msgbody="\n$test_msgbody$img\n" ;
                }
	}
}
#=====================================================================================================================================
sub scanTestLog{
	my $cmd = "/auto/elb_build/autobuild/background_builds/common/scan_log.pl $logdir/testsubmission.test.log > $logdir/testscan.$Date.test.log";
	print "$cmd\n";
	system($cmd);
}
#=====================================================================================================================================
sub copyToExtendedArchive{
	checkDiskSpace();
	my $return_status=checkExtendedArchive();
	if ($return_status == 0){
		my @cpfailarray;
		my $subject;
		my $ext_msgbody;
        	my @subdir=("bin","sun","sym");
		my $dir;
		foreach $dir (@subdir){
			print "==========================================================\n";
			chomp $dir;
			my $exarchive="${extendedarchivedir}/${dir}";
			print "\nextended archive is $exarchive\n";
			chdir $exarchive;
			if( -d $rtag ){
				print "$rtag directory exists\n";
			}
			else{
			        print "Creating $rtag directory in extended archive area\n";
        	       	        mkdir $rtag;
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
			$ext_msgbody="\n$ext_msgbody$img\n" ;
		}
		if(defined $ext_msgbody){
			send_mail($subject,$ext_msgbody,$error_email_to);
		}
	}
	else{
		print "Extended archive didn't exist will continue with the rest\n";
	} 
}
sub checkExtendedArchive {
	if( ! -d $extendedarchivedir){
		my $msgbody="ERROR: $extendedarchivedir Extended archive directory does not exist";
       		print "$msgbody\n";
      		my $subject="Extended Archive Directory doesn't exist";
		if (not $opt_testing) { send_mail($subject,$msgbody,$error_email_to) } ;
		return(1);
	}
	else{
		return(0);
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
		send_mail($subject,$msgbody,$error_email_to);
	}
}
sub getc2kVersion{
        print "In getc2kVersion; Will get version for img ($img) and img2 ($img2) \n";

	my ($c2kimage, $c2kimage2, $pathCmd, $imgVer);

	if ($img)
	{
		$c2kimage=`grep $img "$builddir/$file_path/$ver_mgmt_file"|awk -F , '{print \$1}'`;
		print "In getc2kVersion; Cmd: grep $img \"$builddir/$file_path/$ver_mgmt_file\"|awk -F , '{print \$1}'\n";
		print "In getc2kVersion; Cmd result: $c2kimage \n";
	}
	
	if ($img2)
	{
		$c2kimage2=`grep $img2 "$builddir/$file_path/$ver_mgmt_file"|awk -F , '{print \$1}'`;
		print "In getc2kVersion; Cmd2: grep $img2 \"$builddir/$file_path/$ver_mgmt_file\"|awk -F , '{print \$1}'\n";
		print "In getc2kVersion; Cmd2 result: $c2kimage2 \n";
	}

	##Enhancement for the integ email to contain complete path of bundled image
	##This will help in identifying if the image is fc2 
        chomp($bundleLog);

	if ($bundleLog)
	{
        	$bundleLog = $logdir . '/' . $bundleLog;
        	print "In getc2kVersion; bundleLog: $bundleLog \n";

        	if( ! -e $bundleLog)
        	{
               		print "WARNING: $bundleLog does not exist; Bundling email will NOT contain PATH of bundled image :( \n";
        	}
        	else
        	{
                	my $grepStr = "Path of C2K image bundled:";
                	$pathCmd = `grep \'$grepStr\' $bundleLog`;
                	print "In getc2kVersion; Output: $pathCmd \n";

			my @splice = split (/:/, $pathCmd);
			chomp ($splice[1]);
			my $imagePath = $splice[1];
			$imagePath =~ s/ //g; 
			print "In getc2kVersion; Image Path: $imagePath \n";

			if (-e $imagePath)
			{
				my $verCmd = "grep -a Version $imagePath | head -n 1";
				print "In getc2kVersion; CMD: $verCmd\n";
				$imgVer = `$verCmd`;
				print "In getc2kVersion; Image Version: $imgVer\n";
			}
			else
			{
				print "WARNING: $imagePath does NOT exist; Bundling email will NOT contain VERSION of bundled image :( \n";
			}

        	}
	}
	else
	{
		print "WARNING: No value for -blog(bundleLog); Bundling email will NOT contain PATH of bundled image :( \n";
	}

        my $subject="$Date $branchtag $rtag c2kimage bundled version"; 
	my $msgbody="C2K image bundled into this build is: $c2kimage $c2kimage2 \n$pathCmd\nImageVersion: $imgVer";
	print "Invoking send_mail; $subject \t $msgbody \t $c2k_notification \n\n";
        send_mail($subject,$msgbody,$c2k_notification); 
}
#=========================================================================================
sub send_mail{
	my($subject, $msgbody, $email_to)=@_;
	print "In send_mail; Values: $subject, $msgbody, $email_to \n";
	if(!defined($error_email_to)){
		$error_email_to="ahudatha\@cisco.com";
	}
	else{
		$error_email_to=$email_to;
	}
	if(!defined($email_from)){
		$email_from="isbuweb\@cisco.com";
	}
	my %mail = (   To      =>  "$error_email_to",
	               From    =>  "$email_from",
		       Subject =>  "$subject",	
	               Message =>  "$msgbody"
	            );

	print "In send_mail; Values: $error_email_to, $email_from, $subject, $msgbody \n";
	sendmail(%mail) or warn $Mail::Sendmail::error;
	print "In send_mail; Done. \n";
	#lets comments this for now
	#print "\nOK. Log says:\n", $Mail::Sendmail::log;
}
#=========================================================================================
sub usage{
	my $exit_value = shift;
       print "\nUsage: $0 --cfg <datafile.branch> -ldir \$RT_LOGDIR --action [sanity|extarchive|sesut|c2kversion|all] -v \$RT_VERSION_ID
		-b \$RT_BRANCH_NAME -bldir \$RT_BUILD_DIR -bindir \$RT_ARCHIVE_DIR_BIN \n\n";
        print " -action : optional: either sanity, extarchive,c2kversion,sesut  \n";
        print "         : if nothing is specified then it does everything \n"; 
        print " -ldir current build log directory(RT_LOGDIR) name\n";
        print " -v build version(RT_VERSION_ID) \n";
        print " -bldir build directory(RT_BUILD_DIR) \n";
        print " -b branchname(RT_BRANCH_NAME) \n";
        print " -bindir archive bin directory(RT_ARCHIVE_DIR_BIN) \n";
        print " -cfg  sanity datafile\n";
        print " -h|?|help prints this usage\n\n";
	exit $exit_value;
}
#=========================================================================================
sub buildsesimages{
        print "Entering postbuild process to build sessut images\n";
        $sesarchivedir="$archive_dir/SESUT";
        $seslogdir="$logdir/SESUT";
        if( -d $seslogdir ){
                print "$seslogdir directory exists\n";
        }
        else{
                print "Creating $seslogdir directory in log directory\n";
                mkdir $seslogdir;
        }
        if( -d $sesarchivedir ){
                print "$sesarchivedir Directory Exists\n";
        }
        else{
                print "Creating $seslogdir directory in log directory\n";
                mkdir $sesarchivedir;
        }
        my $bld_dir="$builddir/sys";
        chdir $bld_dir;
        print "pwd is: $bld_dir\n";
        print  "seslogdir is set to:  $seslogdir\n";
        print "Run sesutnb";
        #my $cmd="/auto/ses/bin/sesutnb -imagefile $sesbuildfile -logdir $seslogdir -imagedir $sesarchivedir -nightly -mailto $sesbuildmail";
        my $cmd="/ws/wezuo-sjc/sesut/sesut/scripts/sesutnb -imagefile $sesbuildfile -logdir $seslogdir -imagedir $sesarchivedir -mailto $sesbuildmail";
        my $status=`$cmd 2>&1 1>/dev/null`;
        #print "status: $status" if $DEBUG;
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
        `chmod 755 "c6848x-adventerprisek9_dbg-mz.SSA.$rtag"`;
        print "Changing the permission of the T1, T2 images \n";
        if($? == 0){
                print "successfully changed the permissions\n";
        }
}
