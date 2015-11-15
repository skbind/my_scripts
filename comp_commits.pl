#!/usr/cisco/bin/perl -w
use strict;
use Data::Dumper;
use Getopt::Long;
use WWW::Mechanize;
use HTML::TableExtract;

#use lib '/users/sabind/SCRIPTS/EXTERNAL_LIB';
#use lib '/users/sabind/LOCAL_INSTALLS/my_perl/external_libs/lib/site_perl/5.22.0/';

my ($list,$help_msg,$comp,$start_label,$end_label);

GetOptions(
    "list|f:s" 	    	=> \$list,
    "help|h"        	=> \$help_msg,
    "component|b:s" 	=> \$comp,
    "start_label|sl"    => \$start_label,
    "end_label|el"      => \$end_label,
) or die " Error \n";

my $username = "integ";
my $keyword = "CSGInteg2015";
my $mech = WWW::Mechanize->new( autocheck => 1 );

my $url = 'http://cts.cisco.com/cts/db?comp=crypto&branch=comp_crypto_rel15';
$mech->credentials( "$username" => "$keyword" );
$mech->get( $url );
#print $mech->content();
chomp(my $html = $mech->content);
 
 my $te = HTML::TableExtract->new( headers => [qw(Version Bugid Committed)] );
 $te->parse($html);

 # Examine all matching tables
 foreach my $ts ($te->tables) {
   #print "Table (", join(',', $ts->coords), "):\n";
   foreach my $row ($ts->rows) {
       my $row_value =  join(':', @$row);
   	   $row_value =~ s/(^\s+|\s+$|\n)//mg;
   	   $row_value =~ s/::\s*//;
   	   $row_value =~ s/\s*|ExportedTo|CommittedTo//mg;
   	   $row_value =~ s/ExportedTo|CommittedTo//g;
   	   print "$row_value\n";
      # print join(',', @$row), "\n";
   }
 }

 
=pod

		my $mech = WWW::Mechanize->new(); 
		#$mech->get("http://cts.cisco.com/cts/db?comp=crypto&branch=comp_crypto_rel15");
		$mech->get("http://cts.cisco.com/cts/");
		 
		my $dest = $mech->response->content;
 
		print "Fetching...\n" ;

		unless($mech->success()){
			print "\n web link can not access\n";
			exit;
		}else{
			print "\n web link Accessed sucessfully\n";
		}

=pod
 
if($mech->response->header("Content-Encoding") eq "gzip")
{
	$dest = Compress::Zlib::memGunzip($dest);
	$mech->update_html($dest);
	print "\n Inside zip\n";
}
 
# Commented the below line from version 1b. Uncomment it for version 1a.
#$dest =~ s/<form name="loginForm"/<form action='..\/auth.cl' name="loginForm"/ig;
 
# Added the below updated line to replace the above line in the version 1b.
#lgnFrm
#loginBTN
my $forms = $mech->forms();

$dest =~ s/<form name="loginForm"/<form action='..\/Login1.action' name="loginForm"/ig;

print "\n\n ===================================\ndest\n\n ===================================\n";
#my $ref = ref $forms;
#print Dumper(\@$forms);
#print join("\n FORM:",@{$forms});
 
$mech->update_html($dest);
$mech->form_with_fields(("username","password"));

$mech->field("username",$username);
$mech->field("password",$keyword);

#my $form2 = $mech->form_with_fields(("username","password"));
#print "REF: $form2\n";
#print Dumper(\%$form2);


print "Loggin...\n" if($deb);
 
$mech->submit_form();
 
$dest= $mech->response->content;
if($mech->response->header("Content-Encoding") eq "gzip"){
	$dest = Compress::Zlib::memGunzip($dest);
	$mech->update_html($dest);
}
	    