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

my $dsn = 'DBI:SQLite:dbname=/auto/web-cosi/dev/cgi-bin/CBAS_TRACK/cbas_build';
my $dbh_sqlite = DBI->connect( $dsn, "", "", { RaiseError => 1, AutoCommit => 1 } ) or die $!;

$|=1;

my $cgi = CGI->new();

    print $cgi->header();
    print $cgi->start_html();
    print "hello";
    print'
    <body>
    <table border="0" cellpadding="0" cellspacing="0">
        <tr>
            <td>
                From:
            </td>
            <td>
                <input type="text" id="txtFrom" />
            </td>
            <td>
                &nbsp;
            </td>
            <td>
                To:
            </td>
            <td>
                <input type="text" id="txtTo" />
            </td>
        </tr>
    </table>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.6/jquery.min.js" type="text/javascript"></script>
    <script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/jquery-ui.min.js"
            type="text/javascript"></script>
    <link href="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8/themes/start/jquery-ui.css"
          rel="Stylesheet" type="text/css" />
    <script type="text/javascript">
        $(function () {
            $("#txtFrom").datepicker({
                numberOfMonths: 2,
                onSelect: function (selected) {
                    var dt = new Date(selected);
                    dt.setDate(dt.getDate() + 1);
                    $("#txtTo").datepicker("option", "minDate", dt);
                }
            });
            $("#txtTo").datepicker({
                numberOfMonths: 2,
                onSelect: function (selected) {
                    var dt = new Date(selected);
                    dt.setDate(dt.getDate() - 1);
                    $("#txtFrom").datepicker("option", "maxDate", dt);
                }
            });
        });
    </script>
</body>'
;

	print $cgi->end_html();

