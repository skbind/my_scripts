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
#   Script  : get_cdts.pl
#
#   Author  : Sandeep Kumar Bind
#
#   Desc    : This script is for getting bug details.
#
###
###############################################################################################

#USES : % perl get_cdts.pl -b  CSCuu58139 -br v154_3_m_throttle

my $branch;
my $help_msg;
my $file;

GetOptions(
    "branch|br:s"     => \$branch,
    "bug_list|f:s"  => \$file,
    "help|h"        => \$help_msg,
) or die " Error \n";

if ($help_msg) {
    system("/usr/cisco/bin/perldoc -t $0 ");
    exit 0;
}
unless($branch){
	print "[OPTION ERROR]    : Please pass the branch using option [ -br] or [ -branch].\n[OPTION ERROR]    : For more details please see help\n";
    exit 0;
}
unless($file){
	print "[OPTION ERROR]    : please pass the bug list using option [-f] or [-bug_list].\n[OPTION ERROR]    : For more details please see help\n";
    exit 0;
}

my @bug_id;
if (-f $file) {
	open (FH,"<$file") or die "[ERROR]    : Can't open the file: $file\n";
	foreach (<FH>){
		next if ($_ =~ /^s\+$/);
		chomp;
 		push @bug_id,$_;
	}
	close(FH);
}
print "[INFO]    : ---------------------------------------------------------------------------------------------\n";

my %bug_info;
my $bug_details = 'bug_complete_details.log';
system (" /bin/rm -rf $bug_details") if ( -f $bug_details);
open (FHW,">$bug_details") or die "Can't open the file: $bug_details\n";

my $bug_files = 'bug_files.log';
system ("/bin/rm -rf $bug_files") if ( -f $bug_files);
open (FH_FILES,">$bug_files") or die "Can't open the file: $bug_files\n";

my $bug_comp = 'bug_comp.log';
system (" /bin/rm -rf $bug_comp") if ( -f $bug_comp);
open (FH_COMP,">$bug_comp") or die "Can't open the file: $bug_comp\n";

foreach my $id (@bug_id){
	
	my $cmd = "/usr/cisco/bin/dumpcr $id | egrep \"Diffs--$branch|Engineer\\s+:\" 2>/dev/null | grep -v \"File Name\" 2>/dev/null "; 
	my $output = `$cmd`;
	my @data = split("\n",$output);	
	my $eng_reviewer = shift @data ;
	$eng_reviewer =~ s/\s{2,}/,/g;
	my ($engg, $reviewers) = split (",",$eng_reviewer);
	chomp($reviewers, $engg);
	$reviewers =~ s/\w+.+:\s+//g;
	$reviewers =~ s/\s+/,/g;
	chop $reviewers if ($reviewers =~ /\,$/);
	$engg =~ s/\w+.+:\s+//g;	
	$bug_info{$id}{'ENGG'} = $engg;
	$bug_info{$id}{'REVIEWER'} = $reviewers;
	$bug_info{$id}{'NO_OF_COMMITS'} = scalar (@data);
	
	my $no_of_commits = scalar (@data);
	my @date = @data;
	map { $_ =~ s/\s\s.*// } @data;	
	map { $_ =~ s/^Diff.+cva\s+// } @date;
	if($no_of_commits > 1){
		my $c =0;
		foreach ( @date){
			$c++;
		}
	}else{
		#print "Commit Date : $date[0]\n";
	}
	
	my $it = each_array( @data, @date );
	my $c = 0;
	while ( my ($branch_diff, $date) = $it->() ) {
		$c++;
		$date =~ s/\s{2,}//sm;
		my $mech = WWW::Mechanize->new(); 
		$mech->get("http://cdetsweb-prd.cisco.com/apps/dumpcr_att?identifier=$id&title=$branch_diff&type=FILE&displaytype=html");
		unless($mech->success()){
			print "[ERROR]    : Web link can not access\n";
			exit;
		}else{
			#print "\n web link Accessed sucessfully\n";
		}
	    my $discription = $2 if ($mech->response->content =~ /^(begin\slog\-entry)(.*)(end\slog\-entry)/sm);
	    my $file_match = "/view/.*$branch.*@@.*$branch.*";
	    my $files = $& if ($discription =~ /$file_match/sm);
	    $files =~ s/^\s+$//sm;
	    my $comments = $1 if ($discription =~ /\s+Comment\s+:\n(.+)Elements\s+:/sm);
	    $comments =~ s/^\s+$//sm;
		my $components;
		chomp($files);
		my @file_content = split("\n",$files);
		my @valid_files;
		foreach (@file_content){
			next if ($_ !~ /\w+/);
			next if ($_ =~ /\/view\/.+\.publication_manifest@@\/.+/);
			$_ =~ s/^\s+\/view/\/view/;
							$_ =~ s/\/view\/RES.+\.vob\.ios//;  # To remove /view/RES-v155_1_t_throttle.vob.ios
			push (@valid_files,$_);
		}
		
		if($files =~ /\/view\/.+\.publication_manifest@@\/.+/sm){
			my $components = $2 if ($mech->response->content =~ /(Begin publication manifest diff.+Updated:\s*\n\s+)(.+)(\n#### End publication manifest diff)/sm);
			my @comp = split ("\n",$components);
			my @valid_component;
			foreach (@comp){
				next if ($_ !~ /\w+/);
				$_ =~ s/^\s+//;
				push @valid_component,$_;
			}
			$bug_info{$id}{$date}{'COMPONENTS_MODIFIED'} = [@valid_component] ;
			if( scalar (@valid_component)){
				foreach(@valid_component){			
					print FHW "$id:#$c:$engg:COMP:$_\n";
					print FH_COMP "$id:$engg:$_\n";
				}
			}
		}
		if( scalar (@valid_files)){
			$files =~ s/^\/view\/RES.+\.vob\.ios//sm;
			$bug_info{$id}{$date}{'FILES_MODIFIED'} = [@valid_files] ;
			foreach(@valid_files){
				print FHW "$id:#$c:$engg:FILE:$_\n";
				$_ =~ s/@@.+$//;
				print FH_FILES "$id:$engg:$_\n";
			}
		}
	}

}
close(FHW);
close(FH_FILES);
close(FH_COMP);
print "[INFO]    : Complete Logs written to FILe - $bug_details\n";
print "[INFO]    : FILes Associated with bugs - $bug_files\n";
print "[INFO]    : Components Associated with bugs - $bug_comp\n";