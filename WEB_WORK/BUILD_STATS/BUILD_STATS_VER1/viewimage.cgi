#!/usr/local/bin//perl5.8

use warnings;
use strict;
use CGI qw(:standard);
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use Data::Dumper;

$|=1;

my $cgi = CGI->new();
my $prams;

if($cgi->param('built_images')){
	$prams = $cgi->param('built_images');
}elsif($cgi->param('total_images')){
	$prams = $cgi->param('total_images');
}
elsif($cgi->param('failed_images')){
	$prams = $cgi->param('failed_images');
}elsif($cgi->param('bug_list')){
	$prams = $cgi->param('bug_list');
}

print $cgi->header();
print $cgi->start_html(
                          -script => [
                                     {   -type =>'text/javascript',
                                          -src =>'js/popup.js'
                                     },
                                ],  
                       );

print "Dear user welcome to the CBAS status page* !!!<br><br>";
if($prams){
	my @values = split(',',$prams);
	my $count = 0;
	foreach (@values){
		chomp;
		$count++;
		$_ =  "<a href=\"javascript:popUp('failure_log.cgi?log=$_')\">$_</a>" if($cgi->param('failed_images'));
		$_ =  "<a href=\"javascript:popUp('bug.cgi?log=$_')\">$_</a>" if($cgi->param('bug_list'));
		
		#$_ =  "<a href=cdetsweb-prd.cisco.com/apps/dumpcr_att?identifier=CSCuu93699&title=Diffs--v155_1_t_throttle&type=FILE&displaytype=html>$_</a>";
		
		print "$count. $_<br>";
	}	
}
print $cgi->end_html();

