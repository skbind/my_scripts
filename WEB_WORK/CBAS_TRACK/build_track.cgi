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


&_get_data();
my @data;
sub _get_data{
	my $run_querry = qq{SELECT * FROM RUN_STATUS ORDER BY RUN_TIME DESC LIMIT 5 };
	my $sth_run = $dbh_sqlite->prepare($run_querry);
	$sth_run->execute();
	while( my @row = $sth_run->fetchrow_array) {
		push @data,[@row];
	}
	$sth_run->finish() or die $DBI::errstr;
}

print '<div id="nav">';
print <<ALL;
<table id='table1'  border=0 cellpadding=5 cellspacing=2 width='100%' style='cell-decoration:none' bgcolor='white'>\n<tr>
ALL
print "<th bgcolor='#808080'>RUN NO</th>\n";
print "<th bgcolor='#808080'>RUN TIME</th>\n";
print "<th bgcolor='#808080'>BUILD COUNT</th>\n";

my @eachrow;
foreach my $data (@data) {
    my @eachrow = @$data;
    print "<tr>\n";
    my $color = 0 ;
    foreach my $row (@eachrow) {    ####CC9933
        $color++;
        if($color >= 10 && $color <= 12){ ##999966
         print "<td bgcolor=#C0C0C0 align=center>$row</td>\n";
        }else{
        	print "<td bgcolor=#E6E6FA align=center>$row</td>\n";
        }
    }
    print "</tr>\n";
}
print "</table>\n";

print '</div>';

print <<SECTION

<div id="section">
<h2>Builds Running For You</h2>
<p>
data yet to publish...
</p>
<p>
please wait. 
</p>
</div>
SECTION
;

=pod
print <<FOOTER
<div id="footer">
Copyright © cisco.com
</div>
FOOTER
;

=cut

print $cgi->end_html();

=pod
 Dumper(\@data);
sub func {
    print $cgi->start_table();
    print $cgi->Tr($cgi->th({colspan => 1},['Integrator','RnD','RID','CL','Source']));   
    my @arr = (1..5);
    #print $cgi->Tr(@data);
    print $cgi->end_table();
}
=cut
#======================================

