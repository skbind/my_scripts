#! /usr/cisco/bin/perl
#/usr/cisco/bin/python
use warnings;
use strict;
use Data::Dumper;
#use lib '/users/sabind/SOFTWARES/localperl/lib';

my %alias =  (
	cleartool => 1,
	common => 2,
	synctool => 3,
	cctool => 4,	
);

#print Dumper(\%alias);
my $no;
my $option = $ARGV[0];

$option = lc $option if($option);
$option ||= 'all';

if(	$option && !(exists $alias{$option})){
	print "\t Please provide correct option\n";
	exit(0);
}

if($option && exists $alias{$option}){
	chomp($no = $alias{$option})	
}
#print "option = $option match = $no\n";

open (FH,'/users/sabind/.cshrc') or die "Can't open .cshrc file";
if($option =~ /all/){
	  while (<FH>) {
	  if (/START1/../END4/) {
	    next if($_ =~ /^#.*$/);
	    print ;
	  }	
	}
	
}else{
  while (<FH>) {
	  if (/START$no/../END$no/) {
	  	next if($_ =~ /^#.*$/);
	    print ;
	  }	
	}
}

