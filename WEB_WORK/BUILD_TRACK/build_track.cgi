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


=pod
<body background="image/Cisco_Header.png">
<div id="header">
<div id="synopsys_logo"></div>
<div id="header_text">Auto Integration RID Status Tracking</div>
</div>
=cut


print '<div id="header">
<div id="cisco_logo"></div>
<div id="header_text">CBAS BUILD TRACKING</div>
</div>'; 
print '<br><br><br>';
print '<style> body {opacity:0;}; </style>';
print '<script>$(function() { $( "#tabs" ).tabs();});
window.onload = function() {setTimeout(function(){document.body.style.opacity="100";},500);};
</script>';

print <<TAB

<div id="tabs">
  <ul>
    <li><a href="#tabs-1">Run Status</a></li>
    <li><a href="#tabs-2">Builds Running</a></li>
    <li><a href="#tabs-3">Release Details</a></li>
  </ul>
TAB
;

print '<div id="tabs-1">';
  &_get_data();
    &_table3();

print '</div>
  <div id="tabs-2">';
    &_get_build_data();
    &_table4();
    
print <<REST    
  </div>
  <div id="tabs-3">
  	<p>Data 3# Comming Soon !</p>
    </div>
</div>

REST
;

my @data;
sub _get_data{
	my $run_querry = qq{SELECT * FROM RUN_STATUS ORDER BY RUN_NO DESC LIMIT 10 };
	my $sth_run = $dbh_sqlite->prepare($run_querry);
	$sth_run->execute();
	while( my @row = $sth_run->fetchrow_array) {
		push @data,[@row];
	}
	$sth_run->finish() or die $DBI::errstr;
}


my @build_data;
sub _get_build_data{
	my $run_querry = qq{SELECT ID,REQUEST_TYPE,BRANCH_NAME,BUILD_SERVER,BUILD_DIR,LOGDIR,TOTAL_IMAGE,BUILT_IMAGE,FAILED_IMAGE FROM BUILD_DETAILS_NEW ORDER BY ID };
	my $sth_run = $dbh_sqlite->prepare($run_querry);
	$sth_run->execute();
	while( my @row = $sth_run->fetchrow_array) {
		push @build_data,[@row];
	}
	$sth_run->finish() or die $DBI::errstr;
}



sub _table1{
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
}

sub _build_details{
 
    print $cgi->start_div({class=>"datatablediv_cisco"});
    print $cgi->start_table({class=>"datatable_cisco"});
    print $cgi->Tr($cgi->th({colspan => 1},['Integrator','Count']));
    print $cgi->Tr($cgi->td({colspan => 1},['Sandeep','1']));
    print $cgi->Tr($cgi->td({colspan => 1},['Ramesh','2']));
    print $cgi->end_table();
    print $cgi->end_div();
 
}


sub _table3{
	
	print $cgi->start_div({class=>"datatablediv_cisco"});
    print $cgi->start_table({class=>"datatable_cisco"});
    print $cgi->Tr($cgi->th({colspan => 1},['RUN NO','RUN TIME','BUILDS RUNNING']));
	
	my @eachrow;
	foreach my $data (@data) {
	    my @eachrow = @$data;
	    print $cgi->Tr($cgi->td({colspan => 1},[@eachrow]));
	}

    print $cgi->end_table();
    print $cgi->end_div();
	
}

sub _table4{
	
	print $cgi->start_div({class=>"datatablediv_cisco2"});
    print $cgi->start_table({class=>"datatable_cisco2"});
    print $cgi->Tr($cgi->th({colspan => 1},['ID','TYPE','BRANCH','SERVER','BUILD DIR','LOG DIR','TOTAL IMG','BUILT IMG','FAILED IMG']));
   # 'ID','SEQ','LABEL_NAME','LOGDIR','BUILD_LOG','TOTAL_IMAGE','BUILT_IMAGE','FAILED_IMAGE'
	
	my @eachrow;
	foreach my $data (@build_data) {
	    my @eachrow = @$data;
	    print $cgi->Tr($cgi->td({colspan => 1},[@eachrow]));
	}

    print $cgi->end_table();
    print $cgi->end_div();
	
}

print $cgi->end_html();

