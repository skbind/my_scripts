#!/usr/local/bin//perl5.8

use warnings;
use strict;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use List::MoreUtils qw(each_array);
use Data::Dumper;

$|=1;

my $cgi = CGI->new();
my $rest_details;

if($cgi->param('rest_details')){
	$rest_details = $cgi->param('rest_details');
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

my @hearder = ('REQUEST DESC','START TIME','END TIME','BUILD DIR','LOG DIR','LABEL','RELEASE NUM','MAJOR VERSION','TECH TRAIN','VOB','PROXY LIST','FREEZE TIME','BUILDS TIME (IN HOURS)','PREVIOUS LABEL');

=pod
if($rest_details){
	my @details = split('~',$rest_details);
	my $count = 0;
	foreach (@details){
		chomp;
		$count++;
		#$_ =  "<a href=\"javascript:popUp('failure_log.cgi?log=$_')\">$_</a>" if($cgi->param('rest_details'));
		print "$count. $_<br>";
	}	
}

=cut

my @details;
if($rest_details){
	@details = split('~',$rest_details);	
}

if($#hearder == $#details){
	my $count = 0;
	my $it = each_array( @hearder, @details);
	while ( my ($first, $second) = $it->()) {
		chomp($first, $second);
		$count++;
		print "$count. <b>$first&nbsp:&nbsp</b> $second <br>";
	}
}else{
	print "<br><br> Error!! array count mismatch hearder = $#hearder details = $#details <br> <br>rest_details<br> = $rest_details<br>";
}
#print "<br><br>res details = $rest_details<br>";
print $cgi->end_html();

