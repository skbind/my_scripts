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
                        -title => 'Cbas Report',
                        -script => [
                                     { -type => 'text/javascript',
                                          -src  => '//code.jquery.com/jquery-1.10.2.js'
                                     },
                                     { -type => 'text/javascript',
                                          -src  => '//code.jquery.com/ui/1.11.4/jquery-ui.js'
                                     },
                                ],
                          style => [{'src' => [
                                                '/resources/demos/style.css',
                                                'style/metrics.css',
                                                '//code.jquery.com/ui/1.11.4/themes/smoothness/jquery-ui.css' ]
                                    }],
                                    
                       );



print '<div id="header">
<div id="cisco_logo"></div>
<div id="header_text">IOS BUILD STATS</div>
</div>';

print '
<div id="topmargin">
<table border=0 width="100%" cellpadding=0 cellspacing=1>
	<td><iFRAME name=top1 src="main.cgi?type=rid" frameborder="0" scrolling="no" width="100%" height="250" ></iframe></td>
	<td><iFRAME name=top2 src="add_branch.cgi?type=rid" frameborder="0" scrolling="no" width="100%" height="250" ></iframe></td>
	<td><iFRAME name=top3 src="clock.cgi" frameborder="0" scrolling="no" width="100%" height="250" ></iframe></td>
	</tr>
</table>
</div>
'
;
print '<br>
<iFRAME name=data src="data.cgi" frameborder="0" scrolling="no" width="100%" height="550" align=left></iframe>
'
;
print $cgi->end_html();

