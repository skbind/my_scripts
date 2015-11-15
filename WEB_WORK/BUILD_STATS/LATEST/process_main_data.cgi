#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;
use lib "/usr/cisco/packages/dbdoracle/9.2.0";
$ENV{'ORACLE_HOME'} = '/usr/cisco/packages/dbdoracle/9.2.0';

$|=1;

my $cgi = CGI->new();

my $data_source = 'dbi:Oracle:host=sjc-dbpl-bld.cisco.com;sid=PBAS;port=1521';
my $user = "IRE_CLIENT";
my $pass = "IRE_369";

my $db_cbas = DBI->connect($data_source, $user, $pass, { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;
$db_cbas->{LongReadLen} = 66000;
$db_cbas->{LongTruncOk} = 1;

my $dsn = 'DBI:SQLite:dbname=/auto/web-cosi/dev/cgi-bin/cbas_build';
my $dbh_sqlite = DBI->connect( $dsn, "", "", { RaiseError => 1, AutoCommit => 1 } ) or die $!;

my %form_data;
foreach my $p (param()) {
    $form_data{$p} = param($p);
}

my %all_inputs = (
	'start_date' => 'START DATE',
	'end_date' => 'END DATE',
	'branch' => 'BRANCH NAME',
	'branch_type' => 'BRANCH TYPE',
);

my $error_msg;
my $prams_count_err = 0;

foreach my $pram ( keys %form_data){
	my $val1 = $form_data{$pram};
	unless ( $form_data{$pram} ){
		$error_msg .= "Please pass [$all_inputs{$pram}]<br>";
		$prams_count_err++;
	}
}
if($prams_count_err > 0){
	$error_msg .= "$prams_count_err input needed.<br>";
	&_print_msg("$error_msg");
	exit(0);
}

&_print_msg("proceed further");

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
	#print Dumper(\%form_data);
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