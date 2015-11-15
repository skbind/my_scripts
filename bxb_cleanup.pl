#!/usr/cisco/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::stat ;

#print "---------------------------------";
#USES:
#perl bxb_cleanup.pl -f bxb-archive
#cat bxb-archive
#	/auto/bxb-swarchives4
#	/auto/bxb-swarchives2

my ($archive_list,$archive_dir,$help);
GetOptions(
    "f|list:s" 	    => \$archive_list,
    "dir|d:s"     => \$archive_dir,
    "help|h"        => \$help,
) or die " Error \n";

my @arv_list;
if($archive_list){	
	my $filename = $archive_list;
	open(my $fh,  "< $filename") or die "Could not open file '$filename' $!"; 
	while (my $row = <$fh>) {
    	chomp $row;
  		#print "$row\n";
  		push @arv_list,$row;
	}
	
}else{
	print "please pass the archive list\n";
	exit(0);
}
#exit;
print <<"BEGIN";
------------------------------------------------------------------------------------------------
DIR/FILE NAME:SIZE:CREATION TIME:DIR OWNER:LAST ACCESSED:FILE OWNER:FILE ACCESSED
BEGIN
my $sed = 'sed \'s/\s\+/ /g\'';
foreach my $part (@arv_list){
	#$part = '/auto/bxb-swarchives5/';
	chomp $part;
	$part.= '/' if $part !~ /\/$/;
	my $cmd = "ls -l $part | $sed"; #| cut -d\' \' -f1,3,6,7,8,9
	my @data = `$cmd`;
	#print "errror = $? and cmd = $cmd\n";
print <<"BEGIN";
------------------------------------------------------------------------------------------------
PARTITION:$part
BEGIN
	foreach my $line (@data){
		chomp $line;
		next if $line =~ /total/;
		my @word = grep { /\S/ } split / /, $line; # split("\s+", $line); ## grep the o/p so that its contains non-whitepace characters.
		my @newarr = grep(s/\s*$//g, @word); # remove leading and trainling space of array elements.
		next if ($newarr[7] =~ /:/ && $newarr[7] =~ /^\d/ );
		next if $newarr[2] =~ /root/;
		if ($newarr[7] <= 2013){
			my $stat = "find \$1 -type f -exec stat --format '%Y :%y %n' \"{}\" \\; \| sort -nr \| cut -d: -f2- \| head -1";
			
			my $dir = "$part$newarr[8]" ;
			my $st = stat($dir);
			chomp(my $mod =  $st->mode) ;
			#print "mod = $mod\n";
			my $stat_res ;
			my @stat_data;
			my $uses;
			if($mod == 16832){
				$stat_res = 'ISSUE';
			}else{
				if( -d "$part$newarr[8]"){										
					$stat_res = `cd $part$newarr[8] ; $stat` ;
					@stat_data = grep { /\S/ } split / /,$stat_res if($stat_res);
					chomp($uses = `cd $part$newarr[8] ; du -sh  $part$newarr[8]`);
				}
			}
		
if( -d "$part$newarr[8]" && $stat_res  && ($stat_res ne 'ISSUE')){
	my $file = $stat_data[3];
	my $main_dir = $newarr[8];
	chomp($file,$main_dir,$part);
	$file =~ s/^\.//;
	$file =~ s/^\///;
	my $child_own = `ls -l $part$main_dir/$file \| cut -d' ' -f3`;
	chomp($child_own);
	$uses =~ s/\s+/:/g;
	my ($size,$ex_dir) = grep { /\S/ } split /:/,$uses;
	my ($yy,$mm,$dd) = grep { /\S/ } split /\-/,$stat_data[0];
	if($yy <= 2014){		
		print "$ex_dir:$size:$newarr[5] $newarr[6] $newarr[7]:$newarr[2]:$stat_data[0]:$child_own:$file\n";
		my @subdir = `find $ex_dir -maxdepth 3 -type d -mtime +275 -printf '%p %u\n'`;
		foreach(@subdir){
		chomp(my($subdir,$user) = grep { /\S/ } split / /,$_);
		print "\t:\t:\t:\t:\t:$user:$subdir\n" ;
		#print "SubDir List(s): = @subdir\n";
		}
	}

# print <<"END"
#$ex_dir:$size:$newarr[5] $newarr[6] $newarr[7]:$newarr[2]:$stat_data[0]:$child_own:$file
#END 
}elsif(-d "$part/$newarr[8]" && (!$stat_res)){

 print <<"END"
$part$newarr[8]:0:$newarr[5] $newarr[6] $newarr[7]:$newarr[2]:EMPTY DIR
END
	
}elsif($stat_res eq 'ISSUE'){

 print <<"END"
$part$newarr[8]:PERMISSION ISSUE:$newarr[5] $newarr[6] $newarr[7]:$newarr[2]:NO PERMISSION To THIS DIR
END
	
}else{
 print <<"END"
$part$newarr[8]:NA:$newarr[5] $newarr[6] $newarr[7]:$newarr[2]: ITS A FILE
END
}
		}
	} 
	#last;
}