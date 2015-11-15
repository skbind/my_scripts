
my $var =
"Please wait, examining view...

Integration Branch: v152_1a_sy_throttle
View Freeze time  : 12-Sep-2015.05:50:00UTC-07:00
Bug ID   : CSCur64967
Comments :
Bundle porter tar file to Sup2T image
All Active Elements:
    /view/integ-MK2A_NEW_T_C2K_BUNDLE_VW_DONT_DEL/vob/ios.sys4/sys/const/native-si/fex_version_mgmt.c
    /view/integ-MK2A_NEW_T_C2K_BUNDLE_VW_DONT_DEL/vob/ios/micro/c3560cx-universalk9-tar
    /view/integ-MK2A_NEW_T_C2K_BUNDLE_VW_DONT_DEL/vob/ios/micro/c6800ia-universalk9-tar
15.077u 1.049s 0:17.16 93.8%	0+0k 0+0io 0pf+0w
    ";

my $view = 'integ-MK2A_NEW_T_C2K_BUNDLE_VW_DONT_DEL';


	    my $file_match = "/view/.*$view.*";
	    my $files = $& if ($var =~ /$file_match/sm);
	    $files =~ s/^\s+$//sm;
	    $files =~ s/^\s+$//sm;

		chomp($files);
		my @file_content = split("\n",$files);
		pop(@file_content) if ($file_content[$#file_content] =~ /$file_match/);
		my @newarr = grep(s/\s*//g, @file_content); # remove leading and trainling space of array elements.	    
	    print "#$_#\n" foreach @newarr;
	    
	    print "$file_content[$#file_content]\n";

=pod
if($var  =~ /^\s+\/view\/.+/mg){
	print "$&\n";
}

#print "$var\n";