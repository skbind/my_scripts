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

#FFCC99 light red

my $cgi = CGI->new();

    print $cgi->header();
                       
    print $cgi->start_html(
                        -bgcolor => "#9999CC",
                        -style => [{'src' => [
                                                'style/button.css'
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


_myform("BUILD ID","process_branch.cgi","branch_name","branch name");

sub _myform {
	
my ($title,$cgicall, $name, $defcomment) = @_;

# name is directly used in table row as - branch_name

print '<form method="post" action="'. $cgicall .'" target="data" style="font-size: 9pt; color: #202020 ; font-family: Verdana">';
print '<div style="text-align: center;">';
print '<span style="color:white;font-size: 12pt;font-weight: bold;">ADD NEW BRANCH</span></div>'; 
print '
    <table border="0" cellpadding="0" cellspacing="7">
';
print '<tr><td><span style="color:white; font-size: 10pt;font-weight: bold;">BRANCH NAME:&nbsp</span></td>&nbsp<td><input type="text" name="branch_name" /></td></tr><tr><td>&nbsp</td><td>&nbsp</td></tr>';
print '</table>';
print "<br><br><br><br><br>";

print '
<br>
<div style="text-align: center;">
<button type="submit" class="myButton">UPDATE</button>
</div>
';

print end_form; 

}

print $cgi->end_html();

