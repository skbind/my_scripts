#!/usr/cisco/bin/perl

my $in = "/tmp/unstamped";
my $out = "/tmp/unstamped_out";

open (IN, "< $in") or die "Error: Could not open $in\n\n";
open (OU, "> $out") or die "Error: Could not open $out\n\n";

##STAMP
##cmd = fixcr -i CSCua82425 Integrated-releases "15.1(04)M06"

##UN-STAMP
##cmd = fixcr -i CSCua82425 -R Integrated-releases "15.1(04)M06"

while (<IN>)
{
 my $bug = $_;
 chomp ($bug);
 my $cmd = qq{fixcr -i $bug Integrated-releases "15.2(01)SY01a"};
 my $res = `$cmd`;
 print "CMD-> $cmd;;;; OUT-> $res\n";
 print OU "CMD-> $cmd;;;; OUT-> $res\n";
}

print "TerminatinG!! \n\n";
