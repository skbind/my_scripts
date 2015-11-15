#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
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
$db->{LongReadLen} = 66000;
$db->{LongTruncOk} = 1;

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


my @r_data;
foreach my $id  (@rid){
	chop $id if($id !~ /\d$/);
	my $query =  qq{select REQUEST_ID,BUILD_SEQ_NUM,SUBMITTER,BUILD_SERVER,BRANCH_NAME,REQUEST_TYPE,IMAGE_LIST,NUM_IMAGE_LIST,IMAGE_LIST_BUILT,NUM_IMAGE_LIST_BUILT,IMAGE_LIST_FAILED,NUM_IMAGE_LIST_FAILED,BUGIDS,REQUEST_DESC,START_TIME,END_TIME,BUILD_DIR,LOGDIR,LABEL_NAME,RELEASE_NUM,MAJOR_VERSION,TECH_TRAIN,VOB_NAME,PROXY_LIST,FREEZE_TIME,BUILD_TIME_IN_HOURS,PREV_LABEL_NAME from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where BUILD_SEQ_NUM = ( select max(BUILD_SEQ_NUM) from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW where REQUEST_ID = '$id' ) and REQUEST_ID = '$id' };
 	my $sth = $db->prepare($query) or die $DBI::errstr;
 	$sth->execute() or die $DBI::errstr;
	#$result_set{$id} =  $sth->fetchrow_hashref();
	my $rest_details;
	while( my @row = $sth->fetchrow_array) {
		my @rest_data =  splice(@row,13); # change here if flields added/removed
		foreach (@rest_data){
			$_||= 'NO ENTRY IN DB';
			$rest_details .= $_.'~'; 
		}
		chop $rest_details if ($rest_details =~/~$/);
		push @row,$rest_details;		
		push @r_data,[@row];

	}
}

#==================================

print '<div id="mytable">';
print <<ALL;
<table id='table1'  border=0 cellpadding=5 cellspacing=2 width='100%' style='cell-decoration:none' bgcolor='white'>\n<tr>
ALL

my @header = ('ID','SEQ','SUBMITTER','SERVER','BRANCH','TYPE','TOTAL IMAGE','BUILT IMAGE','FAILED IMAGE','BUG LIST','MORE INFO');
foreach my $table_hearder (@header){
	print "<th bgcolor='#808080'>$table_hearder </th>\n";
}

#my @DATA = ( [2, 3, 1], [4, 5, 7], [2, 2, 2] );

my %failure_hash;

foreach my $data (@r_data) {
    my @eachrow = @$data;
    print "<tr>\n";
    my $count = 0;
    my ($total_images,$built_images,$failed_images);
    my $rid = $eachrow[0];
    my $server = $eachrow[3];
    foreach my  $row (@eachrow) {
    	$row = 'NOT FOUND' unless ( defined $row); 
    	my $value;
  		if($count == 6){ # Total image list
        	$total_images = $row;
        }elsif($count == 7){ # Toatal no of list
        	if($row == 0){
        		$value = "<td bgcolor=#E6E6FA align=center>$row</td>";
        	}else{
        		$value =  "<a href=\"javascript:popUp('viewimage.cgi?total_images=$total_images')\">$row</a>";
        		$value = "<td bgcolor=#E6E6FA align=center>$value</td>";
        	}
        	print "$value";
        }elsif($count == 8){
        	$built_images = $row;
        }elsif($count == 9){
        	if($row == 0){
        		$value = "<td bgcolor=#E6E6FA align=center>$row</td>";
        	}else{
        		$value =  "<a href=\"javascript:popUp('viewimage.cgi?built_images=$built_images')\">$row</a>";
        		$value = "<td bgcolor=#E6E6FA align=center>$value</td>";
        	}
        	print "$value";
        }elsif($count == 10){
        	$failed_images = $row;
        }elsif($count == 11){
        	if($row == 0){
        		$value = "<td bgcolor=#E6E6FA align=center>$row</td>";
        	}else{
        		$failure_hash{$rid} = [$server, $failed_images];
        		$value =  "<a href=\"javascript:popUp('viewimage.cgi?failed_images=$failed_images')\">$row</a>" ;
        		$value = "<td bgcolor=#E6E6FA align=center>$value</td>";
        	}
        	print "$value";
        }elsif($count == 12){
        	$value =  "<input type=\"radio\" onclick=\"javascript:popUp('viewimage.cgi?bug_list=$row')\"/>" ;        	 
        	$value = "<td bgcolor=#E6E6FA align=center>$value</td>";
        	print "$value";
        }elsif($count == 13){
        	#$value =  "<a href=\"javascript:popUp('req_details.cgi?rest_details=$row')\">Details</a>" ;
        	#$value =  "<input type=\"radio\" onclick=\"javascript:popUp('req_details.cgi?rest_details=$row')\"/>" ;
        	##$value =  "<input type=\"radio\" onclick=\"parent.frame2.href=\"more_detail.cgi\"\"/>" ;
        	#$value = "<a href=\"req_details.cgi?rest_details=$row\" target=\"frame2\"><input type=\"radio\" name=\"info\" value=\"data\">More Info</a>";
 			#**$value =  "<input type=\"radio\" onclick='document.getElementById(\"frame2\").src=\"test1.html\";'/>" ;	
        	
        	$value =  "<input type=\"radio\" onclick='document.getElementById(\"frame2\").src=\"req_details.cgi?rest_details=$row\";'/>" ;
        	
        	$value = "<td bgcolor=#E6E6FA align=center>$value</td>";
        	print "$value";
        }else{
        		$value = "<td bgcolor=#E6E6FA align=center>$row</td>";
        		print "$value";
        }
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
                            col_6: "none",
                            col_7: "none",
                            col_8: "none",
                            col_9: "none",
                            col_10: "none",                                              
                            display_all_text: "ALL",
                            sort_select: true 
                        };
    setFilterGrid( "table1",table2_Props );
//]]>
</script>';
print '</div>';

print '<br>';
print '<br>';
print '
<p>
hi sandy lets see more details on frame1 !
<a href="test1.html" target="frame2">call_test1</a>
<p>'
;
#print '<iframe src="frame2.html" name="frame2" width="100%" height="200" ></iframe>';
#onclick='parent.frame2.href="more_detail.cgi"'

#print '<iFRAME name=frame2 src="more_detail.cgi" width="100%" height="550" align=left>';
print '<iFRAME id="frame2" src="more_detail.cgi" width="100%" height="550" align=left>';

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
