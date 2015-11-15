#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);

$|=1;

my $cgi = CGI->new();
my $type = $cgi->param("type") || "none";

print $cgi->header();
print $cgi->start_html();
print $cgi->end_html();

