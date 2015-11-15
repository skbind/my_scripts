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
    print $cgi->start_html(
              -title => 'Run Report',
              -script => [
                            { -type => 'text/javascript',
                              -src  => 'js/jquery-1.8.3.js'
                             }
                          ],
              style => [
              				{'src' => ['css/ui.css']
                            }
                       ],
                   );
                   

print <<HEADER
<div id="header">
<h1>CBAS BUILD TRACKER</h1>
</div>
HEADER
;
print $cgi->end_html();

=pod

my $q = CGI->new;
print $q->header;

print "<html><head><title>BUILD Status Tracking</title>\n";


print '<STYLE TYPE="text/css">
<!--
TD{font-family: Verdana; font-size: 8pt;}
TH{font-family: Verdana; font-size: 8pt;}
.class1 A:link {text-decoration: none; color: blue;}
.class1 A:visited {text-decoration: none; color: blue;}
.class1 A:active {text-decoration: none; color: black;}
.class1 A:hover {text-decoration: underline; color: red;}
.class2 A:link {text-decoration: none; color: black;}
.class2 A:visited {text-decoration: none; color: black;}
.class2 A:active {text-decoration: none; color: black;}
.class2 A:hover {text-decoration: underline; font-weight:bold; color: black;}
td.locked{
left: expression(parentNode.parentNode.parentNode.parentNode.scrollLeft);
position: relative;
z-index: 10;
}
--->
</STYLE>
<link rel="stylesheet" type="text/css" href="css/build_status.css"/>
</STYLE><link rel="stylesheet" type="text/css" href="css/build_status.css"/>
';
print "</head>\n";

print '
<body background="image/B3.jpg">
<div id="header">
<div id="cisco_logo"></div>
<div id="header_text">Build Status Tracking</div>
</div>
<div id="topmargin">

<table border=1 width="100%" cellpadding=0 cellspacing=0>
	<td><iFRAME name=top2 src="initial.cgi?type=rid" width="100%" height="350" ></iframe></td>
	</tr>
	<tr><td colspan=3 width="100%"><iFRAME name=data src="blank.cgi" width="100%" height="550" align=left></iframe></td></tr>
</table>
</div>

=cut
print '

</body>
</html>
';
