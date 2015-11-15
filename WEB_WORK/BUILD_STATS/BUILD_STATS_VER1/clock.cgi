#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);

$|=1;

my $cgi = CGI->new();
#E6E6FA light blue
#6666CC
#FFCC99 light pink
print $cgi->header();
print $cgi->start_html(
                        -bgcolor => "#9999CC",
                       );
                       
#print' <embed src="http://www.clocktag.com/cs/flags/hindigital.swf"  width="150" height="197" wmode="transparent" type="application/x-shockwave-flash"></embed>';
#*print '<embed src="http://www.clocktag.com/cs/d11.swf"  width="140" height="30" wmode="transparent" type="application/x-shockwave-flash"></embed>';
#**print '<embed src="http://www.clocktag.com/cs/d51.swf"  width="135" height="54" wmode="transparent" type="application/x-shockwave-flash"></embed>';

print '<div style="text-align:center;width:350px;padding:0.5em 0;"> <h2><span style="color:white;">Current local time in</span><br />Bangalore, India</a></h2> <iframe src="http://www.zeitverschiebung.net/clock-widget-iframe?language=en&timezone=Asia%2FKolkata" width="100%" height="130" frameborder="0" seamless></iframe></div>';

#print '<div style="text-align:center;width:350px;padding:0.5em 0;"> <h2><span style="color:#000033;">Current local time in<br/>Bangalore, India</span></a></h2> <iframe src="http://www.zeitverschiebung.net/clock-widget-iframe?language=en&timezone=Asia%2FKolkata" width="100%" height="130" frameborder="0" seamless></iframe></div>';

=pod
print <<CLOCK
<!-- clock widget start -->
<script type="text/javascript"> var css_file=document.createElement("link"); css_file.setAttribute("rel","stylesheet"); css_file.setAttribute("type","text/css"); css_file.setAttribute("href","//s.bookcdn.com//css/cl/bw-cl-126el.css"); document.getElementsByTagName("head")[0].appendChild(css_file); </script> <div id="tw_7_749473787"><div style="width:126px; height:82px; margin: 0 auto;">Bang<br/></div></div> <script type="text/javascript"> function setWidgetData_749473787(data){ if(typeof(data) != 'undefined' && data.results.length > 0) { for(var i = 0; i < data.results.length; ++i) { var objMainBlock = ''; var params = data.results[i]; objMainBlock = document.getElementById('tw_'+params.widget_type+'_'+params.widget_id); if(objMainBlock !== null) objMainBlock.innerHTML = params.html_code; } } } var clock_timer_749473787 = -1; </script> <script type="text/javascript" charset="UTF-8" src="http://www.booked.net/?page=get_time_info&ver=2&domid=209&type=7&id=749473787&scode=124&city_id=18033&wlangid=1&mode=0&details=0&background=ffffff&color=08488d&add_background=ffffff&add_color=00faff&head_color=333333&border=0&transparent=0"></script>
<!-- clock widget end -->
CLOCK
;
=cut
#print '
#<div style="margin: 15px 0px 0px; display: inline-block; text-align: center; width: 118px;"><div style="display: inline-block; padding: 2px 4px; margin: 0px 0px 5px; border: 1px solid rgb(204, 204, 204); text-align: center; background-color: transparent;"><a style="text-decoration: none; font-size: 13px; color: rgb(0, 0, 0);" href="http://localtimes.info/Asia/India/Bangalore/"><img src="http://localtimes.info/images/countries/in.png"="" border=0="" style="border:0;margin:0;padding:0"=""> Bangalore</a></div><script src="http://localtimes.info/clock.php?continent=Asia&country=India&city=Bangalore&cp1_Hex=000000&cp2_Hex=36357e&cp3_Hex=000000&fwdt=118&ham=0&hbg=1&hfg=0&sid=0&mon=0&wek=0&wkf=0&sep=0&widget_number=100" type="text/javascript"></script></div>
#';
print $cgi->end_html();

