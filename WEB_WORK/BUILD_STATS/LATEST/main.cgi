#!/usr/local/bin//perl5.8
use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);

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


myform("BUILD ID","process_main_data.cgi","rid_no","rid number");

sub myform {
	
my ($title,$cgicall, $name, $defcomment) = @_;

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
print '<tr><td><span style="color:white; font-size: 10pt;font-weight: bold;">BRANCH NAME:&nbsp</span></td>&nbsp<td><input type="text" name="branch" /></td></tr>';
print '<tr><td><span style="color:white; font-size: 10pt;font-weight: bold;">BRANCH TYPE:&nbsp</span><td><input type="text" name="branch_type" /></td></tr>';
print '<tr><td><span style="color:white; font-size: 10pt;font-weight: bold;">START DATE:&nbsp</span></td>&nbsp<td><input type="text" name="start_date" id="txtFrom" /></td></tr>';
print '<tr><td><span style="color:white; font-size: 10pt;font-weight: bold;">END DATE:&nbsp</span></td>&nbsp<td><input type="text" name="end_date" id="txtTo" /></td></tr>';
print '</table>';
print '
<br>
<div style="text-align: center;">
<button type="submit" class="myButton">GO</button>
</div>
';

print end_form; 

}
print $cgi->end_html();

