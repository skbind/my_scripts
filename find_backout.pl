#!/usr/cisco/bin/perl5.8 -w
################################################################################
#  Copyright (c) 2003-2008 by cisco Systems, Inc.
#  All Rights Reserved
#
#  File Id:
#  Rel Cspec:
#  Rel Date:   
#  Enhancement:
#	- filename option from command line
#	- directory should be output'd to bkout.dir
#	- output result to bkout.single bkout.mix
# 	- using sync_tool modules
#	- file has ref ver but no base version should be in the single list
#	- using sync_get_contrib to get bas and ref version for diffs
#       - backout a file version which filename was changed in the child branch. 
#         Use oid to find the child's filename.
################################################################################

my $CT = '/usr/atria/bin/cleartool';
my $DIFF_cmd = '/router/bin/diff -q';
my $REF_VDIR = $ENV{ 'REF' };
my $BAS_VDIR = $ENV{ 'BAS' };
my $SYN_VDIR = $ENV{ 'SYN' };
my $PRE_VDIR = $ENV{ 'PRE' };

sub get_all_version
{
    my $fname = shift;
    my %element;
    
    $element{'NAME'} = $fname;
    my $ref_path = $REF_VDIR . $fname;
    my $bas_path = $BAS_VDIR . $fname;
    my $pre_path = $PRE_VDIR . $fname;

    $element{'REF'} = `$CT des -fmt "%n" $ref_path`;
    $element{'BAS'} = `$CT des -fmt "%n" $bas_path`;
    $element{'PRE'} = `$CT des -fmt "%n" $pre_path`;

    $element{'PRED_REF'} = `$CT des -fmt "%En@@%PVn" $element{'REF'}`;

    foreach my $i ( keys(%element) ) {
        print "$i  $element{$i} \n";
    }
    return \%element;
}

sub is_identical
{
    my ($file1, $file2) = @_;
    
    #system return is oppsite to perl func return
    my $rc = ! system("$DIFF_cmd $file1 $file2");

    my $status_str = $rc ? "" : "NOT";

    my $diff_msg = <<EOF;
$file1 and
$file2 is $status_str identical

EOF

    print $diff_msg;
    return $rc;
}




#############################
# main()
#############################
{
  my $bkout_version = '/vob/ios/ddts.bkout.version';

  my @single_bkout_list;
  my @special_bkout_list;

  open(FILE, "<$bkout_version") 
		or die "Can't open $bkout_version and exit!\n";

  while (<FILE>) {
	chomp();
	print "\n\n### BOUT VERSION $_ \n";
  	my ($filename, $s1, $s2, $ver) = split(/@/, $_);
  	my $elmt = get_all_version($filename);
  	#print "$elmt->{NAME}\n";

  	if ( is_identical($_, $elmt->{'REF'}) && 
             is_identical($elmt->{'BAS'}, $elmt->{'PRED_REF'})     
     	   ) 
  	{
        	push(@single_bkout_list, $elmt->{'NAME'}."\n");
  	} else {
		push(@special_bkout_list, $_."\n");
  	}

  }  
  close FILE;
  	print <<EOF;

### SINGLE BACKOUT FILES ###
@single_bkout_list

### MULTI BACKOUT FILES ###
@special_bkout_list
EOF

## TO DO LIST:
## make "bkout_versions" to be a parameter to the script
## also need to double check if the file is "branched" in haw_t, ie, not a bleed-through file
  

}
