#!/usr/cisco/bin/perl5.8 -w
use strict;
use Data::Dumper;
use Getopt::Long;
use WWW::Mechanize;
use Compress::Zlib;
use List::MoreUtils qw( each_array );
 
###############################################################################################
###
#
#   Script  : sync_solver.pl
#
#   Author  : Sandeep Kumar Bind
#
#   Desc    : This script is for resolving issues in sync process.
#
###
###############################################################################################

#USES : % perl cdts.pl -b  CSCuu58139 -br v154_3_m_throttle
#perl /users/sabind/SCRIPTS/sync_solver.pl -pb v155_3_m_throttle -cb t_base_6 -L2 V155_3_M0_3 -L1 V155_3_M0_2


my ($pbranch,$cbranch,$to_label,$frm_label,$help_msg);
GetOptions(
    "pb|parent_branch:s"    => \$pbranch,
    "cb|child_branch:s"     => \$cbranch,
    "L1|frm_label:s"     	=> \$frm_label,
    "L2|to_label:s"     	=> \$to_label,
    "help|h"        		=> \$help_msg,
) or die "[OPTION ERROR]    : Please see usage [sync_solver.pl -help].\n";


if ($help_msg) {
    system("/usr/cisco/bin/perldoc -t $0 ");
    exit 0;
}
unless($pbranch){
	print "[OPTION ERROR]    : Please pass the parrent branch by option [ -pb] or [ -parent_branch].\n[OPTION ERROR]    : For more details please see help [sync_solver.pl -help].\n";
    exit 0;
}
unless($cbranch){
	print "[OPTION ERROR]    : Please pass the child branch by option [ -cb] or [ -child_branch].\n[OPTION ERROR]    : For more details please see help [sync_solver.pl -help].\n";
    exit 0;
}
unless($frm_label){
	print "[OPTION ERROR]    : Please pass the start LABEL by option [ -L1] or [ -frm_label].\n[OPTION ERROR]    : For more details please see help [sync_solver.pl -help].\n";
    exit 0;
}
unless($to_label){
	print "[OPTION ERROR]    : Please pass the end LABEL by option [ -L2] or [ -to_label].\n[OPTION ERROR]    : For more details please see help [sync_solver.pl -help].\n";
    exit 0;
}

print "[INFO]    : ---------------------------------------------------------------------------------------------\n";
print "[INFO]    : PARENT BRANCH : $pbranch\n" if($pbranch);
print "[INFO]    : CHILD BRANCH : $cbranch\n" if($cbranch);
print "[INFO]    : START LABEL : $frm_label\n" if($frm_label);
print "[INFO]    : END LABEL : $to_label\n" if($to_label);

my @bugs_in_parrent;
my @bugs_in_child;	
my @bugs_double_committed;
my $log_file;

_doSystemCommand("rm -rf SYNC_SOLVER > /dev/null 2>&1") if(-d "SYNC_SOLVER");
_doSystemCommand("mkdir SYNC_SOLVER > /dev/null 2>&1");

chdir('SYNC_SOLVER');

_get_parrent_bugs($pbranch,$frm_label,$to_label);
_get_child_bugs($cbranch);
_get_double_commit();

sub _get_parrent_bugs{
	my($branch,$from_label,$to_label) = @_;
	print "[INFO]    : Getting list of bugs commited to $branch b/w Label:$from_label to Label:$to_label\n";
	my $cmd = "/usr/cisco/bin/cc_list_bugs -vob /vob/ios -b $branch -type direct -from label:$from_label -to label:$to_label";
	my @word = `$cmd`;
	@bugs_in_parrent = grep(s/\s*$//g, @word); # remove leading and trainling space of array elements.
	_write_into_file($branch,\@bugs_in_parrent);
}

sub _get_child_bugs{
	my($branch) = @_;
	print "[INFO]    : Getting list of bugs commited to child branch: $branch.\n";
	my $cmd = "/usr/cisco/bin/cc_list_bugs -vob /vob/ios -b $branch -type direct";
	my @word = `$cmd`;
	@bugs_in_child =  grep(s/\s*$//g, @word); # remove leading and trainling space of array elements.
	_write_into_file($branch,\@bugs_in_child);
}

sub _get_double_commit{
	print "[INFO]    : Getting double commited bugs.\n";
	foreach my $data ( @bugs_in_parrent ){
	    push @bugs_double_committed, $data if grep { $_ eq $data } @bugs_in_child;
	}
	_write_into_file('double_comit',\@bugs_double_committed);
}

sub _write_into_file{
	my($branch,$content) = @_;
	$log_file = $branch.'.bugs' if($branch);
	chomp($log_file);
	_doSystemCommand("rm -rf $log_file > /dev/null 2>&1") if(-f $log_file);
	print "[INFO]    : $branch bug list file: $log_file\n";
	open(MYFILE, '>', $log_file) or die "[ERROR]   : Could Not Open File '$log_file' $!";
	foreach (@$content){
		chomp;
		print MYFILE "$_\n";	
	}
	close(MYFILE);
}

sub _doSystemCommand {
    my $systemCommand = $_[0];
    print "[INFO]    : Executing... [$systemCommand] \n";
    my $returnVal = system( $systemCommand );
    if ( $returnVal != 0 ) 
    {
        print "[ERROR]   : Failed To Execute [$systemCommand] \n";
    }
	print "[INFO]    : Sucessfully Executed [$systemCommand] \n";
}

if(-f "v155_3_m_throttle.bugs"){
	_doSystemCommand("/usr/cisco/bin/perl5.8 /users/sabind/SCRIPTS/get_ddts_elements.pl -f v155_3_m_throttle.bugs -br v155_3_m_throttle");
}

my $check_file_version = 'check_file_version';
&_get_bleed_through_files();

sub _create_version_list{
	_doSystemCommand("rm -rf $check_file_version > /dev/null 2>&1") if(-f $check_file_version);
	open(MYF, '>', $check_file_version) or die "[ERROR]   : Could Not Open File '$check_file_version' $!";
	if(-f "bug_files.log"){
		my @files = `/bin/cat bug_files.log | cut -d':' -f3`; # bug_files.log is getting created in get_ddts_elements.pl.
		foreach (@files){
			chomp;
			print MYF "/usr/atria/bin/cleartool ls $_\n";
		}
	}
	close(MYF);
	_doSystemCommand("/bin/chmod +x $check_file_version > /dev/null 2>&1") if(-f $check_file_version);	
}


sub _get_bleed_through_files{
	
	&_create_version_list();
	print "[INFO]    : Getting list of bleed throgh files.\n";

	my @list = `$check_file_version`;
	my @bleed = grep { /mkbranch/ } @list;
	my @bleed_file =  grep(s/@@.*$//g, @bleed);
	
	my @bleed_file_detail;
	my @files_all_details = `/bin/cat bug_files.log`;
	foreach my $data ( @files_all_details ){
		chomp $data;
		my @data = split(':',$data);
		push @bleed_file_detail, $data if grep { $_ =~ /$data[2]/ } @bleed_file;
	}
	if(@bleed_file_detail){
		print "[INFO]    : Listing bleed through files.\n";
		print "[INFO]    : ---------------------------------------------------------------------------------------------\n";
		my $same_bug = 'NA'; # dummy value.
		foreach(@bleed_file_detail){
			my @fields = split(':',$_);
			if($fields[0] eq $same_bug){
				#print "\t\t\t    $fields[2]\n";
				print "          : \t$fields[2]\n";
			}else{
				#print "          : $_\n";
				print "          : $fields[0] : $fields[1]\n";
				print "          : File(s):\n";
				print "          : \t$fields[2]\n";
			}
			$same_bug = $fields[0];
		}
	}else{
		print "[INFO]    : No bleed through files found.\n";
	}
	
}


