#!/usr/cisco/bin/perl5.8 -w

###
#
#   Script  : C2k_Image_Bundle.pl
#
#   Author  : Sandeep Kumar Bind
#
#   Desc    : This script is for C2k Images to C6k.
#
###
 
use strict;
use warnings;
use JSON qw(decode_json);
use Data::Dumper;
use Getopt::Long;
use Mail::Sendmail;
use File::Find::Rule;
use MIME::Lite;

sub usage;
sub bugExists;
sub branchExists;
sub viewExists;
sub ExtractAndUpdateVersion;
sub RunMutiSiteSync; 
sub checkBugIntegrationField;
sub _notify_me;
sub _write_logs;
sub _doSystemCommand;

my ($view_name, @str,$logdir, $branch_name, $bugid, $bundle_datafile, $buildeng, $opt_testing, $opt_help, $stat, $error_email_to, $verfile_loc, $ver_file, $micro_dir, $TMP_DIR, $BIN_FILE, $image, $img_location, $img_tar, $version, $version_file, $email_from, $to_perl, $line, $FH, $des_loc, $build_ver, $build_partition, @processedImages);
my $mail_data;
if ( not scalar @ARGV) {&usage(1)};
GetOptions (    "v|view=s"        => \$view_name,
                "l|logdir=s"      => \$logdir,
                "b|branch=s"      => \$branch_name,
                "i|bugid=s"	      => \$bugid,
                "e|buildeng=s"	  => \$buildeng,
                "ver|version=s"   => \$build_ver,
                "p|partition=s"   => \$build_partition,
                "t|test"          => \$opt_testing,
                "h|help"          => \$opt_help
           ) or &usage(1);
if($opt_help){
        usage(0);
}

chomp(my $script_name=`basename $0`);
my ($msg,$subj);
print "[INFO]    : ========= Start Of The Main ==========\n";
print "[INFO]    : ------------------------------------------------------------------------------------------------\n";
if( not $branch_name ){
		$msg = "Please Specify The Branch Name Using -b or -branch Option.";
		$subj = "[$script_name] Branchname Is Missing.";
		_abort_with_error($subj,$msg);
}else{
	$bundle_datafile="/users/integ/build_scripts/${branch_name}_bundle.datafile";
	#$bundle_datafile='data_file_mk2a';
	chomp($bundle_datafile);	
}

if( ! -f $bundle_datafile){
        $msg = "Datafile File: $bundle_datafile  Doesn't Exist.";
        $subj = "[$script_name : $branch_name] Datafile Doesn't Exist.";
        _abort_with_error($subj,$msg);
}
if (! -r $bundle_datafile){
		$msg = "Datafile File: $bundle_datafile is not readable";
        $subj = "[$script_name : $branch_name] Datafile is not readable";
        _abort_with_error($subj,$msg);
}

print "[INFO]    : VIEW NAME : $view_name\n" if($view_name);
print "[INFO]    : BRANCH NAME : $branch_name\n" if($branch_name);
print "[INFO]    : BUNDLE DATAFILE : $bundle_datafile\n" if$bundle_datafile;
print "[INFO]    : LOG DIRECTORY : $logdir\n" if($logdir);

if( not $bugid){
        $msg = "Please Specify The Bugid Using -i or -bugid Option.";
        $subj = "[$script_name : $branch_name] Build Bugid is missing.";
        _abort_with_error($subj,$msg);
}


bugExists();
branchExists($branch_name);

if( not $build_ver){
        $msg = "Please Specify The Build Version Using -ver or -version Option.";
        $subj = "[$script_name : $branch_name] Version Is Missing.";
        _abort_with_error($subj,$msg);
}

if( not $build_partition){
        $msg = "Please Specify The Build Partition Using -p or -partition Option.";
        $subj = "[$script_name : $branch_name] Partition is Missing.";
        _abort_with_error($subj,$msg);
}

if( not $logdir ){
        $msg = "Please Specify The Log Dir Using -l or -logdir Option.";
        $subj = "[$script_name : $branch_name] Build Logdir is Missing.";
        _abort_with_error($subj,$msg);
}

if( ! -d $logdir ){
        $msg = "Logdir: $logdir Does Not Exist.";
        $subj = "[$script_name : $branch_name]Logdir Doesn't Exist.";
        _abort_with_error($subj,$msg);
}

if( not $view_name){
		$msg = "Please Specify The View Name Using -v or -view Option.";
		$subj = "[$script_name : $branch_name] View Is missing.";
        _abort_with_error($subj,$msg);
}
viewExists($view_name);
checkBugIntegrationField();

$TMP_DIR='TEMP_TAR_EXTRACTION';
print "[INFO]    : ------------------------------------------------------------------------------------------------\n";
my $log_file = $branch_name.'ct_cmds.log';
$log_file = $logdir.'/'.$log_file;
my $std_out_err;
my $chdir_stats;


print "[INFO]    : ------------------------------------------------------------------------------------------------\n";
print "[INFO]    : Updating View To Latest.\n";
$std_out_err = `cleartool setview -exec "cd /vob/ios/sys; cc_update -m LATEST -f" $view_name 2>&1`;

if($? != 0){
	print "[ERROR]   : View: $view_name Update Unsucessfull.\n";
}
else{
	print "[INFO]    : View: $view_name Updated Sucessfully.\n";
}
print "[INFO]    : View Update Log Written To File: $log_file.\n";
_write_logs("VIEW UPDATE LOG :\nCOMMAND:\t cleartool setview -exec \"cd /vob/ios/sys; cc_update -m LATEST -f\" $view_name 2>&1\n",\$std_out_err) if($std_out_err);

print "[INFO]    : ------------------------------------------------------------------------------------------------\n";

open($FH,"<",$bundle_datafile) or die "[ERROR]   : Can't Open File: $bundle_datafile.\n";
foreach my $line(<$FH>){
	if ($line =~ /^\#/){
		next;
	}else{
	    my $json_str=$line;
		$to_perl=decode_json($json_str);
        if($to_perl->{Bundle} ne "true"){
        	print "[WARNING] : Skipping The Image $to_perl->{image} To bundle, As Bundle Option Is Set To False.\n";
            next;
		}else{
			chomp($image=$to_perl->{image});
			print "[INFO]    : Image To Checkout: $image.\n";
			chomp($img_location=$to_perl->{img_location});
			if( -l $img_location ) {
				chomp($img_location=`ls -la $img_location|awk '{print \$11}'`);
			}
			print "[INFO]    : Image Location: $img_location.\n";			
			#chdir function returns 0 on failure and 1 on success.

			if( -d $img_location){
				$chdir_stats = chdir $img_location;
				print "[ERROR]   : Failed To cd: $img_location.\n" unless($chdir_stats);
				chomp($img_tar=`find . -name "$image.*" | awk -F '/' '{print \$NF}'|tail -1`); 
		        if($img_tar){
		        	print "[INFO]    : Image Tar: $img_tar.\n";
		        }else{
		        	print "[ERROR]   : Tar Image Not Found At Path: $img_location.\n";
		        	$subj = "[$script_name : $branch_name] Tar Image Not Found.";
		        	if (not $opt_testing) { _notify_me($subj,"Tar Image Not Found At Path: $img_location.",'ERROR')};
		        }
			}else{
				print "[ERROR]   : Image Location: $img_location Doesn't exit.\n";
				$subj = "[$script_name : $branch_name] $img_location Doesn't exit.";
				if (not $opt_testing) { _notify_me($subj,"Image Location: $img_location Doesn't exit.",'ERROR')};
				next;
			}
			if(! -f "$img_location/$img_tar"){
				print "[ERROR]   : $image Doesn't Exist In Archive: $img_location/$img_tar.\n";
				$subj = "[$script_name : $branch_name] $image Doesn't Exist In Archive.";
				if (not $opt_testing) { _notify_me($subj,"$image Doesn't Exist In Archive: $img_location/$img_tar.",'ERROR')};
				next;
			}
		 	chomp($micro_dir=$to_perl->{micro_dir});
		 	if($micro_dir){
		 		print "[INFO]    : MICRO DIRECTORY: $micro_dir.\n";
		 	}else{
		 		print "[ERROR]   : MICRO DIRECTORY Doesn't Exists In DataFile\n";
		 		next;
		 	}
			chomp($verfile_loc=$to_perl->{verfile_loc});
			if($verfile_loc){
		 		print "[INFO]    : VerisonFile Location: $verfile_loc.\n";
		 	}else{
		 		print "[ERROR]   : VerisonFile Location Doesn't Exists In DataFile\n";
		 		next;
		 	}
			chomp($ver_file=$to_perl->{ver_file});
			if($ver_file){
		 		print "[INFO]    : VerisonFile: $ver_file.\n";
		 	}else{
		 		print "[ERROR]   : VerisonFile Doesn't exists In DataFile.\n";
		 		next;
		 	}
			chomp(my $ver_loc="/view/$view_name/$verfile_loc");
			$chdir_stats = chdir $ver_loc;
			print "[ERROR]   : Failed To cd: $ver_loc.\n" unless($chdir_stats);
			chomp(my $str=`cleartool desc -fmt "%o" $ver_file`);
			if($str eq 'checkout'){
				print "[WARNING] : Version File: $ver_file Is Already Checked Out.\n";
			}
			else{
				$std_out_err=`cleartool setview -exec "cd $verfile_loc; cc_co -nc -f $ver_file" $view_name 2>&1`;
        		if($? == 0){
					print "[INFO]    : Successfully Checkedout The $ver_file Version Management File.\n";
        		}else{
        			print "[ERROR]   : Failed To Checkout The $ver_file Version Management File.\n";
				}
				_write_logs("Checkout Log of File :\nCOMMAND:\t cleartool setview -exec \"cd $verfile_loc; cc_co -nc -f $ver_file\" $view_name 2>&1\n",\$std_out_err) if($std_out_err);
			}

			chomp(my $loc="/view/$view_name/$micro_dir");
            $chdir_stats = chdir($loc);
            print "[ERROR]   : Failed To cd: $loc.\n" unless($chdir_stats);
            chomp(my $str1=`cleartool desc -fmt "%o" $image`);
            if($str1 eq "checkout"){
            	print "[WARNING] : Image File $image Is Already Checked Out.\n";
            	$stat = _doSystemCommand("cleartool setview -exec \"cd $micro_dir; cc_unco -force_unco $image\" $view_name > /dev/null 2>&1");
            }
			$std_out_err=`cleartool setview -exec "cd $micro_dir; cc_co -nc -f $image" $view_name 2>&1`;
			if($? != 0){
				print "[ERROR]   : Failed To Checkout The Image $image.\n";
				cleanup($image);
				next;
			}
			else{
				print "[INFO]    : $image Checked Out Successfully.\n";
			}
			_write_logs("Checked Out Log oF $loc/$image:\nCOMMAND:\t cleartool setview -exec \"cd $micro_dir; cc_co -nc -f $image\" $view_name 2>&1\n",\$std_out_err) if($std_out_err);

			print "[INFO]    : Copying $image To Micro Directory.\n";
			chomp($des_loc="/view/$view_name$micro_dir");
			$chdir_stats = chdir($des_loc);
            print "[ERROR]   : Failed To cd: $des_loc\.n" unless($chdir_stats);

			chomp(my $source_img="$img_location/$img_tar");
			print "[INFO]    : Path Of C2K Image Bundled: $source_img.\n";
			$stat = _doSystemCommand("cp -p $source_img $image > /dev/null 2>&1");		
         	if($stat != 0){
         		print "[ERROR]   : Couldn't Copy The Image To Micro Directory.\n";
                cleanup($image);
			}else{
				print "[INFO]    : Image Copied To Micro Directory.\n";
			}

			print "[INFO]    : Creating Temporary Directory.\n"; 
			if ( -d $TMP_DIR ){
				print "[WARNING] : TMP_DIR $TMP_DIR Already Exists.\n";
			}
			else{
				print "[INFO]    : TMP_DIR: $TMP_DIR Doesn't Exist, Creating It...\n";
				$stat = _doSystemCommand("mkdir $TMP_DIR > /dev/null 2>&1");
				if($stat != 0){
					print "[ERROR]   : Error In Creating TMP_DIR: $TMP_DIR.\n";
		        }else{
		        	print "[INFO]    : TMP_DIR: $TMP_DIR Created Successfully.\n";
				}
			}

			print "[INFO]    : Untaring The Image IN Temp Directory.\n";
			chomp(my $tmpdir="$des_loc/$TMP_DIR");
			$chdir_stats = chdir($tmpdir);
            print "[ERROR]   : Failed To cd: $tmpdir.\n" unless($chdir_stats);
            $stat = _doSystemCommand("tar -xvf $source_img > /dev/null 2>&1");
		    if($stat != 0){
		        print "[ERROR]   : Error During Untar $image File.\n";
                cleanup($image);
        	}else{
				print "[INFO]    : Untar Is Successful.\n";
			}

		    print "[INFO]    : Extracting .bin And Verison & Updating The $ver_file Version Management File.\n";
		    ExtractAndUpdateVersion($image,$img_tar,$des_loc,$tmpdir,$verfile_loc,$ver_file);
			if( $? == 0 ){
				print "[INFO]    : Adding Image: $image To Processed Array.\n";
				push(@processedImages,$image);
			}else{
				print "[ERROR]   : Fail To Add Image: $image To Processed Array.\n";
			}
		}
	}
}

print "[INFO]    : ------------------------------------------------------------------------------------------------\n";
	
if(@processedImages){
	#print "Images in the processedImages array are @processedImages\n";
	print "[INFO]    : Preparing To Commit.\n";
    $std_out_err=`cleartool setview -exec "prepare -f -noip -i $bugid -k 'Bundle porter tar file to Sup2T image' -m LATEST" $view_name  2>&1`;        
        if($? == 0){
        	print "[INFO]    : Prepare Is Successful.\n";
        	_write_logs("Prepare Log::\nCOMMAND:\t cleartool setview -exec \"prepare -f -noip -i $bugid -k 'Bundle porter tar file to Sup2T image' -m LATEST\" $view_name  2>&1\n",\$std_out_err) if($std_out_err);
        	print "[INFO]    : Performing the commit.\n";
        	$std_out_err=`cleartool setview -exec "commit -f" $view_name 2>&1`;
        	if($? == 0){
               		print "[INFO]    : Commit is Successful.\n";
               		print "[INFO]    : Running Mutisite Sync.\n";
		        	RunMutiSiteSync($branch_name,$build_partition);
        	}else{
                	print "[ERROR]   : Commit Failed.\n";
        	}
        	_write_logs("Commit Log::\nCOMMAND:\t  cleartool setview -exec \"commit -f\" $view_name 2>&1",\$std_out_err) if($std_out_err);
        } 
	else{
		print "[ERROR]   : Prepare Failed.\n";
		_write_logs("Prepare Log::\nCOMMAND:\t cleartool setview -exec \"prepare -f -noip -i $bugid -k 'Bundle porter tar file to Sup2T image' -m LATEST\" $view_name  2>&1\n",\$std_out_err) if($std_out_err);
	} 
}else{
	print "[WARNING] : No Images Are Bundled.\n";
}

print "[INFO]    : ------------------------------------------------------------------------------------------------\n";

print "[INFO]    : Uncheckout The Checkedout Files.\n";
foreach my $img(@processedImages){
	cleanup($img);
}

$std_out_err=`cleartool setview -exec "cd $verfile_loc; cc_unco -force_unco $ver_file" $view_name 2>&1`;
if($? == 0){
	print "[INFO]    : $ver_file Is Unchecked Out Successfully.\n";
}
else{
	print "[ERROR]   : $ver_file Is Not Unchecked Out Successfully.\n";
}
print "[INFO]    : Removing Temp Directory.\n";
$chdir_stats = chdir $des_loc;
print "[ERROR]   : Failed To cd: $des_loc\n" unless($chdir_stats);

$stat = _doSystemCommand("rm -r $TMP_DIR > /dev/null 2>&1");
if($? == 0){
	print "[INFO]    : Removing Temp Directory Is Successful.\n";
}
else{
	print "[ERROR]   : Removing Temp Directory Is Not Successful.\n";
}
print "[INFO]    : ------------------------------------------------------------------------------------------------\n";
print "[INFO]    : ========= End Of The Main ==========\n";

#========   End of Main ============


sub cleanup{
        my($images)=@_;
        foreach my $img ($images){
            `cleartool setview -exec "cd $micro_dir; cc_unco -force_unco $img" $view_name`;
			if($? == 0){
				print "[INFO]    : $img Is Unchecked Out Successfully.\n";
			}else{
				print "[ERROR]   : $img Is Not Uncheckedout Successfully.\n";
			}
        }
}
#=========================================================================================
sub ExtractAndUpdateVersion{
    my($img,$img_tar,$des_loc,$tmp_dir,$verfile_loc,$ver_file)=@_;
	$chdir_stats = chdir $des_loc;
	print "[ERROR]   : Failed To cd: $des_loc\n" unless($chdir_stats);
	chomp(my $str=`ls $img | awk -F - '{print \$1}'`);
	my @BIN_FILE=File::Find::Rule->file()
				     ->name("$str*.bin")
				     ->in($tmp_dir);
	chomp(my $image_name=`ls @BIN_FILE|awk -F \/ '{print \$NF}'`);
    $image_name =~ s/bin/tar/i;
	if($? == 0){
		print "[INFO]    : New Image bin name = $image_name.\n";
	}

	chomp(my $new_version=`strings -a $img | grep CW_VERSION | tail -1 | awk -F \$ '{print \$2}'`);
	print "[INFO]    : New Image version = $new_version .\n";
	#Getting Previous verion and image bin name from fex_version_mgmt.c file
	chomp(my $prev_file_name=`grep $str "/view/$view_name/$verfile_loc/$ver_file"|cut -d '\"' -f 2`);
	print "[INFO]    : Previous file name = $prev_file_name.\n";
    chomp(my $line_num=`grep -nr "$str*" "/view/$view_name/$verfile_loc/$ver_file"|awk -F : '{print \$1}'`);
	my $ver_line=$line_num-1;
	chomp($ver_line);
	
	chomp(my $prev_version=`awk 'NR==$ver_line' /view/$view_name/$verfile_loc/$ver_file|awk -F { '{print \$2}'|cut -d '\"' -f 2`);
    print "[INFO]    : Previous version = $prev_version.\n";
	chomp(my $version_file="/view/$view_name/$verfile_loc/$ver_file");
	print "[INFO]    : Version file is $version_file.\n";
	print "[INFO]    : Updating the Fex image Version and Name in fex_version_mgmt.c file.\n";

    `sed -i 's/$prev_version/$new_version/g' $version_file`;	
	if($? == 0){
		print "[INFO]    : Replaced the version Successfully .\n";
	}
	else{
		print "[ERROR]   : Failed to replace the version.\n";
	} 
    `sed -i 's/$prev_file_name/$image_name/g' $version_file`;	
	if($? == 0){
		print "[INFO]    : Replaced the Image Name Successfully.\n";
     }else{
        print "[ERROR]   : Failed to replace the Image Name.\n";
     }
}

#=========================================================================================
sub RunMutiSiteSync{
	my($branch,$build_partition)=@_;
	my $view_tag="SYNC_VIEW";
	my $view_name="BLD-${branch}.SYNC_VIEW";
	print "[INFO]    : Starting Multisite Sync.\n";
	$stat = _doSystemCommand("mkview -i ${branch} -t ${view_tag} -p BLD -v /vob/ios -s $build_partition -a > /dev/null 2>&1");

	chomp(my $vobios="/view/$view_name/vob/ios");
    $chdir_stats = chdir($vobios);
    print "[ERROR]   : Failed To cd: $vobios\n" unless($chdir_stats); 
    my @output=`/ws/isbj/mtrose/scripts/msiteSync $branch`;
	if($? == 0){
		print "[INFO]    : Multisitesync is successful\n";
		print "[LOG]     : Multisitesync Log:\n";
		print "@output \n";
	}
	else{
		print "[ERROR]   : Multisitesync is not successful.\n";
	}
	$chdir_stats = chdir($build_partition);
    print "[ERROR]   : Failed To cd: $vobios\n" unless($chdir_stats);
    $stat= _doSystemCommand("cleartool rmview -tag $view_name > /dev/null 2>&1");
     
}
#========================================================================================
sub bugExists{
        $stat = _doSystemCommand("grep $bugid /auto/scmlog/ios/$branch_name/RestrictedToBugs-$branch_name > /dev/null 2>&1");
        if( $stat != 0){
        	$msg = "$bugid Is Not Present In RestrictedToBugs-$branch_name file.";
        	$subj = "[$script_name : $branch_name] $bugid Is Not Present In RestrictedToBugs-$branch_name.";
        	_abort_with_error($subj,$msg);
        }
        $stat = _doSystemCommand("grep $bugid /auto/scmlog/ios/$branch_name/MultipleCommitsAllowed > /dev/null 2>&1");
        if( $stat != 0){        	
        	$msg = "$bugid Is Not Present In File: /auto/scmlog/ios/$branch_name/MultipleCommitsAllowed.";
            $subj = "[$script_name : $branch_name] BugId: $bugid Is Not Present In MultipleCommitsAllowed.";
            _abort_with_error($subj,$msg);
        }
}
#==========================================================================================
sub viewExists{
        my ($view_name)=@_;
        $stat = _doSystemCommand("cleartool lsview -s $view_name > /dev/null 2>&1");
        if($stat != 0){
        	$msg = "Specified View : $view_name Doesn't Exist.";
			$subj = "[$script_name : $branch_name] View : $view_name Doesn't Exist.";
        	_abort_with_error($subj,$msg);
        }
}

#=============================================================================================
sub branchExists{
        my ($branch_name)=@_;
        $stat = _doSystemCommand("cleartool desc -s brtype:$branch_name@/vob/ios > /dev/null 2>&1");
        if($stat != 0){
             $msg = "Specified Branch: $branch_name Doesn't exist.";
             $subj = "[$script_name : $branch_name] Branch: $branch_name Doesn't Exist.";
             _abort_with_error($subj,$msg);
             
        }

}
#=============================================================================================
sub checkBugIntegrationField{
	chomp(my $length=`findcr -i $bugid -w "Integrated-releases" | wc -c`);
	if($length > 1900){
		$msg = "$bugid bugid Integration-releases Field Will Be Full Soon, Create Another Bug For $branch_name<br>LENGTH: $length<br>CUTOFF LENGTH: 1900";
       	print "[WARNING] : BUGID: $bugid Integration-releases Field Will Be Full Soon, Create Another Bug For $branch_name\n";
	    $subj = "[$script_name : $branch_name] Integrated-releases Field Is Almost Full For Bug $bugid";
        if (not $opt_testing) { _notify_me($subj,$msg,'WARNING')};		
	
	}
}

sub _doSystemCommand {
    my $systemCommand = $_[0];
    my $returnVal = system( $systemCommand );
    print "[INFO]    : Executing... [$systemCommand] \n";
    if ( $returnVal != 0 ) 
    {
        print "[ERROR]   : Failed To Execute [$systemCommand] \n";
        return 1;
    }
	print "[INFO]    : Sucessfully Executed [$systemCommand] \n";
    return 0;
}

sub _abort_with_error{
	my ($rsubj,$rmsg) = @_;
    print "[ERROR]   : $rmsg\n";
    if (not $opt_testing) { _notify_me($rsubj,$rmsg,'ERROR')};
    exit(1);
}

sub _notify_me{

    my ($subject,$HTML_data,$head) = @_;
    chomp(my $user = `whoami`);
    my $sendto = $user unless($buildeng);
    $user = 'isbuweb' if ($user =~/integ/);
    $branch_name ||= 'BRANCH' ;
    $head ||= 'DATA';
    chomp($sendto, $subject,$head);

my $msg = MIME::Lite->new(
		 From    =>"$user\@cisco.com",
         To      =>"$sendto\@cisco.com",
         Subject =>"$subject",
         Type    =>'multipart/related'
    );
    $msg->attach(
        Type => 'text/html',
        Data => qq{
            		<body>
                	<strong>Hi $sendto</strong>,
					<p><p>
						This is notification mail from $branch_name bundling script.
					<p><p><p><p><p>
					<strong><font color="#151B8D">Details:</font></strong>
					<br>
					<br>
					$head:<br>
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

sub _write_logs{
	my($log_head,$log_msg) = @_;
	open(MYFILE, '>>', $log_file) or die "[ERROR]   : Could Not Open File '$log_file' $!";
	print MYFILE "$log_head";
	print MYFILE "=================================================================================================\n\n";
	print MYFILE "$$log_msg\n\n";
	print MYFILE "\n------------------------------------------------------------------------------------------------\n";
	close(MYFILE);
}