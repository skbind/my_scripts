#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);
use Time::localtime;
use DBI;
use Data::Dumper;

$|=1;

my $cgi = CGI->new();

print $cgi->header();
print $cgi->start_html();

myform("BUILD ID","request.cgi","rid_no","rid number");

sub myform {
	
my ($title,$cgicall, $name, $defcomment) = @_;

print "<b>&nbsp&nbsp$title</b>";
print '<form method="post" action="'. $cgicall .'" target="data" style="font-size: 9pt; color: #202020 ; font-family: Verdana">';
print "&nbsp&nbsp";
print '<TEXTAREA NAME=rid_no ; STYLE="color: #000000; background-color: #FFF8DC;" cols="11" rows="12"></TEXTAREA>';
print '<table width="10%" border="0">';
print '<tr><td width="10%"><button type="reset"> <img src="image/reset.gif" alt="" width="45" height="25" /> </button></td><td width="10%"><input type="image" src="image/go.png" alt="Submit" width="32" height="32"></td></tr>';
print '</table>';
print "&nbsp&nbsp";
print "&nbsp&nbsp";
print end_form; 

}
print $cgi->end_html();

