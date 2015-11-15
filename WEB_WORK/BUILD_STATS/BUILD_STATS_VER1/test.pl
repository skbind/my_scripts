
use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

my $cgi = CGI->new();
print $cgi->header();

my $cmd = '/usr/bin/scp sabind@build-lnx-011:/san1/temp1/\{a,b,c\} /auto/web-cosi/dev/cgi-bin/temp1/./';

my $res = qx/$cmd/;

print "conversion done ##$res##  $? !!!\n";