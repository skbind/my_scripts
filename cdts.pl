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
#   Script  : cdts.pl
#
#   Author  : Sandeep Kumar Bind
#
#   Desc    : This script is for getting bug details.
#
###
###############################################################################################

#USES : % perl cdts.pl -b  CSCuu58139 -br v154_3_m_throttle

my $bugid = '';
#my $branch = 'v154_3_m_throttle';
my $branch;
my $help_msg;
my $file;

GetOptions(
    "b|bug:s" 	    => \$bugid,
    "branch|br:s"     => \$branch,
    "bug_list|f:s"  => \$file,
    "help|h"        => \$help_msg,
) or die " Error \n";

if ($help_msg) {
    system("/usr/cisco/bin/perldoc -t $0 ");
    exit 0;
}
unless($branch){
	print "\n please pass the branch [ -br] and [ -branch]  !!!\n For more details please see help\n";
    exit 0;
}

my @bug_id;
if($bugid && $file){
	print "\n[ -b] and [ -f] both are mutually exclusive switches !!!\n For more details please see help\n";
    exit 0;	
}elsif ( $file && -f $file) {
	open (FH,"<$file") or die "Can't open the file: $file\n";
	foreach (<FH>){
		next if ($_ =~ /^s\+$/);
		chomp;
 		push @bug_id,$_;
	}
	close(FH);
}elsif($bugid){
	#print "BUILD:$build\n";
	foreach (split(',',$bugid)){
		$_ =~ s/\s+$//;
		chomp;
		push @bug_id,$_;
	}
}else{
	print "NO bugs passed\n";
	print "Enter atleast one Bug ID to continue; Terminating! \n\n";
 	exit 1;
}
print "------------------------------------------\n\n";

my %bug_info;
my $bug_details = '/users/sabind/SCRIPTS/bug_details.log';
system (" /bin/rm -rf $bug_details") if ( -f $bug_details);
open (FHW,">$bug_details") or die "Can't open the file: $bug_details\n";

foreach my $id (@bug_id){
	
	my $cmd = "/usr/cisco/bin/dumpcr $id | egrep \"Diffs--$branch|Engineer\\s+:\" 2>/dev/null | grep -v \"File Name\" 2>/dev/null "; 
	my $output = `$cmd`;
	my @data = split("\n",$output);	
	#print " cmd = $cmd\n";
	my $eng_reviewer = shift @data ;
	$eng_reviewer =~ s/\s{2,}/,/g;
	my ($engg, $reviewers) = split (",",$eng_reviewer);
	chomp($reviewers, $engg);
	$reviewers =~ s/\w+.+:\s+//g;
	$reviewers =~ s/\s+/,/g;
	chop $reviewers if ($reviewers =~ /\,$/);
	$engg =~ s/\w+.+:\s+//g;
	#print "\nENGG = $engg\nREVIEWER = $reviewers\n";
	
	$bug_info{$id}{'ENGG'} = $engg;
	$bug_info{$id}{'REVIEWER'} = $reviewers;
	$bug_info{$id}{'NO_OF_COMMITS'} = scalar (@data);
	
	my $no_of_commits = scalar (@data);
	my @date = @data;
	map { $_ =~ s/\s\s.*// } @data;	
	map { $_ =~ s/^Diff.+cva\s+// } @date;
	
	#print "TOTAL COMMITS INTO $branch BY $id : $no_of_commits\n";
	
	if($no_of_commits > 1){
		my $c =0;
		foreach ( @date){
			$c++;
			#print " $c. Commit Date : $_\n"; 
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
			print "\n web link can not access\n";
			exit;
		}else{
			#print "\n web link Accessed sucessfully\n";
		}
	    my $discription = $2 if ($mech->response->content =~ /^(begin\slog\-entry)(.*)(end\slog\-entry)/sm);
	    #my $discription = $2 if ($var =~ /^(begin\slog\-entry)(.*)(end\slog\-entry)/sm);
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
			#my $components = $2 if ($var =~ /(Begin publication manifest diff.+Updated:\s*\n\s+)(.+)(\n#### End publication manifest diff)/sm);
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
				}
			}
		}
		if( scalar (@valid_files)){
			$files =~ s/^\/view\/RES.+\.vob\.ios//sm;
			$bug_info{$id}{$date}{'FILES_MODIFIED'} = [@valid_files] ;
			foreach(@valid_files){
				print FHW "$id:#$c:$engg:FILE:$_\n";
			}
		}
	}

}
close(FHW);
print "===================================================\n";
print Dumper(\%bug_info);
print "===================================================\n";

print "\n LOGS written to FILe - $bug_details\n";
#print "output = $output\n lines0 = $lines[0] \n lines1 = $lines[1]  \n lines2 = $lines[2]\n";
my $var ;

$var = <<END_MESSAGE
begin log-entry
 Subject: /vob/ios (branch v154_3_m_throttle) Source Repository Modification
 rkalluri    2015/06/18 05:23:17 UTC CSCus67718	2015/06/17 22:23:17 local
 
 Comment  :
	Bug ID used: CSCus67718 FTP Client fails to get connection closed by
	remote host with BtB NAT HA 
	
Elements :
	/view/RES-v154_3_m_throttle.vob.ios/vob/ios.sys1/sys/ip/ipnat_fixup.c@@/main/t_base_3/t_base_4/v154_3_m_throttle/1
	/view/RES-v150_1_sy_throttle.vob.ios/vob/ios/sys/entity/entity_api.c@@/main/florida/flo_isp/const2/pp_port/rainier/sierra/carson/mtrose/v150_1_sy_throttle/1
	/view/RES-v155_1_t_throttle.vob.ios/vob/ios/.publication_manifest@@/main/t_base_3/t_base_4/t_base_5/v155_1_t_throttle/159

 
end log-entry

Index: .publication_manifest 
# OID /vob/ios/.publication_manifest;5dc47406.1df711d8.8631.00:01:80:7a:46:12

#### Begin publication manifest diff ####
Original manifest: /view/RES-v154_3_m_throttle.vob.ios/vob/ios/.publication_manifest@@/main/t_base_3/t_base_4/v154_3_m_throttle/289
New manifest: /view/RES-v154_3_m_throttle.vob.ios/vob/ios/.publication_manifest@@/main/t_base_3/t_base_4/v154_3_m_throttle/290
Updated:
	uc_infra@(rls8)1.3.42 replaced uc_infra@(rls8)1.3.41
	uc_fir@(rls9)1.7.1 replaced uc_fir@(rls9)1.2.0
#### End publication manifest diff ####;
END_MESSAGE
;

#print "\n $var\n"; 