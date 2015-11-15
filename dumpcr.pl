#!/usr/cisco/bin/perl     #/usr/local/bin/perl
package dumpcr;
use Getopt::Long;
require LWP::UserAgent;
use URI::Escape;
use File::Temp qw/ tempfile tempdir /;

$SIG{PIPE}='IGNORE';

sub Usage { 
	print "\n";
	print "usage: dumpcr [--help] [{-x,--xml} | {-h,--html} | {-s,--summary} | {-d,--datafile}]\n";
    print "              [{-P,--parentprogram}]\n"; 
    print "              [{-S,--smallxml}]\n"; 
    print "              [{-e,--enclosure}]\n"; 
    print "              [{-u,--unmarked}] [{-n,--note} title][{-a,--attachment} title]] [{-t,--history}] [{-df,--dateformat}]\n";
    print "              identifier identifier ...\n";
    print "\n";
	print "  --help                : print this usage\n";
	print "  -x,--xml              : output in XML format\n";
  	print "  -h,--html             : output in HTML format\n";
  	print "  -s,--summary          : output in 132 column wide summary format\n";
  	print "  -e,--enclosure        : include note(s) and attachment(s) contents in the output. When\n";
    print "                          used with -n and or -a option, it allows you to display selected\n";
	print "                          note(s) or attachment(s)\n";
  	print "  -u,--unmarked         : do not show '---End of [Note|Attachment] Title: <title>---'\n";
    print "                          between enclosures. Only works in combination with -e option.\n";
  	print "  -n,--note title       : show only the note(s) contents that match the title. Wildcard\n";
    print "                          asterisk (*) is allowed\n";
  	print "  -a,--attachment title : show only the attachment(s) contents that match the title.\n";
  	print "  -t,--history          : show only the audit trail (history) contents.\n";
	print "  -df,--dateformat      : specify the format for the date output.\n";
  	print "  -d,--datafile         : output in datafile format (Fieldname: value) format.\n";
  	print "  -S,--smallxml         : output in xml format with excluding following nodes \n";
	print "                          ListOfPdItemNote\n";
    print "                          ListOfFixEntry\n";
    print "                          ListOfDummy\n";
    print "                          ListOfCSCRelatedCREAI\n";
	print "\n";
	print "You must quote special characters like asterisk (*) to disable shell interpretation\n";
	print "\n";
	print "Please run \"cdets\" for list of command and field names supported\n";
	print "by CDETS software\n";
	print "\n";

    exit (0);
}
	our $binaryAttachment = 0;
	######### Global Exit Status value #########
	$exitStatus = 0;
	$debug = 0;
	
	# set serverName
	if ($ENV{'CDETS_URL'} ne ""){
		@url_parts = split(/\//, $ENV{'CDETS_URL'});
		#### Get only the Host Name ###
		$serverName = $url_parts[2];
	}

	if ($ENV{'CDETS_DEBUG'} =~ m/true/ix){
		$debug = 1;
	}else{
		$debug = 0;
	}
			
	if ($ENV{'CDETS_USER'} ne "") {
	    $username = $ENV{'CDETS_USER'};
	} elsif ($ENV{'USER'} ne "") {
	    $username = $ENV{'USER'};
	} else {
	    $username = $ENV{'USERNAME'};
	}

	$template = "dumpcrcliXXXXX";
	########## Temp File Path & Dir ###########
	if($^O eq "MSWin32"){
		$temp_dir = $ENV{'TEMP'};
	}elsif($^O eq 'MacOS') {
		$temp_dir = $ENV{'TMPDIR'};
	}else {
		$temp_dir = "/tmp";
	}
	
	########## Print Usage ############
	foreach $arg (@ARGV) {
	   if ($arg eq "--help" || $arg eq "") {
		  &Usage;
		  exit(1);
	   }
	}
		
	################### Get User Parameters ###############
        &Getopt::Long::Configure('no_ignore_case');
	&GetOptions(\%Options,  "x|xml", "h|html", "s|summary", "P|parentprogram=s", 
							"S|smallxml","e|enclosure", "n|note=s","a|attachment=s", 
							"t|history", "u|unmarked","d|datafile", "df|dateformat=s");

	############ Initial Checks ##########
	if ($Options{x} && $Options{h}) {
	 	print STDERR "Please provide either -x or -h parameter as command line argument\n";
	 	exit(1);
	}
	
	if(($Options{x}) && $Options{s}){
		print STDERR "Please use -s parameter without -x parameter as command line argument\n";
		exit(1);
	}

	if($Options{e} && !($Options{a} || $Options{n})){
		print STDERR "Please use -e parameter with either -a or -n parameters\n";
		exit(1);
	}

	if(($Options{a} || $Options{n}) && !($Options{e})){
		print STDERR "Please use -e parameter with either -a or -n parameters\n";
		exit(1);
	}
	
	if($Options{u} && !$Options{e}){
		print STDERR "Please use -u parameter only with -e parameter\n";
		exit(1);
	}
	
	####################### Start Processing ############################
	$myRequest =  "http://" . $serverName . "/apps/dumpcr?username=$username&debug=$debug&cleartext=true";
	
	
	####################### Output Format ###############################
	$outputFormat = ""; 	# Global variable which holds output format requested
	$myRequest .= "&format=";	
	# Output format XML/HTML		
	if($Options{x}){
		$myRequest .= "xml";
		$outputFormat = "xml";
          if($Options{S}){
                $myRequest .= "&smallxml=true";
          }
	}elsif ($Options{h}){
		$myRequest .= "html";
		$outputFormat = "html";
	}elsif ($Options{d}){
		$myRequest .= "dfile";
		$outputFormat = "dfile";
	}else{
		$myRequest .= "default";
		$outputFormat = "default";
	}

	####################### Output Content #####################
	$myRequest .= "&content=";
	if ($Options{s}){
		$myRequest .= "summary";
	}elsif ($Options{t}){
		$myRequest .= "history";
	}else{
		$myRequest .= "default";
	}
	
	######### Marked/Unmarked ############	
	if($Options{u}){
		$myRequest .= "&unmarked=";
		$myRequest .= $Options{u};
	}

        #################### Get the parentnprogram if supplied ############
        if($Options{P}){
                $myRequest .= "&parentprogram=";
                $myRequest .= $Options{P};
        }


	########### Enclosure Only ###########
	if($Options{e}){
		$myRequest .= "&enclosure=";
		$myRequest .= $Options{e};
	}
	#################### Notes #################
	if($Options{n}){
		$myRequest .= "&note=";
		$myRequest .= $Options{n};
	}
		
	$count = 1;

	#################### Attachments ############
	# Option where -a is used without -e
	# Return bug data with attachments
	if ($Options{a} && !$Options{e}){
		@local_ARGV = @ARGV;
		foreach $local_arg (@local_ARGV) {
			if(&checkBugId($local_arg)){
				if(&getBugData($local_arg, $outputFormat)){
					if(&getTitleFile($local_arg, $Options{a})){
						&getTitleName($local_arg);
					}
				}
				if(! -e $outFilename){
					($OutFH, $outFilename) = tempfile( "out_$username".$template, DIR => $temp_dir, SUFFIX => ".tmp");
				}else {
					open($OutFH, ">>$outFilename");
				}
				if($binaryAttachment ==1){
					binmode($OutFH);
				}
				open(BUGDATA, "$bugDataFilename");
					print $OutFH <BUGDATA>;
				close(BUGDATA);
				open(ATTDATA, "$attachmentFile");
				if($binaryAttachment ==1){
					binmode(ATTDATA);
				}
				print $OutFH <ATTDATA>;
				close(ATTDATA);
				close($OutFH);
				&cleanup($bugDataFilename, $attachmentFile, $attInfoFilename);
			}
		}

		&dumpFile($outFilename);
		&cleanup($outFilename);		
		&exit($exitStatus);
	}
	
	# Option where -a is used with -e
	# Return only attachments No Bug data
	if ($Options{a} && $Options{e}){
		@local_ARGV = @ARGV;
		foreach $local_arg (@local_ARGV) {
			if(&checkBugId($local_arg)){			
				if(&getTitleFile($local_arg, $Options{a})){
					&getTitleName($local_arg);
				}
				
				if(! -e $outFilename){
					($OutFH, $outFilename) = tempfile( "out_$username".$template, DIR => $temp_dir, SUFFIX => ".tmp");
				}else {
					open($OutFH, ">>$outFilename");
				}
				if($binaryAttachment ==1){
					binmode($OutFH);
				}
				open(ATTDATA, "$attachmentFile");
				if($binaryAttachment ==1){
					binmode(ATTDATA);
				}
#=========commented for bugfix CSCsy68585 CDETS Rel: 1.4.5 ===============			   
=cm
			   if($attCount == 1){
				  print $OutFH "---Start of Attachment Titled: ". $title. " (".$attachmentMeta.")---\n";
				  print $OutFH <ATTDATA>;
				  print $OutFH "---End of Attachment Titled: ". $title. "---\n\n";
			   }
			   else{
				   print $OutFH <ATTDATA>;
			  }
=cut
#=======================End =======
#================== new code added for bugfix CSCsy68585 CDETS Rel: 1.4.5 ============================
			if(!$Options{u} && $attCount == 1){
			  print $OutFH "---Start of Attachment Titled: ". $title. " (".$attachmentMeta.")---\n";
				print $OutFH <ATTDATA>;
			  print $OutFH "---End of Attachment Titled: ". $title. "---\n\n";
		   }
		   else{
			   print $OutFH <ATTDATA>;
		   }
#=================End of newly added code for bugfix CSCsy68585 CDETS Rel: 1.4.5 =============================================
				close(ATTDATA);
				close($OutFH);
				&cleanup($attachmentFile, $attInfoFilename);
			}
		}
		&dumpFile($outFilename);
		&cleanup($outFilename);
		&exit($exitStatus);
	}
	
	
	if(@ARGV < 1){
	 	################### Process STDIN ###################
		while(<STDIN>){
			$i = $_;
			chomp ($i);
			$i =~ s/\s+//g;
			if(!$i eq '') {
				$localRequest = $myRequest;
				if(&checkBugId($i)){
					$localRequest .= "&identifier=";
					$localRequest .= $i;
					&dumpit($localRequest);
				}
			}
		}
 	}else{
		#################### Process all the Bug Ids from Arguments #################
                $cnt = 0;
		foreach $arg (@ARGV) {
			if(&checkBugId($arg)){
                           push(@ids,$arg);
                           push(@ids,",");
			}
		}
		$localRequest = $myRequest;
		$localRequest .= "&identifier=";

                foreach $elem (@ids){
                 $localRequest .= $elem;
                }
                $localRequest =~ s/,$//;

        	&dumpit($localRequest);
	}	
	&exit($exitStatus);

####################### Private Subroutines ####################

############## Dumps normal output on screen (Not Attachments) ##########
sub dumpit() {
	$request = $_[0];
	
		#print "Request is : $request \n";
	
	$ua = LWP::UserAgent->new;
 	$req = HTTP::Request->new('GET', $request);

 	if ($debug == 1){ ### CDETS_DEBUG=true
	 	print "Executed Servlet Request: $request\n\n";
 	}
 	
 	$response = $ua->request($req); # ormotd

	if ($response->is_success) {
		
		if($ENV{'CDETS_LOCAL_DATETIME'}=~ m/true/ix){
			&convertTimeZone($response);
		 }else{
			print $response->content;
		}
		
    	###### Check for special Case of Note not found ######
		if($Options{n}){	
	    	$resp = $response->as_string;
	    	if($resp =~ m/The\ssupplied\snote\sdoes\snot\sexist\sin\sCDETS/ix) {
		    	$exitStatus = 1; ## Special case even though response is success
	    	}
		}
 	} else {
	 	if($debug == 1){   ### CDETS_DEBUG=true
    		print STDERR $response->error_as_HTML;
		}
		$resp = $response->as_string;
	    if($resp =~ m/The\sspecified\snote\sdoes\snot\sexist\sfor\sthe\sbug/ix) {
		    	print STDERR "The specified note does not exist for the bug.";
	    }
		else
		{
			$responseStatus = $response->status_line;
			if($responseStatus =~ /^([0-9]*\s)(.*)$/){ ### Split the error Code from Error Msg
				$errorCodeReturned = $1; ## save error code for future enhancements
				print STDERR $2 . "\n\n"; ## print the Error Message
			}
		}
    	$exitStatus=1;


 	}
}

# Dumps a file to the output, Filename passed as argument
sub dumpFile(){
	if($_[0] ne ""){
		open(INFO, $_[0]);
		if($binaryAttachment){
			binmode (INFO);
			binmode(STDOUT);
		}
		while ( read( INFO, $buffer, 1024 ) ) {
        	print STDOUT $buffer;
    	}
		close(INFO);
	}
}

# Remove all temp files
sub cleanup(){
	foreach $file (@_){
		unlink($file);
	}
}

	
# makes a call to DumpServlet with enclosure=1
# and attachment string
# dumps output into a temp file (contains username)
sub getTitleFile(){
	$nRequest = "http://$serverName/apps/dumpcr?username=$username&debug=$debug&cleartext=true";
	if($_[0] ne "" && $_[1] ne ""){
		$nRequest .= "&identifier=$_[0]";
		$nRequest .= "&attachment=$_[1]";
		$nRequest .= "&enclosure=1";
	}
	
	$nUa = LWP::UserAgent->new;
 	$nReq = HTTP::Request->new('GET', $nRequest);

 	$nResponse = $nUa->request($nReq);

	if ($nResponse->is_success) {
		# this file contains Titles of all Attachments which match criteria
		($AttInfoFH, $attInfoFilename) = tempfile( "attInfo_$username".$template, DIR => $temp_dir, SUFFIX => ".tmp");
    	print $AttInfoFH $nResponse->content;
 	} else {
	 	if($debug == 1){   ### CDETS_DEBUG=true
    		print STDERR $nResponse->error_as_HTML;
		}
		$responseStatus = $nResponse->status_line;
		if($responseStatus =~ /^([0-9]*\s)(.*)$/){ ### Split the error Code from Error Msg
			$errorCodeReturned = $1; ## save error code for future enhancements
			print STDERR $2 . "\n\n"; ## print the Error Message
		}
    	$exitStatus = 1;
 	}
 	close($AttInfoFH);
}

# reads each line of title file and extracts Title name
sub getTitleName(){
	
	#**********************************************************************
	 if($ENV{'CDETS_LOCAL_DATETIME'}=~ m/true/ix){
		($destBugAttFH, $destattInfoFilename) = tempfile( "destattInfoFilename"."_tgt_".$template, DIR => $temp_dir, SUFFIX => ".tmp");
		my $currTz = "PST";
		my $clspath = $ENV{'CDETS_INSTALL_DIR'};
		my $javacmd = "java -classpath $clspath/classes com.cisco.cdets.utils.TZParser $attInfoFilename $destattInfoFilename o $debug  \"$Options{df}\"";
	    system("$javacmd");
		@lines = <$destBugAttFH>;
	    close($destBugAttFH);
	 }else{
			open($AttInfoFH1, "<$attInfoFilename");
			@lines = <$AttInfoFH1>;
			close($AttInfoFH1);
	 }
	
	#**********************************************************************

	$attNotFound = 1;
	$attCount = &countAttachments();
	foreach $line (@lines){
		if($line =~ /.*File-attachment::(.*)$/){
# 			if($1 =~ /(.*)::\s+(.*)$/){
			@splits = split(/::/, $line);
			$attachmentMeta = trim($splits[1]);
			$attType=trim($splits[2]);
			if($attType =~ /.*binary.*/){
				$binaryAttachment = 1;
			}
			$title = trim($splits[4]);
			$attNotFound=0;
			# call getAttachment for each Bug ID & title
			&getAttachment($_[0], $title, $attCount);
		}
	}
	if ($attNotFound == 1){
		print STDERR "The supplied attachment does not exist in CDETS\n\n";
		$exitStatus = 1;
	}
}


# makes a call to DumpAttServlet with bug ID and Title
# dumps the attachment into a temp file
sub getAttachment(){
	$newAttRequest = "http://$serverName/apps/dumpcr_att?debug=$debug&cleartext=true";
	if ($_[0] ne "" && $_[1] ne ""){
		$newAttRequest .= "&identifier=$_[0]";
		$newAttRequest .= "&title=$_[1]";
	}
	if($debug == 1){  ### CDETS_DEBUG=true
		print "Attachment request: $newAttRequest \n";
	}
	
	$newAttUa = LWP::UserAgent->new;
 	$newAttReq = HTTP::Request->new('GET', $newAttRequest);
 	$newAttResponse = $newAttUa->request($newAttReq);
 	$attachCount = $_[2];
	
 	
 	if($newAttResponse->is_success){
	 	if(! -e $attachmentFile){
	 		($AttDataFH, $attachmentFile) = tempfile( "attData_$username".$template, DIR => $temp_dir, SUFFIX => ".tmp");
	 	}else {
		 	open($AttDataFH, ">>$attachmentFile");
	 	}
	 	if($binaryAttachment == 1){
	 		binmode($AttDataFH);
	 	}
	 	if(!$Options{u} && $attachCount>1){
	 		print $AttDataFH "---Start of Attachment Titled: ". $_[1]. " (".$attachmentMeta.")---\n";
 		}
	 	print $AttDataFH $newAttResponse->content;
	 	if(!$Options{u} && $attachCount>1){
	 		print $AttDataFH "---End of Attachment Titled: ". $_[1]. "---\n\n";
 		}
 	}else{
	 	if($debug == 1){ ### CDETS_DEBUG=true
	 		print STDERR $newAttResponse->error_as_HTML;
 		}
 		print STDERR $newAttResponse->status_line. "\n";
	 	$exitStatus = 1;
 	}
 	#print "******* getAttachment ". $newAttResponse->status_line ."\n";
 	close($AttDataFH);
 	
}

# makes a call to DumpServlet with Bug ID and required O/P format
# appends o/p to the existing attachment temp file (begining)
sub getBugData(){
	$newRequest = "http://$serverName/apps/dumpcr?username=$username&debug=$debug&cleartext=true";
	
	if ($_[0] ne "" && $_[1] ne ""){
		$newRequest .= "&identifier=$_[0]";
		$newRequest .= "&format=$_[1]";
		if($Options{u}){
			$newRequest .= "&unmarked=1";
		}
	}
	if($debug == 1){   ### CDETS_DEBUG=true
		print "BugData request: $newRequest \n";
	}
		
	$newUa = LWP::UserAgent->new;
 	$newReq = HTTP::Request->new('GET', $newRequest);

 	$newResponse = $newUa->request($newReq);

	if ($newResponse->is_success) {
		# This file contains all the Bug Data for each bug ID
		if(! -e $bugDataFilename){
			($BugdataFH, $bugDataFilename) = tempfile( "bugData_$username".$template, DIR => $temp_dir, SUFFIX => ".tmp");
		}else {
			open($BugdataFH, ">>$bugDataFilename");
		}
		if($binaryAttachment==1){
			binmode($BugdataFH);
		}
    	print $BugdataFH $newResponse->content;
 	} else {
	 	if($debug == 1){   ### CDETS_DEBUG=true
    		print STDERR $newResponse->error_as_HTML;
		}
		$responseStatus = $newResponse->status_line;
		if($responseStatus =~ /^([0-9]*\s)(.*)$/){ ### Split the error Code from Error Msg
			$errorCodeReturned = $1; ## save error code for future enhancements
			print STDERR $2 . "\n\n"; ## print the Error Message
		}
    	$exitStatus = 1;
 	}
 	#print "******* getBugData ". $newResponse->status_line."\n";
 	close($BugdataFH);
}

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub exit(){
	if($_[0] == 1){
		#print "Error executing dumpcr\n";
	}
	exit($_[0]);
}

sub checkBugId() {
	my $string = $_[0];
	$string =~ s/^\s+//; #remove leading spaces
	$string =~ s/\s+$//; #remove trailing spaces
	if($string =~/CSC[a-z]{2}\d{5}$/){
		return 1;
	}else {
		print STDERR "Bug ID [$_[0]] does not match expected format.\n";
		$exitStatus=1;
		return 0;
	}
}

sub countAttachments() {
	open($fileHandle, "<$attInfoFilename");
	@fileContent = <$fileHandle>;
	close($fileHandle);
	$attachmentCount = 0;
	foreach $line (@fileContent){
		if($line =~ /.*File-attachment::(.*)$/){
			$attachmentCount ++;
		}
	}
	return $attachmentCount;
}

sub convertTimeZone() {
	  
	  $response = $_[0];
	 ($srcBugdataFH, $srcbugDataFilename) = tempfile( "cdets_$username"."_src_".$template, DIR => $temp_dir, SUFFIX => ".tmp");
		  
	  print $srcBugdataFH $response->content;

	  ($destBugdataFH, $destbugDataFilename) = tempfile( "cdets_$username"."_tgt_".$template, DIR => $temp_dir, SUFFIX => ".tmp");
	  my $currTz = "PST";
	  my $clspath = $ENV{'CDETS_INSTALL_DIR'};
	  my $javacmd = "java -classpath $clspath/classes com.cisco.cdets.utils.TZParser $srcbugDataFilename $destbugDataFilename o $debug  \"$Options{df}\"";
	  system("$javacmd");

	  &dumpFile($destbugDataFilename);

	  close($srcBugdataFH);
	  close($destBugdataFH);

}
