#!/usr/cisco/bin/perl5.8 -w 
use strict;
use warnings;
use JSON qw(decode_json);
use Data::Dumper;
use Getopt::Long;
use Mail::Sendmail;
use File::Find::Rule;

sub usage;
sub bugExists;
sub branchExists;
sub viewExists;
sub ExtractAndUpdateVersion;
sub RunMutiSiteSync; 
sub checkBugIntegrationField;

my ($view_name, @str,$logdir, $branch_name, $bugid, $bundle_datafile, $buildeng, $opt_testing, $opt_help, $status, $error_email_to, $verfile_loc, $ver_file, $micro_dir, $TMP_DIR, $BIN_FILE, $image, $img_location, $img_tar, $version, $version_file, $email_from, $to_perl, $line, $FH, $des_loc, $build_ver, $build_partition, @processedImages);

if ( not scalar @ARGV) {&usage(1)};
GetOptions (    "v|view=s"        => \$view_name,
                "l|logdir=s"      => \$logdir,
                "b|branch=s"      => \$branch_name,
		"i|bugid=s"	  => \$bugid,
		"e|buildeng=s"	  => \$buildeng,
		"ver|version=s"   => \$build_ver,
		"p|partition=s"   => \$build_partition,
                "t|test"          => \$opt_testing,
                "h|help"          => \$opt_help
           ) or &usage(1);
if($opt_help){
        usage(0);
}

#$bundle_datafile="/auto/scmlog/ios/$branch_name/ImageLists/datafile.json";
$bundle_datafile="/users/integ/build_scripts/${branch_name}_bundle.datafile";
chomp($bundle_datafile);
my $script_name=`basename $0`;
chomp($script_name);
print "VIEW NAME IS: $view_name\n";
print "LOG DIRECTORY IS: $logdir\n";
print "BRANCH NAME IS: $branch_name\n";
print "BUNDLE DATAFILE: $bundle_datafile\n";

#Check if the buildeng is specified
if( not $buildeng){
        $buildeng="isbuweb\@cisco.com";
}
# check if the view_name is specified
if( not $view_name){
        my $msgbody="ERROR: Specify the view name using -v or -view option";
        print "$msgbody\n";
        my $subject="For $build_ver $branch_name build  view is missing while Invoking the bundling script $script_name";
        if (not $opt_testing) { send_mail($subject,$msgbody,$buildeng) } ;
        exit(1);
}
#check if the view exists or not
viewExists($view_name);

# check if the build version is specified
if( not $build_ver){
        my $msgbody="ERROR: Specify the build version using -ver or -version option";
        print "$msgbody\n";
        my $subject="For $build_ver $branch_name build Build version is missing while Invoking the bundling script $script_name";
        if (not $opt_testing) { send_mail($subject,$msgbody,$buildeng) } ;
        exit(1);
}
#check if the build partition is specified
if( not $build_partition){
        my $msgbody="ERROR: Specify the build partition using -p or -partition option";
        print "$msgbody\n";
        my $subject="For $build_ver $branch_name build Build partition is missing while Invoking the bundling script $script_name";
        if (not $opt_testing) { send_mail($subject,$msgbody,$buildeng) } ;
        exit(1);
}
#check if the logdir is specified
if( not $logdir ){
        my $msgbody="ERROR: Specify the log directory using -l or -logdir option";
        print "$msgbody\n";
        my $subject="For $build_ver $branch_name build logdir missing while Invoking the bundling script $script_name";
        if (not $opt_testing) { send_mail($subject,$msgbody,$buildeng) } ;
        exit(1);
}

#check if the logdir exists
if( ! -d $logdir ){
        my $msgbody="ERROR: $logdir logdir does not exist";
        print "$msgbody\n";
        my $subject="For $build_ver $branch_name build Logdir doesn't exist";
        if (not $opt_testing) { send_mail($subject,$msgbody,$buildeng) } ;
        exit(1);
}

#check if the branch_name is specified
if( not $branch_name ){
        my $msgbody="ERROR: Specify the branch name using -b or -branch option";
        print "$msgbody\n";
        my $subject="For $build_ver $branch_name build branchname  missing while Invoking the bundling script $script_name";
        if (not $opt_testing) { send_mail($subject,$msgbody,$buildeng) } ;
        exit(1);
}
branchExists($branch_name);


#Check if the bugid is specified
if( not $bugid){
        my $msgbody="ERROR: Specify the bugid using -i or -bugid option";
        print "$msgbody\n";
        my $subject="For $build_ver $branch_name build bugid missing while Invoking the bundling script $script_name";
        if (not $opt_testing) { send_mail($subject,$msgbody,$buildeng) } ;
        exit(1);
}
#check if the bugid exists in the RestrictedtoBugs-$branch and MultipleCommitsAllowed
bugExists();


#check if the bundle datafile exists
if( ! -f $bundle_datafile){
        my $msgbody="ERROR: bundle_datafile file does not exist";
        print "$msgbody\n";
        my $subject="For $build_ver $branch_name build bundle_datafile doesn't exist in the specified directory";
        if (not $opt_testing) { send_mail($subject,$msgbody,$buildeng) } ;
        exit(1);
}
if (! -r $bundle_datafile){
	my $msgbody="ERROR: bundle_datafile file is not readable";
        print "$msgbody\n";
        my $subject="For $build_ver $branch_name build bundle_datafile is not readable";
        if (not $opt_testing) { send_mail($subject,$msgbody,$buildeng) } ;
        exit(1);
}
checkBugIntegrationField();

#$json = JSON->new->allow_nonref;
$TMP_DIR="bndl_script_temp_dir";

=pod
print " ============ updating the view to the LATEST ========== \n";
@str=`cleartool setview -exec "cd /vob/ios/sys; cc_update -m LATEST -f" $view_name`;
if($? != 0){
	print "Error in updating the view.......\n";
	print "@str\n\n";
}
else{
	print "@str\n";
	print "Updating the view to the Latest is successful\n";
}

=cut
print "After updating the view: $view_name\n";

print "\n\n========== Bundling the Images =========== \n";
my $file=$bundle_datafile;
open($FH,"<",$file);
foreach $line(<$FH>){
	if ($line =~ /^\#/){
		next;
	}
	else{ 	
		print $line;
	    	my $json_str=$line;
		$to_perl=decode_json($json_str);
                if($to_perl->{Bundle} ne "true"){
			print "\n\nSkipping the Image $to_perl->{image} to bundle as Bundle option is set to False\n\n";
                	next;
                }
		else{
			$image=$to_perl->{image};
			chomp($image);
			print "Currently Bundling image ======= $to_perl->{image}\n\n";
			$img_location=$to_perl->{img_location};
			chomp($img_location);
			
			$img_location=`ls -la $img_location|awk '{print \$11}'`;
			chomp($img_location);
			
			print "image_loaction is $img_location\n";
			print "\nCurrent Bundling image location is ======= $img_location\n\n";
			chdir $img_location;
			
			print " #### img_location = $img_location ####\n";
			die;
			#$img_tar=`cd $img_location;find . -name "$image.*" | awk -F '/' '{print \$NF}'|tail -1`; 
			$img_tar=`find . -name "$image.*" | awk -F '/' '{print \$NF}'|tail -1`; 
		        chomp($img_tar);	
    	                print "Image Location: $img_location; Image Tar: $img_tar; Image: $image ;\n\n";
			if(! -f "$img_location/$img_tar"){
				print "Image $image doesn't exist in archive: $img_location/$img_tar\n\n";
				next;
			}
			print "image tar file is ======= $img_tar\n\n";
		 	$micro_dir=$to_perl->{micro_dir};
			chomp($micro_dir);
		 	print "micro directory is $to_perl->{micro_dir}\n\n";
			$verfile_loc="$to_perl->{verfile_loc}\n";
			chomp($verfile_loc);
			print "Verisonfile location is $verfile_loc\n";
			$ver_file="$to_perl->{ver_file}";
			chomp($ver_file);
			print "============ Checking out the Version Management File ============= \n";  
			print "Verisonfile is $ver_file\n";
			my $ver_loc="/view/$view_name/$verfile_loc";
			chdir $ver_loc;
			my $str=`cleartool desc -fmt "%o" $ver_file`;
			chomp($str);
			if($str eq 'checkout'){
				print " version file $ver_file is already checked out \n\n";	
			}
			else{
				my @output=`cleartool setview -exec "cd $verfile_loc; cc_co -nc -f $ver_file" $view_name`;
        			if($? == 0){
					print "@output\n";
                			print "successfully checkedout the $ver_file version Management file\n\n";
        			}
				else{
                			print "Failed to checkedout the $ver_file version Management file\n\n";
					print "@output \n";
				}
			}
			print " =============  Checking Out the Image $image ============= \n\n";
			my $loc="/view/$view_name/$micro_dir";
                        chomp($loc);
                        chdir($loc);
                        my $str1=`cleartool desc -fmt "%o" $image`;
                        chomp($str1);
                        if($str1 eq "checkout"){
                                print " Image file $image is already checked out \n\n";
                                `cleartool setview -exec "cd $micro_dir; cc_unco -force_unco $image" $view_name`;

                        }
			my @output1=`cleartool setview -exec "cd $micro_dir; cc_co -nc -f $image" $view_name`;
			if($? != 0){
				print "Failed to checkout the Image $image\n"; 
				cleanup($image);
				print @output1;
				next;
			}
			else{
				print "@output1\n";
				print "$image checkout successfully \n\n";
			}

			print "============ Copying the Image to Micro Directory ========== \n\n";
			$des_loc="/view/$view_name$micro_dir";
			chomp($des_loc);
			chdir $des_loc;
			my $pwd=`pwd`;
			print "present WORKING DIrectory = $pwd\n\n";
			my $source_img="$img_location/$img_tar";
			print "Path of C2K image bundled: $source_img \n\n";
			`cp -p $source_img $image`;
         		if($? != 0){
                		print "couldn't copy the image to micro directory\n\n";
                		cleanup($image);
    			}
			else{
				print "Image copied to micro directory\n";
			}

			print "============= Creating Temporary Directory ===============\n\n";
		        chdir $des_loc;   
			if ( -d $TMP_DIR ){
				print "Temporary directory already exists\n\n";
			}
			else{
				print "Temporary directory doesn't exist creating it .....\n\n";
				`mkdir $TMP_DIR`;
				if($? != 0){
		                	print "Error in creating the TMP_DIR\n\n";
		        	}
				else{
					print "TMP_DIR is created successfully\n\n";
				}
			}

			print "=============== Untaring the Image to temporary Directory ====================\n\n";
			my $tmpdir="$des_loc/$TMP_DIR";
			chomp($tmpdir);
			chdir $tmpdir;
			`tar -xvf $source_img`;
		        if($? != 0){
               			 print "Error during untar $image file\n\n";
                		 cleanup($image);
        		}
			else{
				print "Untar is successful \n\n";
			}

			print "=========== Extracting .bin and verison and updating it in the $ver_file Version Management file =====\n\n";
		        ExtractAndUpdateVersion($image,$img_tar,$des_loc,$tmpdir,$verfile_loc,$ver_file);
			if( $? == 0 ){
				print "========== updating the Processed Imagelist File ==========\n\n";
				push(@processedImages,$image);
			}
		}
	}
}	
if(@processedImages){
	#print "Images in the processedImages array are @processedImages\n";
	print "========= Preparing for commit as the Images exists in ProcessedImages Array ========\n\n";
        my @output2=`cleartool setview -exec "prepare -f -noip -i $bugid -k 'Bundle porter tar file to Sup2T image' -m LATEST" $view_name`;
        if($? == 0){
		print "@output2\n";
        	print "Prepare is successful\n\n";
		print "========== Performing the commit ============\n\n";
        	my @output=`cleartool setview -exec "commit -f" $view_name`;
        	if($? == 0){
               		print "@output\n";
               		print "Commit is successful\n";
			print "============== Running Mutisite Sync =============== \n\n";
		        RunMutiSiteSync($branch_name,$build_partition);
		        #print "RunMutiSiteSync($branch_name,$build_partition)";
        	}
        	else{
                	print "Commit failed \n";
                	print "@output\n";
        	}
        } 
	else{
		print "Prepare failed...@output2\n\n";
	} 
}
else{
	print "No Images are Bundled\n";
}
print "================ Uncheckout the checkedout files ============ \n\n";
foreach my $img(@processedImages){
	cleanup($img);
}
print "=============== Uncheckout the fex_version_mgmt.c =========== \n\n";
`cleartool setview -exec "cd $verfile_loc; cc_unco -force_unco $ver_file" $view_name`;
if($? == 0){
	print "$ver_file is unchecked out successfully \n\n";
}
else{
	print "$ver_file is not uncheckedout successfully \n\n";
}
print "=============== Removing Temporary directory ================ \n\n";
chdir $des_loc; 
`rm -r $TMP_DIR`; 
if($? == 0){
	print "Removing temporary Directory is successful\n";
}
else{
	print "Removing temporary Directory is not successful\n";
}

#========   End of Main ============
#
# 
#========= Function definitions ==================================
sub cleanup{
        my($images)=@_;
        foreach my $img ($images){
                `cleartool setview -exec "cd $micro_dir; cc_unco -force_unco $img" $view_name`;
		if($? == 0){
			print "$img is unchecked out successfully \n\n";
		}
		else{
			print "$img is not uncheckedout successfully \n\n";
		}
        }
}
#=========================================================================================
sub ExtractAndUpdateVersion{
        my($img,$img_tar,$des_loc,$tmp_dir,$verfile_loc,$ver_file)=@_;	
	chdir $des_loc;
	my $str=`ls $img | awk -F - '{print \$1}'`;
	chomp($str);
	my @BIN_FILE=File::Find::Rule->file()
				     ->name("$str*.bin")
				     ->in($tmp_dir);
	my $image_name=`ls @BIN_FILE|awk -F \/ '{print \$NF}'`;
        $image_name =~ s/bin/tar/i;
	chomp($image_name);
		#print "New Image bin name = $img_tar \n\n";
	if($? == 0){
		print "New Image bin name = $image_name \n\n";
	}
	#chdir $des_loc;
	my $new_version=`strings -a $img | grep CW_VERSION | tail -1 | awk -F \$ '{print \$2}'`;
	chomp($new_version);
	print "New Image version = $new_version  \n\n";
	#Getting Previous verion and image bin name from fex_version_mgmt.c file
	my $prev_file_name=`grep $str "/view/$view_name/$verfile_loc/$ver_file"|cut -d '\"' -f 2`;
	chomp($prev_file_name);
	print "previous file name = $prev_file_name\n\n";
        my $line_num=`grep -nr "$str*" "/view/$view_name/$verfile_loc/$ver_file"|awk -F : '{print \$1}'`;
        chomp($line_num);	
	my $ver_line=$line_num-1;
	chomp($ver_line);
	my $prev_version=`awk 'NR==$ver_line' /view/$view_name/$verfile_loc/$ver_file|awk -F { '{print \$2}'|cut -d '\"' -f 2`;
	chomp($prev_version);
        print "previous version = $prev_version\n\n";
	my $version_file="/view/$view_name/$verfile_loc/$ver_file";
	chomp($version_file);
	print "version file is $version_file\n\n";
        print "============= Updating the Fex image Version and Name in fex_version_mgmt.c file ============ \n\n";	
        #`perl -pi -e 's/$prev_file_name/$image_name/g' $version_file`;	
        `sed -i 's/$prev_version/$new_version/g' $version_file`;	
	if($? == 0){
		print "Replaced the version Successfully \n\n";
	}
	else{
		print "Failed to replace the version \n\n";
	} 
        `sed -i 's/$prev_file_name/$image_name/g' $version_file`;	
	if($? == 0){
                print "Replaced the Image Name Successfully \n\n";
        }
        else{
                print "Failed to replace the Image Name \n\n";
        }

	
}
#=========================================================================================
sub send_mail{
        my($subject, $msgbody, $email_to)=@_;
        if(!defined($error_email_to)){
                $error_email_to="ahudatha\@cisco.com";
        }
        else{
                #$error_email_to=$email_to;
                $error_email_to="ahudatha\@cisco.com";
        }
        if(!defined($email_from)){
                $email_from="isbuweb\@cisco.com";
        }
        my %mail = (   To      =>  "$error_email_to",
                       From    =>  "$email_from",
                       Subject =>  "$subject",
                       Message =>  "$msgbody"
                    );

        sendmail(%mail) or warn $Mail::Sendmail::error;
}
#=========================================================================================
sub RunMutiSiteSync{
	my($branch,$build_partition)=@_;
	my $view_tag="SYNC_VIEW";
	my $view_name="BLD-${branch}.SYNC_VIEW";
	print "$view_name is the view name from multisync\n";
        print "$branch is the branch\n";
	system("mkview -i ${branch} -t ${view_tag} -p BLD -v /vob/ios -s $build_partition -a");
	my $vobios="/view/$view_name/vob/ios";
	chomp $vobios;
        print "$vobios is vobios\n";
        chdir $vobios;
        my @output=`/ws/isbj/mtrose/scripts/msiteSync $branch`; 
	if($? == 0){
		print "@output \n";
		print "multisitesync is successful\n"; 
	}
	else{
		print "multisitesync is not successful\n";
	}
	print "\n ========= Removing the view once the msyte sync is complete ================\n";
	chdir $build_partition;
        system("cleartool rmview -tag $view_name");
}
#=========================================================================================
sub usage{
        my $exit_value = shift;
        print "\nUsage: $0 -l \$RT_LOGDIR -v view_name -p \$RT_BUILD_PARTITION
                -b \$RT_BRANCH_NAME -i bugid -e buildeng -ver \$RT_BUILD_VERSION\n\n";
        print " -l current build log directory(RT_LOGDIR) name\n";
        print " -v view_name \n";
        print " -i bugid \n";
        print " -b branchname(\$RT_BRANCH_NAME) \n";
        print " -e buildeng \n";
	print " -ver|version \$RT_BUILD_VERSION \n";
        print " -p|partition \$RT_BUILD_PARTITION \n";
        print " -h|?|help prints this usage\n\n";
        exit $exit_value;
}
#========================================================================================
sub bugExists{
        my $bugexists=system("grep $bugid /auto/scmlog/ios/$branch_name/RestrictedToBugs-$branch_name");
        if( $bugexists != 0){
                my $msgbody="ERROR: $bugid is not present in the RestrictedToBugs-$branch_name file";
                my $subject="For $build_ver $branch_name build $bugid not present in the RestrictedToBugs-$branch_name file";
                if (not $opt_testing) { send_mail($subject,$msgbody) } ;
		exit(1);
        }
        my $bugfound=system("grep $bugid /auto/scmlog/ios/$branch_name/MultipleCommitsAllowed");
        if( $bugfound != 0){
                my $msgbody="ERROR: $bugid is not present in MultipleCommitsAllowed file";
                my $subject="For $build_ver $branch_name build $bugid not present in MultipleCommitsAllowed file";
                if (not $opt_testing) { send_mail($subject,$msgbody) } ;
		exit(1);
        }
}
#==========================================================================================
sub viewExists{
        my ($view_name)=@_;
        my $status=system("cleartool lsview -s $view_name");
        #my $status=`cleartool lsview -s $view_name`;
        if($status != 0){
                my $msgbody="ERROR: Specified view doesn't exist";
                print "$msgbody\n";
                my $subject="For $build_ver $branch_name build view $view_name doesn't exist";
                if (not $opt_testing) { send_mail($subject,$msgbody) } ;
                exit(1);
        }
}
#=============================================================================================
sub branchExists{
        my ($branch_name)=@_;
        my $status=system("cleartool desc -s brtype:$branch_name@/vob/ios");
        if($status != 0){
                my $msgbody="ERROR: Specified branch doesn't exist";
                print "$msgbody\n";
                my $subject="For $build_ver $branch_name build branch $branch_name doesn't exist";
                if (not $opt_testing) { send_mail($subject,$msgbody) } ;
                exit(1);
        }

}
#=============================================================================================
sub checkBugIntegrationField{
	my $length=`findcr -i $bugid -w "Integrated-releases" | wc -c`;
	#my $length=`findcr -i CSCud49759 -w "Integrated-releases" | wc -c`;
	if($length > 1900){
		my $msgbody="WARNING: $bugid bugid Integration-releases field will be full soon please create another bug for $branch_name";
       		print "$msgbody\n";
	        my $subject="For $build_ver $branch_name build Integrated-releases field is almost full for bug $bugid";
        	send_mail($subject,$msgbody);		
	
	}
}
