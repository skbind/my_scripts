#! /usr/cisco/bin/perl
use warnings;
use strict;
use Data::Dumper;

open(FH,"<",'bleed_files_unique1') or die "[ERROR]   : Can't Open File: bleed_files_unique1.\n";
my $count = 0;
while (<FH>){
	chomp;
	if( -d $_){
		print "$_\n";
		$count++;
	}
}
close(FH);

print "Total = $count\n";