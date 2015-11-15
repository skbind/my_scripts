#!/usr/local/bin//perl5.8

use warnings;
use strict;
use Data::Dumper;
use CGI qw(:standard);

$|=1;

my $cgi = CGI->new();
my $type = $cgi->param("type") || "none";

print $cgi->header();
#-background => 'image/gray-strip.jpg',
#E6E6FA light blue
#FFFFCC light yellow

print $cgi->start_html(
                        -bgcolor => "#FFD4FF",
                       );
print $cgi->end_html();

