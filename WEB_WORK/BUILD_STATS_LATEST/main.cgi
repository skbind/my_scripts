#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);
use Time::localtime;
use DBI;
use Date::Calc qw/Delta_DHMS/;
use Date::Calc qw/Delta_Days/;
use Data::Dumper;


#9999CC selected blue
my $cgi = CGI->new();

    print $cgi->header();
    print $cgi->start_html(
                        -bgcolor => "#9999CC",
                         -style => [{'src' => [
                                                'style/button.css',
                                                'style/metrics.css',
                                                 ]
                                    }], 
                       );
    print'
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.6/jquery.min.js" type="text/javascript"></script>
    <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"
            type="text/javascript"></script>
    <link href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/start/jquery-ui.css"
          rel="Stylesheet" type="text/css" />
    <script type="text/javascript">
        $(function () {
            $("#txtFrom").datepicker({
                numberOfMonths: 1,
                onSelect: function (selected) {
                    var dt = new Date(selected);
                    dt.setDate(dt.getDate() + 1);
                    $("#txtTo").datepicker("option", "minDate", dt);
                }
            });
            $("#txtTo").datepicker({
                numberOfMonths: 1,
                onSelect: function (selected) {
                    var dt = new Date(selected);
                    dt.setDate(dt.getDate() - 1);
                    $("#txtFrom").datepicker("option", "maxDate", dt);
                }
            });
        });
    </script>
'
;


myform("BUILD ID","get_data.cgi","rid_no","rid number");

sub myform {
	
my ($title,$cgicall, $name, $defcomment) = @_;

#print "<b>&nbsp&nbsp$title</b>";
print '<form method="post" action="'. $cgicall .'" target="data" style="font-size: 9pt; color: #202020 ; font-family: Verdana">';
print '<div style="text-align: center;">';
print '<span style="color:white;font-size: 12pt;font-weight: bold;">GET IOS BUILD DETAILS</span></div>'; 
print '
	    <style type="text/css">
        body {
            font-family: Arial;
            font-size: 8pt;
        }
    </style>
    <table border="0" cellpadding="0" cellspacing="10">
';
#<h2><span style="color:white; font-size: 12pt">END DATE:&nbsp</span></h2>
# ORG : print '<tr><td><h2><span style="color:white; font-size: 10pt">BUILD ID:&nbsp</span></h2><td><input type="text" name="rid_no" /></td></tr><tr><td>&nbsp</td><td>&nbsp</td></tr>';
print '<tr><td><span style="color:white; font-size: 10pt;font-weight: bold;">BUILD ID:&nbsp</span><td><input type="text" name="rid_no" /></td></tr>';
print '<tr><td><span style="color:white; font-size: 10pt;font-weight: bold;">BRANCH NAME:&nbsp</span></td>&nbsp<td><input type="text" name="br_no" /></td></tr>';
print '<tr><td><span style="color:white; font-size: 10pt;font-weight: bold;">START DATE:&nbsp</span></td>&nbsp<td><input type="text" id="txtFrom" /></td></tr>';
print '<tr><td><span style="color:white; font-size: 10pt;font-weight: bold;">END DATE:&nbsp</span></td>&nbsp<td><input type="text" id="txtTo" /></td></tr>';
#*print '<tr><td>&nbsp</td><td>&nbsp</td><td><button type="submit" class="myButton">GO</button></td></tr>';
#print '<tr><td>&nbsp</td><td>&nbsp</td><td> <button type="submit"><a href="#" class="myButton">GO</a></button></td></tr>';
#print '<tr><td><a href="#" class="myButton" role="submit">GO</a></td></tr>';
#print '<tr><td><button type="reset"><a href="#" class="myButton">RESET</a></td><td>&nbsp</td><td><button type="submit"><a href="#" class="myButton">GO</a></td></tr>';
#print '<tr></td>&nbsp<td><td><button type="reset"> <img src="image/reset.gif" alt="" width="45" height="25" /> </button></td></td>&nbsp<td><td><input type="image" src="image/go.png" alt="Submit" width="32" height="32"></td></tr>';
print '</table>';
#print '<button type="submit" class="myButton">GO</button>';

=pod
print '
<div id="bottommargin">
<table border=0 width="100%" cellpadding=0 cellspacing=1>
<tr><td>&nbsp</td><td>&nbsp</td><td><button type="submit" class="myButton">GO</button></td></tr>
</table>
</div>
';
=cut

print '
<br>
<div style="text-align: center;">
<button type="submit" class="myButton">GO</button>
</div>
';

print end_form; 

}

#print '<button type="reset"><a href="#" class="myButton">RESET1</a><button type="submit"><a href="#" class="myButton">GO1</a>';

	print $cgi->end_html();

