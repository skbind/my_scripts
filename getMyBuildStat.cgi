#!/usr/cisco/bin/perl5.8 -wl

"Content-type:text/html\n\n";

$|=1;

BEGIN{

    use lib '/usr/cisco/packages/dbdoracle/9.2.0';
    $ENV{ SINGLEVIEW_LIBDIR } = '/auto/web-cosi/dev/cgi-bin';
    $ENV{ CC_LIBDIR } = ( $^O eq 'MSWin32' ) ? 't:/cctools/current/lib':'/usr/cisco/lib/atria/perl' unless( exists( $ENV{ CC_LIBDIR } ) );
    $ENV{ SYNC_LIBDIR } = '/usr/cisco/packages/synctools/current/lib' unless (exists ($ENV{ SYNC_LIBDIR }));
    $ENV{'ORACLE_HOME'} = '/usr/cisco/packages/dbdoracle/9.2.0';

}
    my $SUBMITTER_LIST = "'sdcunha', 'pallavik', 'svustipa', 'ahudatha' , 'viraneek', 'deenayak', 'radharan'";
    my $BROS_DB_USER = 'IRE_CLIENT';
    my $DB_HOST = 'sjc-dbpl-bld.cisco.com';
    my $SID = 'PBAS';
    my $LOG_DIR = '/auto/web-cosi/dev/logs/BUILD_STAT';
    my $JSON_DIR = '/auto/web-cosi/dev/html/singleview/jsonfiles/';

use lib( $ENV{ CC_LIBDIR }, $ENV{ SYNC_LIBDIR }, $ENV{'ORACLE_HOME'}, $ENV{ SINGLEVIEW_LIBDIR } );

my $user_name = $ENV{'REMOTE_USER'};

use CGI qw(:all);

use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

use DBI;
use Spreadsheet::WriteExcel;
use Data::Dumper;
use logger qw($DEFAULT $DEBUG);

my $cgi_obj = new CGI();

my $userReportJsonFile;
my $CBAS_PROD_DATA_VIEW = 'CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW';

#
# Set logging - using logger.pm
#

    my (undef, $min, $hour, $mday, $mon, $year, undef, undef, undef) = localtime();

    $mon += 1; # Because localtime returns 0..11 for month
    $year += 1900; # Because localtime returns number of years since 1900

    my $timeStamp = sprintf("%04d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min);

    my $main_trace_file_name = "$LOG_DIR".'/'."$user_name".'_get_build_time'."$timeStamp".'.log';

    my $trace_level = '2';
    #if (defined $options{trace}) {$trace_level =$options{trace};} else { $trace_level = '2';}

    our ($errorHandle, $traceInstance) = logger->new($main_trace_file_name, $trace_level);

    if ($errorHandle)
    {
        print "cannot initialise tracing ... ";
        exit (1);
    }

#
# -- DB Connection
#

$traceInstance->Trace("$DEFAULT", "Start - Logging ");
$traceInstance->Trace("$DEFAULT", "Connecting to DB " . scalar(localtime));

my $dbh = DBI->connect('dbi:Oracle:host=sjc-dbpl-bld.cisco.com;sid=PBAS;port=1521','IRE_CLIENT', 'IRE_369',
                        { RaiseError => 1, AutoCommit => 0 })
                         or  die $DBI::errstr;

$traceInstance->Trace("$DEFAULT", "Connected  to DB " . scalar(localtime));

#
# -- Statistics timeframe - As per user request from UI
#    Default values: Start_time -> Set to frist of the current month
#                    End_time   -> Set to the present date (Database time sjc-dbpl-bld.cisco.com) 
#

    my $start_time = $cgi_obj->param('fromdate');
    my $end_time = $cgi_obj->param('todate');

    # - Fetch the time from DB

        my $chkDateDB = "select max (to_char(start_time, 'yyyymmdd')) from CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW";
        my $stm_chkDateDB = $dbh->prepare($chkDateDB) or die "Cannot prepare the sql statement $stm_chkDateDB $DBI::errstr";
        $stm_chkDateDB->execute() or die "Cannot execute sql statement $stm_chkDateDB $DBI::errstr";
        my $dateDB = $stm_chkDateDB->fetchrow_array;
   
        $traceInstance->Trace("$DEFAULT", "Select time from DB stm : $chkDateDB  Date: $dateDB" . scalar(localtime));  
        $dateDB =~ /^(\d{6})/;
        my $dateCheckDB = $1;
    
        if ($start_time =~ /^$/)
        {
            #-Default value for Start time is set to beginning of the month
            $start_time = "$dateCheckDB"."01";
        }
        else
        {
            my ($month, $day, $year) = split ('/', $start_time);
            $month = sprintf ("%02d" , $month);
            $day = sprintf ("%02d" , $day);
            $start_time = "$year"."$month"."$day";
        }
    
        $start_time =~ /(\d{4})(\d{2})(\d{2})/;
        my ($dis_year, $dis_month, $dis_day) =  ($1, $2, $3);
        my $start_date_display = $dis_month . '/' . $dis_day . '/' . $dis_year; #- Overlay diaplay in UI
    
        if ($end_time =~ /^$/)
        {
            #- Default Value: End date mark it to present date
            $end_time = $dateDB;
        }
        else
        {
            my ($month, $day, $year) = split ('/', $end_time);
            $month = sprintf ("%02d" , $month);
            $day = sprintf ("%02d" , $day);
        
            $end_time = "$year"."$month"."$day";
        }
    
        $end_time =~ /(\d{4})(\d{2})(\d{2})/;
        ($dis_year, $dis_month, $dis_day) =  ($1, $2, $3);
        my $end_date_display = $dis_month . '/' . $dis_day . '/' . $dis_year; #- Overlay diaplay in UI

        $traceInstance->Trace("$DEFAULT", "Start Time : $start_time  :: $start_date_display  Endtime: $end_time :: $end_date_display" . scalar(localtime));  
#
# -- Engineer name - As Logged in user 
#

    $SUBMITTER_LIST = $user_name; 

    #
    # - Create a new JSON file for the first time/ File refreshed everytime user logs in
    #


#
# -- Additional filters / Correlating the stats 
#

    my $buildDetailSelectValue = $cgi_obj->param('buildDetailSelect');

    $buildDetailSelectValue = "MY_CURRENT_RUNNING_BUILDS" if ($buildDetailSelectValue eq ''); 

#
# - Gather data from the CBAS DB for displaying the build stats 
#


my $jsonFileNameDisplayTable;
my $jsonFileNameTable;
my $tableData;
#if ($train_type_select_value ne 'SELECT' and $build_type_select_value ne 'SELECT')
#{

     $jsonFileNameTable = $user_name. '_buildStat.json';
     $jsonFileNameDisplayTable =  $JSON_DIR .$jsonFileNameTable;
     $traceInstance->Trace("$DEFAULT", "Start: Write Table jsonfile $jsonFileNameDisplayTable" . scalar(localtime));
         open (FHWT, "+>$jsonFileNameDisplayTable") or die "Cannot write Table Data JSON file $jsonFileNameDisplayTable\n";

 
    my $getBuildStatStmBuildTime = " select to_char(start_time, \'mm\/dd\/yyyy\') , branch_name, request_type, build_server,  request_desc,NUM_IMAGE_LIST,  NUM_IMAGE_LIST_BUILT,NUM_IMAGE_LIST_FAILED, LOGDIR
                        from
                        CBAS_PROD.CBAS_RPT_CLASSIC_IOS_VW 
                       where
                       start_time >= trunc (to_date('$start_time', 'YYYYMMDD'))
                       and start_time <= (to_date('$end_time','YYYYMMDD')) ";
    $getBuildStatStmBuildTime .= " and submitter = \'$user_name\' " if ($buildDetailSelectValue eq 'MY_CURRENT_RUNNING_BUILDS' or $buildDetailSelectValue eq 'MY_BUILDS');
    $getBuildStatStmBuildTime .= " and proxy_list in (\'$user_name\') "if ($buildDetailSelectValue eq 'PROXY');
    $getBuildStatStmBuildTime .= " and end_time is null " if ($buildDetailSelectValue eq 'MY_CURRENT_RUNNING_BUILDS')  ; 
    $getBuildStatStmBuildTime .= " and (NUM_IMAGE_LIST_BUILT > 0 or NUM_IMAGE_LIST_FAILED > 0) " if ($buildDetailSelectValue eq 'MY_CURRENT_RUNNING_BUILDS')  ; 
    $getBuildStatStmBuildTime .= " and end_time is not null " if ($buildDetailSelectValue eq 'MY_BUILDS')  ; 
    $getBuildStatStmBuildTime .= " order by branch_name, request_id , to_char(start_time, \'mm\/dd\/yyyy\')";

    $traceInstance->Trace("$DEBUG", "Start: prepare SQL stm $getBuildStatStmBuildTime" . scalar(localtime));
    my $sth_getBuildStatStmBuildTime = $dbh->prepare($getBuildStatStmBuildTime) or die "Cannot prepare the sql statement $getBuildStatStmBuildTime $DBI::errstr";

    $traceInstance->Trace("$DEBUG", "End: prepare SQL stm " . scalar(localtime));
    
    $traceInstance->Trace("$DEBUG", "Start: Execute SQL stm " . scalar(localtime));
    $sth_getBuildStatStmBuildTime->execute() or die $DBI::errstr;
    
    $traceInstance->Trace("$DEBUG", "End: prepare SQL stm " . scalar(localtime));
    
    my $buildDisplayData;
    my %buildStat;
    my ($start_time_build, $branch_name, $request_type, $server_name, $build_desc, $total_img, $built_img, $failed_img, $logdir );
    $counter = 1;
    my $totalBuilds;
    while ( ($start_time_build, $branch_name, $request_type, $server_name, $build_desc, $total_img, $built_img, $failed_img, $logdir) = $sth_getBuildStatStmBuildTime->fetchrow_array)
    {

        my $termFile = $logdir .'/terminate.log';
        if (-e $termFile)
	{
            next;
	}
        $totalBuilds.=  "count: \"$counter\",";
        $totalBuilds.=  "start_time_build: \"$start_time_build\","; 
        $totalBuilds.=  "branchname:\"$branch_name\",";
        $totalBuilds.=   "requesttype:\"$request_type\",";
        $totalBuilds.=   "servername:\"$server_name\",";
        $totalBuilds.= "buildname:\"$build_desc\",";
        $totalBuilds.=  "total_images:\"$total_img\",";
        $totalBuilds.=  "built_images:\"$built_img\",";
        $totalBuilds.=  "failed_images:\"$failed_img\",";
        $totalBuilds.=  "logdir:\"$logdir\""; 

        $totalBuilds.= "\}, \{"; 		
        $counter ++;	
        
    }

    $totalBuilds =~ s/\}, \{$//;


    
    print FHWT "\{";
    print FHWT "  identifier: \"count\"\,";
    print FHWT "  label: \"count\"\,";
    print FHWT "  items: \[\{";
    print FHWT "  $totalBuilds"; 
    print FHWT " \}\]\n\}";


    $sth_getBuildStatStmBuildTime->finish();
    close(FHWT);
#}





$dbh->disconnect();
my $INC=<<EOF;
                        var djConfig = {
                                parseOnLoad: true,
                                isDebug: false,
                                usePlainJson: true 
                        };
EOF
;
my $DOJO=<<FI;
// Allow disabling of layers as needed.
		        dojo.require("xwt.xwt-package");		
                        dojo.require("dojo.data.ItemFileReadStore");
                        dojo.require("xwt.widget.notification.Form"); 
                        dojo.require("xwt.widget.form.DatePicker");
                        dojo.require("xwt.widget.form.ComboBox");
                        dojo.require("xwt.widget.form.TextButton");
                        dojo.require("xwt.widget.table.Table");
			dojo.require("xwt.widget._ConfigureTheme");
			dojo.require("xwt.widget.table.Table");
			dojo.require("xwt.widget.table.Toolbar");
			dojo.require("xwt.widget.table.Filter");

FI
;

my $JSCRIPT=<<END;

                        stateStore = new dojo.data.ItemFileReadStore({url: "../html/singleview/jsonfiles/myBuild.json"});
                        stateStoreTableData = new dojo.data.ItemFileReadStore({url: "../html/singleview/jsonfiles/$jsonFileNameTable"});

var tableLayout = [{
			    attr: 'count',
			    label: "Sl No",
			    width: 50 
			}, {
			    attr: 'start_time_build',
			    label: "Build Start Date",
			    width: 100 
			}, {
			    attr: 'branchname',
			    label: "Branch",
			    width: 100
			}, {
			    attr: 'requesttype',
			    label: "BuildType",
			    width: 100
			}, {
			    attr: 'servername',
			    label: "BuildServer",
			    width: 100
			}, {
			    attr: 'buildname',
			    label: "BuildName",
			    width: 100
			}, {
			    attr: 'total_images',
			    label: "Total Images ",
			    width: 100
			}, {
			    attr: 'built_images',
			    label: "Built Images ",
			    width: 100
			}, {
			    attr: 'failed_images',
			    label: "Failed Images ",
			    width: 100
			}, {
			    attr: 'logdir',
			    label: "Log",
			    width: 100
			}];
                       

                        function myFunction()
                       {
                             var start_date_from = dijit.byId("from_date");
                                 //alert ("start date" + start_date_from.get("value"));
                             document.getElementById('fromdate').value = start_date_from.get("value");

                             var start_date_to = dijit.byId("end_date");
                                 //alert ("to date" + start_date_to.get("value"));
                             document.getElementById('todate').value = start_date_to.get("value");

 var build_detail_list_select = dijit.byId("build_detail");
                           //      alert ("build list" + build_type_list_select.get("value"));
                             document.getElementById('buildDetailSelect').value = build_detail_list_select.get("value");

                             document.getElementById("form1").submit();
                      }

END

$cgi_obj->default_dtd(
            '-//W3C//DTD HTML 4.01 Transitional//EN',
            'http://www.w3.org/TR/html4/strict.dtd');
print $cgi_obj->header();
print $cgi_obj->start_html(
           -dtd=>'yes',
           -title=>'BuildStat',
           -class=>'prime',
           -head=>meta({-http_equiv => 'Content-Type',
                                    -content    => 'text/html; charset=UTF-8'}),
             -style=>[
                       {
                           -src=>'../html/sdcunha/xwt/themes/prime/prime-base.css'
                       },
                       {
                           -src=>'../html/sdcunha/xwt/themes/prime/prime-xwt.css'
                       }
                     ],
             -script=>[
                     $INC,
                     {
                          -type => 'text/javascript',
                          -src => '../html/sdcunha/dojo/dojo.js'
                     },
                     {
                          -type => 'text/javascript',
                          -src => 'tableContentworking.js'
                     },
                     $DOJO,
                     $JSCRIPT,
                      ]
       );

print qq~
		<h1>My Build Stat</h1>
                <p> User logged in - $user_name --  Stat from $start_time till $end_time for Engineer $submitterDisplay </p> 
~;

print qq~
<form id="form1" jsid="form1" dojoType="xwt.widget.notification.Form" action="http://wwwin-cositool-dev.cisco.com/cgi-bin/getMyBuildStat.cgi" name="example" method="post">
			
		                   <div style="float:left;width: 50px;margin-top:4px;padding-left: 7px;">
                                                <label style="padding-left:4px;">From</label>
                                        </div>
                                        <div>
                                                <div id="from_date" dojoType="xwt.widget.form.DatePicker" showLabel=false required="true" value="$start_date_display" datePickerText="Select Start Date to Generate the stat"> </div>

                                                <INPUT type="hidden" id="fromdate" name="fromdate" > </INPUT>  
                                        </div>
<br>	
					<div style="float:left;width: 50px;margin-top:4px;padding-left: 7px;">
						<label style="padding-left:4px;">To</label>			
					</div>
					<div>
						<div id="end_date" dojoType="xwt.widget.form.DatePicker" value="$end_date_display" showLabel=false required="true" datePickerText="Select End Date to Generate the stat"></div>
                                                 <INPUT type="hidden" id="todate" name="todate"   > </INPUT>
					</div>	

<br>
<br>
<br>
					
			<div class="dojoFilteringSelectLabel">
				<label style="padding-left:4px; margin-top:4px;padding-left: 7px; " for="list">Select Build Stat:  </label>
				<input dojoType="xwt.widget.form.ComboBox"
                                                   ~;
                                                   if ($submitterDisplay eq 'MY_CURRENT_RUNNING_BUILDS')
                                                   {  
                                                        print qq~
						   	value="MY_CURRENT_RUNNING_BUILDS"
                                                        ~;
                                                   }
                                                   else
                                                   {
                                                       print qq~
                                                        value="$buildDetailSelectValue"
                                                        ~;
                                                   }  
                                                   print qq~  
							store="stateStore"
							searchAttr="name"
							style="width: 205px;"
							name="build_detail"
							autoComplete="false"
							id="build_detail"
							required="true"
							highlightMatch="none" />	
				
                                 <INPUT type="hidden" id="buildDetailSelect" name="buildDetailSelect" > </INPUT> 

                        </div>	
                   </div>
<br><br><br>
<div style="padding-left:4px; margin-top:4px;padding-left: 7px; ">
				<button name="button" type="submit" class="xwtDisableableButton"  dojoType="xwt.widget.form.TextButton" id="save-button" onClick="myFunction()" >GetStat</button> 

</form>
~;

#if ($train_type_select_value ne 'SELECT' and $build_type_select_value ne 'SELECT')
#{
print qq~
<br>
<br>
<br>
		<form action='javascript: alert("This should not execute!")' style="min-width: 87rem;">
			<div id="global" dojoType="xwt.widget.table.GlobalToolbar" title="Build Stats" tableId="table" showButtons="refresh, settings"
				displayTotalRecords="true">
			</div>
			<div id="context" dojoType="xwt.widget.table.ContextualToolbar" tableId="table" quickFilter="true">
			</div>
			<div id="table" jsid="table" dojoType="xwt.widget.table.Table" store="stateStoreTableData" 
				selectMultiple="true" selectModel="input" selectAllOption=true
				style="height: 25rem;" structure="columns" filters=[]>
			</div>
		</form>
~;
#}
print qq~
</body>
    </html>
~;
$traceInstance->Trace("$DEFAULT", "End - Logging ");
$cgi_obj->end_html();

