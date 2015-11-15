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
<div id="header_text">CBAS BUILD TRACKING</div>
</div>';

print '
<div id="topmargin">
<table border=1 width="100%" cellpadding=0 cellspacing=0>
	<td><iFRAME name=top2 src="initial.cgi?type=rid" width="100%" height="300" ></iframe></td>
	</tr>
	<tr><td colspan=3 width="100%"><iFRAME name=data src="initial.cgi?type=rid" width="100%" height="350" align=left></iframe></td></tr>
	<tr><td colspan=3 width="100%"><iFRAME name=spec_data src="spec_data.cgi" width="100%" height="350" align=left></iframe></td></tr>
</table>
</div>
'
;
print $cgi->end_html();

