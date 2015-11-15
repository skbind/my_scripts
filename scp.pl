#!/usr/cisco/bin/perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use Cwd; 

my $cmd = 'scp -p sabind@build-lnx-011:/san1/temp1/\{a,b,c\} /users/sabind/SCRIPTS/temp2/./';

my $res = qx/$cmd/;

print "####$res###\n";