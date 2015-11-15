#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);

$|=1;

my $cgi = CGI->new();
my $images;

if($cgi->param('built_images')){
	$images = $cgi->param('built_images');
}elsif($cgi->param('total_images')){
	$images = $cgi->param('total_images');
}
elsif($cgi->param('failed_images')){
	$images = $cgi->param('failed_images');
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
if($images){
	my @images = split(',',$images);
	my $count = 0;
	foreach (@images){
		chomp;
		$count++;
		$_ =  "<a href=\"javascript:popUp('failure_log.cgi?log=$_')\">$_</a>" if($cgi->param('total_images'));
		print "$count. $_<br>";
	}	
}
print $cgi->end_html();

