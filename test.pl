#! /usr/cisco/bin/perl
use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use File::stat ;

use Net::SSH::Perl;

my $hostname = "build-lnx-056";
my $username = "sabind";
my $password = "Bang\@231";

my ($archive_list,$archive_dir,$help);
GetOptions(
    "f|list:s" 	    => \$archive_list,
    "dir|d:s"     => \$archive_dir,
    "help|h"        => \$help,
) or die " Error \n";

my $sed = 'sed \'s/\s\+/ /g\'';
print <<"BEGIN";

------------------------------------------------------------------------------------------------
DIR/FILE NAME:SIZE:CREATION TIME:DIR OWNER:LAST ACCESSED:FILE OWNER:FILE ACCESSED
BEGIN

if($archive_list){	
	my $filename = $archive_list;
	open(my $fh,  "< $filename") or die "Could not open file '$filename' $!"; 
	while (my $row = <$fh>) {
    	chomp $row;
  		#print "$row\n";
  		#push @arv_list,$row;
  		my @data =split (':',$row);
  		if($#data >= 1){
  			my $server = shift @data;
  			print <<"BEGIN";
------------------------------------------------------------------------------------------------
SERVER:$server
BEGIN
  			my $count = 0;
  			foreach my $part (@data){
  				chomp $part;
				$part.= '/' if $part !~ /\/$/;
				my $cmd = "ls -l $part | $sed"; #| cut -d\' \' -f1,3,6,7,8,9
  				my $ssh = Net::SSH::Perl->new("$server", debug=>0);
				$ssh->login("$username","$password");
				print "\n" if($count);
				print "PARTITION:$part\n\n";
				my ($stdout,$stderr,$exit) = $ssh->cmd("$cmd");
				print "\n$stderr" if($exit);
				next if($exit);
				$stdout =~ tr/\n/#/;
				chop $stdout if ($stdout =~/#$/);
				my @line = split ("#",$stdout);				
				foreach my $line (@line){
					chomp $line;
					next if $line =~ /total/;
					my @word = grep { /\S/ } split / /, $line; # split("\s+", $line); ## grep the o/p so that its contains non-whitepace characters.
					my @newarr = grep(s/\s*$//g, @word); # remove leading and trainling space of array elements.
					next if ($newarr[7] =~ /:/ && $newarr[7] =~ /^\d/ );
					next if $newarr[2] =~ /root/;
					if ($newarr[7] <= 2014){
						my $dir = "$part$newarr[8]" ;
						my $stat = "find $dir \$1 -type f -exec stat --format '%Y :%y %n' \"{}\" \\; \| sort -nr \| cut -d: -f2- \| head -1";
						my $stat_res ;
						my @stat_data;
						my $uses;
						my ($stdout,$stderr,$exit) = $ssh->cmd("cd $dir");
						#print "\n#$stdout#$stderr#$exit#\n";
						unless($exit){
							my ($std,$err,$ext) = $ssh->cmd("$stat");							
							$stat_res = $std ;
							my ($std2,$err2,$ext2) = $ssh->cmd("cd $dir ; du -sh  $dir");
							chomp($uses = $std2);
							if($stat_res){
								@stat_data = grep { /\S/ } split / /,$stat_res if($stat_res);
								my $file = $stat_data[3];
								my $main_dir = $newarr[8];
								chomp($file,$main_dir,$part);
								my $child_own_cmd = "ls -l $file \| cut -d' ' -f3";
								my ($std3,$err3,$ext3) = $ssh->cmd("$child_own_cmd");
								chomp(my $child_own = $std3);
								$uses =~ s/\s+/:/g;
								my ($size,$ex_dir) = grep { /\S/ } split /:/,$uses;
								print "\n$ex_dir:$size:$newarr[5] $newarr[6]  $newarr[7]:$newarr[2]:$stat_data[0]:$child_own:$file\n";
							}elsif($ext == 0){								
								print "$dir:0:$newarr[5] $newarr[6]  $newarr[7]:$newarr[2]:EMPTY DIR\n";					
							}
							
						}else{
							#my ($std4,$err4,$ext4) = $ssh->cmd("cd $dir ");
							chomp($stderr);
							if($stderr =~ 'Not a directory'){
						    print "$dir:0:$newarr[5] $newarr[6]  $newarr[7]:$newarr[2]:ITS A FILE\n";
								
							}else{
						    	print "$dir:0:$newarr[5] $newarr[6]  $newarr[7]:$newarr[2]:PERMISSION ISSUE\n";
							}
						}
					}
				}
				$count++ ;
  				
  			} # for loop END
  		}
  		#last;
	}
	
}else{
	print "please pass the archive list\n";
	exit(0);
}

=pod
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

 print <<"END"
$ex_dir:$size:$newarr[5] $newarr[6] $newarr[7]:$newarr[2]:$stat_data[0]:$child_own:$file
END
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


================
my $ssh = Net::SSH::Perl->new("$hostname", debug=>0);
$ssh->login("$username","$password");
my ($stdout,$stderr,$exit) = $ssh->cmd("$cmd");
print $stdout;