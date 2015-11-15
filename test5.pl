#! /usr/cisco/bin/perl
use warnings;
use strict;
use Data::Dumper;
use JSON qw(decode_json);

=pod
open(my $FH,"<",'bundle.datafile') or die "[ERROR]   : Can't Open File:bundle.datafile.\n";
foreach my $line(<$FH>){
	if ($line =~ /^\#/){
		next;
	}else{
	    my $json_str=$line;
		my $to_perl=decode_json($json_str);
        if($to_perl->{id_check} ne "true"){
        	print "Skipping the Image $to_perl->{branch} to bundle as Bundle option is set to False\n";
            next;	
        }else{
			my $bundle_id=$to_perl->{bundle_id};
			print "$bundle_id\n";
		}
	}
}
=cut

#&_add_bug_id('555555555','/users/sabind/SCRIPTS/abc.txt');
sub _add_bug_id{
	my ($bug_id,$file) = @_;
	chomp($bug_id,$file);
	open(my $FH,">>",$file) or die "[ERROR]   : Can't Open File:$file.\n";
	print "print $bug_id to file : $file \n";
	print $FH "$bug_id\n";
	close($FH);
	print "[INFO]    : $bug_id Sucessfully added to $file.\n";
}

if( -w '/users/sabind/SCRIPTS/abc.txt'){
	print "File writable\n";
}

=pod
sub bugExists {
	my $rtb_file = "/auto/scmlog/ios/$branch_name/RestrictedToBugs-$branch_name";
    $stat = _doSystemCommand("grep $bugid $rtb_file > /dev/null 2>&1");
    
    if ( $stat != 0 ) {
    	$msg = "$bugid could not be added to RestrictedToBugs-$branch_name file.";
        $subj ="[$script_name : $branch_name] $bugid Is Not Present, Failed to add to RestrictedToBugs-$branch_name";
        if( -w "$rtb_file"){
        	print "[INFO]    : Adding $bugid to /auto/scmlog/ios/$branch_name/RestrictedToBugs-$branch_name.\n";
        	_add_bug_id($bugid,$rtb_file);
        }else{
        	_abort_with_error( $subj, $msg );
        }
    }
    $rtb_file = "/auto/scmlog/ios/$branch_name/MultipleCommitsAllowed";
    $stat = _doSystemCommand("grep $bugid $rtb_file > /dev/null 2>&1");
    if ( $stat != 0 ) {
        $msg ="$bugid could not be added to /auto/scmlog/ios/$branch_name/MultipleCommitsAllowed file.";
        $subj = "[$script_name : $branch_name] $bugid Is Not Present, Failed to add to MultipleCommitsAllowed.";
        if( -w "$rtb_file"){
        	print "[INFO]    : Adding $bugid to /auto/scmlog/ios/$branch_name/MultipleCommitsAllowed.\n";
        	_add_bug_id($bugid,$rtb_file);
        }else{
        	_abort_with_error( $subj, $msg );
        }
    }
}

#==

