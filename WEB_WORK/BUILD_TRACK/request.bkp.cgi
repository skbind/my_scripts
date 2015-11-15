#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);
use DBI;
use lib "/usr/cisco/packages/dbdoracle/9.2.0";
$ENV{'ORACLE_HOME'} = '/usr/cisco/packages/dbdoracle/9.2.0';

$|=1;

my $cgi = CGI->new();
my $req_id = $cgi->param("rid_no") || "none";
my @rid;
my $validate_data = $req_id;
$validate_data =~ s/\n//g;
$validate_data =~ s/\s+//g;

if ($validate_data =~ /^none$/) {
    print $cgi->header;
    print "<html><head><title>Error Page</title>\n";
    print "</head>\n";
    print "<body>\n";
    print "<h4><font color=" . "red"
      . ">Ooops!!! No build ID passed || req_id = $validate_data.<font color=" . "red" . "><h4>";
    print "<h4><font color=" . "red"
      . ">Please Enter Correct ID<font color=" . "red"
      . "><h4>\n";
    print "</body>\n";
    print "</html>\n";
    exit 0;
}elsif( $validate_data =~ /\D+/ ){
	print $cgi->header;
    print "<html><head><title>Error Page</title>\n";
    print "</head>\n";
    print "<body>\n";
    print "<h4><font color=" . "red"
    . ">Ooops!!! Entered build ID is not correct|| req_id = ##$validate_data##.<font color=" . "red" . "><h4>";
    print "<h4><font color=" . "red"
      . ">Please Enter Correct ID<font color=" . "red"
      . "><h4>\n";
    print "</body>\n";
    print "</html>\n";
    exit 0;
}else{
	@rid = split("\n",$req_id);

=pod
	my $count = scalar (@rid);
	print $cgi->header;
    print "<html><head><title>Error Page</title>\n";
    print "</head>\n";
    print "<body>\n";
    print "<h4><font color=" . "green"
    . ">Entered data = @rid, array count = $count.<font color=";
    print "</body>\n";
    print "</html>\n";
    exit 0;
=cut	
}


my $data_source = 'dbi:Oracle:host=sjc-dbpl-bld.cisco.com;sid=PBAS;port=1521';
my $user = "IRE_CLIENT";
my $pass = "IRE_369";

my $db = DBI->connect($data_source, $user, $pass, { RaiseError => 1, AutoCommit => 0 }) or die $DBI::errstr;

print $cgi->header();

print $cgi->start_html(
                          -script => [
                                     { -type => 'text/javascript',
                                          -src  => 'js/tablefilter_all_min.js'
                                     },
                                     {   -type =>'text/javascript',
                                          -src =>'js/popup.js'
                                     },
                                ],
                          
                          style => [{'src' => [
                                                'style/metrics.css'
                                                 ]
                                    }],   
                       );

#my %result_set;
#@rid = ('6492709','6536310');
my @r_data;
foreach my $id  (@rid){
	chop $id if($id !~ /\d$/);
	my $query =  qq{select REQUEST_ID,BUILD_SEQ_NUM,BUILD_SERVER,BRANCH_NAME,REQUEST_TYPE,START_TIME,END_TIME,BUILD_DIR,LOGDIR,LABEL_NAME,NUM_IMAGE_LIST,NUM_IMAGE_LIST_BUILT,NUM_IMAGE_LIST_FAILED,IMAGE_LIST,IMAGE_LIST_BUILT,IMAGE_LIST_FAILED from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where BUILD_SEQ_NUM = ( select max(BUILD_SEQ_NUM) from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where REQUEST_ID = '$id' ) and REQUEST_ID = '$id' };
 	my $sth = $db->prepare($query) or die $DBI::errstr;
 	$sth->execute() or die $DBI::errstr;
	#$result_set{$id} =  $sth->fetchrow_hashref();
	while( my @row = $sth->fetchrow_array) {
		push @r_data,[@row];
	}
}
#print Dumper(\@r_data);
=pod
foreach my $id_data (keys %result_set){	
	while (my ($key, $value) = each ( %{$result_set{$id_data}}))
	{
	  $value = $result_set{$id_data}{$key};
	  print "  $key ===> $value<br>";
	}
	
}

=cut

#&_table4();

#==================================

print '<div id="mytable">';
print <<ALL;
<table id='table1'  border=0 cellpadding=5 cellspacing=2 width='100%' style='cell-decoration:none' bgcolor='white'>\n<tr>
ALL

my @header = ('ID','SEQ','SERVER','BRANCH','TYPE','START TIME','END TIME','BUILD DIR','LOG DIR','LABEL_NAME','TOTAL IMAGE','BUILT IMAGE','FAILED IMAGE');
foreach my $table_hearder (@header){
	print "<th bgcolor='#808080'>$table_hearder </th>\n";
}

#my @DATA = ( [2, 3, 1], [4, 5, 7], [2, 2, 2] );

foreach my $data (@r_data) {
    my @eachrow = @$data;
    print "<tr>\n";
    my $count = 0;
    foreach my  $row (@eachrow) {
    	$row = 'NOT DIFINED' unless ( defined $row); 
        	my $value;
        	if ($count >= 5 && $count <= 6){
        		 $value = &truncate_time($row) ;
        		 $value = "<td bgcolor=#E6E6FA align=center>$value</td>";
        	}elsif($count >= 10 && $count < 11){
        		$value = 5;
        		# <a href="http://www.w3schools.com">Visit W3Schools.com!</a> 
        		$value =  "<a href=\"javascript:popUp('viewimage.cgi?scriptids=123')\">$value</a>";
        		#$value = $cgi->a({href => "javascript:popUpWide('viewscripts.cgi?scriptids=123')"},$value.'<br>');
        		$value = "<td bgcolor=#E6E6FA align=center>$value</td>";
        	}else{
        		$value = "<td bgcolor=#E6E6FA align=center>$row</td>";
        	}
        	print "$value";
        	$count++;
    }
    print "</tr>\n";
}
print "</table>\n";
    print '<script language="javascript" type="text/javascript">
//<![CDATA[
    var table2_Props =  {
                            col_0: "multiple",
                            col_1: "multiple",
                            col_2: "multiple",
                            col_3: "multiple",
                            col_4: "multiple",
                            col_5: "multiple",
                            col_6: "multiple",
                            col_7: "none",
                            col_8: "none",
                            col_9: "none",
                            col_10: "none",
                            col_11: "none",
                            col_12: "none",                                               
                            display_all_text: "ALL",
                            sort_select: true 
                        };
    setFilterGrid( "table1",table2_Props );
//]]>
</script>';
print '</div>';
#==================================



print $cgi->end_html();


sub truncate_time{
	my ($full_time) = @_;
	my $time = $&  if ($full_time =~ /PM|AM/);
    my $last_finish  = substr $full_time, 0, 15;
    $last_finish .= ' '.$time;
    return $last_finish || 'NOT FOUND';
}

sub _table4{
	
	print $cgi->start_div({class=>"datatablediv_cisco2"});
    print $cgi->start_table({class=>"datatable_cisco2"});
    print $cgi->Tr($cgi->th({colspan => 1},['ID','SEQ','SERVER','BRANCH','TYPE','START TIME','END TIME','BUILD DIR','LOG DIR','LABEL_NAME','TOTAL IMAGE','BUILT IMAGE','FAILED IMAGE']));
   # 'ID','SEQ','LABEL_NAME','LOGDIR','BUILD_LOG','TOTAL_IMAGE','BUILT_IMAGE','FAILED_IMAGE'
	
	my @eachrow;
	foreach my $data (@r_data) {
	    my @eachrow = @$data;
	    print $cgi->Tr($cgi->td({colspan => 1},[@eachrow]));
	}

    print $cgi->end_table();
    print $cgi->end_div();
	
}
