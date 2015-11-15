#!/usr/cisco/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use Cwd; 


sub ScanDirectory {
	my $workdir = shift;
	my $startdir = cwd; # keep track of where we began
	
	chdir $workdir or die "Unable to enter dir $workdir: $!\n";
	opendir my $DIR, '.' or die "Unable to open $workdir: $!\n";
	my @names = readdir $DIR or die "Unable to read $workdir: $!\n";
	my $pwd = `pwd`;
	closedir $DIR;
	
	foreach my $name (@names) {
		next if ( $name eq '.' );
		next if ( $name eq '..' );
		if ( -d $name ) { # is this a directory?
			chomp(my $pwd = `pwd`);
			print "DIR : $pwd/$name\n";
			ScanDirectory($name);
		}
		next;
	}
	chdir $startdir or die "Unable to change to dir $startdir: $!\n";
}

ScanDirectory('/auto/bxb-swarchives6');