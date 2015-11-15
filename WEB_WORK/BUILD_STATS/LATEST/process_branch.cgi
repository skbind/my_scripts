#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;

my $dsn = 'DBI:SQLite:dbname=/auto/web-cosi/dev/cgi-bin/cbas_build';
my $dbh_sqlite = DBI->connect( $dsn, "", "", { RaiseError => 1, AutoCommit => 1 } ) or die $!;
$|=1;

my $cgi = CGI->new();
my $msg = '';
my $branch = $cgi->param("branch_name") || "none";
$branch =~ s/\n//g;
$branch =~ s/\s+//g;

if ($branch =~ /^none$/) {
    $msg .= "<h4><font color=" . "red"
      . ">Ooops!!! No Branch Have Been Passed.<font color=" . "red" . "><h4>";
    $msg .= "<h4><font color=" . "red"
      . ">Please Pass Branch To Be Added.<font color=" . "red"
      . "><h4>\n";
	&_print_msg($msg);
    exit 0;
}elsif( $branch !~ /^[a-z0-9_]+[a-z0-9_]$/ ){
	# this section should have to validate the branch.
    $msg .= "<h4><font color=" . "red"
    . ">Ooops!!! Entered build ID is not correct|| req_id = ##$branch##.<font color=" . "red" . "><h4>";
    $msg .= "<h4><font color=" . "red"
      . ">Please Enter Correct ID<font color=" . "red"
      . "><h4>\n";    
    &_print_msg($msg);
    exit 0;
}else{
		my $valid = &_valid_branch($branch);
		if($valid){
			$msg .= " Its a valid branch:$branch, proceeding to add return = $valid<br>";
			eval {
				# To check branch already present.
				my $sql_insert = qq{ SELECT EXISTS(SELECT 1 FROM TRACK_BRANCH_NEW WHERE BRANCH_NAME = '$branch')};
				my $sth_insert = $dbh_sqlite->prepare($sql_insert);
				$sth_insert->execute() or die "Can't execute SQL statement: $DBI::errstr";
				my $ret = $sth_insert->fetchrow_array();
				$sth_insert->finish() or die $DBI::errstr;
				if($ret){
					$msg .= "Branch:$branch already present in track list , ret = $ret<br>";
					&_print_msg($msg);
				}else{
					# Branch already not present, so need to be added.
					$msg .= "Branch:$branch not present in track list , neeed to be added. ret = $ret<br>";			
					eval {
						$sql_insert = qq{ INSERT OR IGNORE INTO TRACK_BRANCH_NEW(BRANCH_NAME) VALUES ('$branch')};
						$sth_insert = $dbh_sqlite->prepare($sql_insert);
						$sth_insert->execute() or die "Can't execute SQL statement: $DBI::errstr";
						$ret = $sth_insert->finish() or die $DBI::errstr;
						$msg .= "Successfully added the branch = $branch<br>";
						&_print_msg($msg);
				
					};
					if($@ ){		
						$msg = "Failed to add, branch = $branch<br>";
						&_print_msg($msg);
					}
				}			
			}; # End of first eval.
			if($@ ){		
				my $msg = "Failed \$@ = $@ , branch = $branch<br>";
				&_print_msg($msg);
			}
		}else{
			$msg = "Entered branch is not a valid branch<br> If it is newly created branch, It will take 12 hr to reflect in Database<br>";
			&_print_msg($msg);
		}
		
}

sub _print_msg{
	my ($msg) = @_;
	print $cgi->header();
	print $cgi->start_html(
	                          
							-style => [{'src' => [
	                             					'style/metrics.css'
	                         					 ]
	               					   }],   
	                       );
	print "$msg";
	print $cgi->end_html();
	
}

sub _valid_branch{
	my ($branch) = @_;
	# TRACK_BRANCH = valid branch list.
	my $sql_insert = qq{ SELECT EXISTS(SELECT 1 FROM TRACK_BRANCH WHERE BRANCH_NAME = '$branch')};
	my $sth_insert = $dbh_sqlite->prepare($sql_insert);
	$sth_insert->execute() or die "Can't execute SQL statement: $DBI::errstr";
	my $ret = $sth_insert->fetchrow_array();
	$sth_insert->finish() or die $DBI::errstr;
	return $ret;

}