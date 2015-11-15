#!/usr/cisco/bin/perl5.8.8 -w
################################################################################
#
# Program:     updver_comp.pl
# Creator:     Sandeep Kumar Bind (sabind@cisco.com)
# Date:        1/7/2005
#
# Copyright (c) 1996-2007, 2009-2010, 2012 by cisco Systems, Inc.
#
################################################################################

=head1 NAME

    updver_comp.pl - To get clasification detail of component version.

=head1 SYNOPSIS

    updver_comp.pl  [-help]

=head1 DESCRIPTION

The tool updver_comp.pl is responsible getting detail of component clasification.
with a component version. The attribute list is restricted only to PASSED_STATIC_ANALYSIS,
BAD_FIX, and GOOD_FIX_VERSION attributes.

=head1 OPTIONS

 -help       - Show the usage information for cc_updver_comp.

 -file       - List of the component or component version to be examined.
               It's value should be in the <compname@version-string> format.

=head1 EXAMPLES
 o   To get component clasification
     updver_comp.pl -file /path_contains_component_list

=head1 SEE ALSO

 updbranch

=cut

BEGIN {
    if ( $^O eq 'MSWin32' ) {
        require( $ENV{'CC_STARTUP_FILE'}
              || 'T:/cctools/current/lib/cc_startup.pm' );
    }
    else {
        require( $ENV{'CC_STARTUP_FILE'}
              || '/usr/cisco/packages/atria/current/lib/cc_startup.pm' );
    }
}

##################################################################
#                      MODULES                                   #
##################################################################
use strict;
use Getopt::Long;
use Error qw( :try );
use cc_error;
use cc_component::singlesource;
use cc_comp_tag;
use cc_branch;
use cc_env_init;
use Pod::Usage qw( pod2usage );
use Data::Dumper;

require "cc_io.pl";

################################################################################
#                    GLOBALS                                                   #
################################################################################
my %ALL_ATTRIBUTES = (
    BRANCH_CLASSIFICATION  => \&_cs_branch_classification
);
my $Exitval = 0;
my %attr_change_details;

################################################################################
#			MAIN						       #
################################################################################
# The main function.
# Things gets controlled from the hash of functions. One just needs to create a
# separate function and add to the hash of function. That's all !
try {
    flush();
    cc_env_init::cc_setup();
    install_sighandler();

    my %option_values = ();
    my @options       = qw( help component=s change=s  file=s);
    my ( $component_obj, $component_name, $attr, $value, $comp_tag_obj,
        %attr_old_values, $old_value );

    my $result = GetOptions( \%option_values, @options );
    if ( !$result || scalar(@ARGV) ) {
        pod2usage(
            -exitval => 1,
            -verbose => 0,
            -message => "Error: Invalid arguments passed.\n"
        );
    }

    if ( exists( $option_values{help} ) ) {    #GetOpts knows h for help
        pod2usage( -exitval => 0, -verbose => 1 );
    }

    if ( defined( $option_values{file} ) ) {
    	my $file = $option_values{file};   
	    open (FH,"< $file") or die "Can't open the file: $file\n";	
		foreach (<FH>){
			next if ($_ =~ /^#/ || /^\s+/);
			$_ =~ s/\s+::.*$//;
			chomp;
			#print "$_\n";
			$option_values{component} = $_;
			my $comp = $option_values{component};
	        my $comp_obj  = cc_component::singlesource->new( component => $comp );
	        my $comp_t_obj = $comp_obj->get_tag();					        
	        &_show_comp_attr( $comp_t_obj, $_ );
		}
		close(FH);
        cc_view_exit(0);
    }else{
    	print "\n Please provide the file path\n";
    	cc_view_exit(0);
    }
}
  otherwise {
    my $e = shift;
    print "ERROR: " . $e->text . "\n";
    $Exitval ||= 1;
  };
cc_view_exit( $Exitval, undef, \%attr_change_details );

##############################################################################
#                        FUNCTIONS                                            #
###############################################################################

#----------------------------------------------------------------------------------------

sub flush {

    # autoflush output
    select(STDERR);
    $| = 1;    # make unbuffered
    select(STDOUT);
    $| = 1;    # make unbuffered
}

#---------------------------------------------------------------------------------------------
# show_comp_attr ()
# Retrieves the existing attr values from the Component tag.
# Params:
#       Component Tag - The component tag object.
#       Component name - The component version string.
# Returns
#      A existing attributes value hash.
#------------------------------------------------------------------------- -------------------
sub _show_comp_attr {
    my ( $comp_tag, $component_name ) = @_;
    my $attr_val_str    = '';
    $attr_val_str = $ALL_ATTRIBUTES{BRANCH_CLASSIFICATION}->( $comp_tag, undef, undef );
    print $comp_tag->get_spec()->get_name() . '@'. $comp_tag->get_version_string(). ' : ';
    print "$attr_val_str\n" ;
}

# _cs_branch_classification()
#
# If parameter   : Set the changeset branch classification.
# If no parameter: Return the changeset branch classification, or '' if none.
#
# Params:
#      Component Tag - The component tag object
#      Attr Value    - The new classification
#      Returns (set) - 1 (if properly set)
#                    - 0 (user quits)
#                    - Throws Exception on any other error.
#------------------------------------------------------------------------------------
sub _cs_branch_classification {
    my ( $comp_tag, $new_value ) = @_;
    my $changeset = $comp_tag->get_cctoolsdb_comp_ver->changeset;

    # Set the changeset branch classification to the given value
    if ($new_value) {

        # Error - no changeset
        if ( !$changeset ) {
            my $version = $comp_tag->get_spec->get_spec;
            throw cc_error(<<EOF);
Unable to set BRANCH_CLASSIFICATION on version ($version) with no changeset.
EOF
        }

        # Error - invalid classification
        if ( !cc_branch->VALID_CLASSIFICATIONS->{$new_value} ) {
            my $valid =
              join( " ", sort( keys %{ cc_branch->VALID_CLASSIFICATIONS } ) );
            throw cc_error(<<EOF);
Invalid BRANCH_CLASSIFICATION: $new_value
       Valid values include : $valid
EOF
        }

        # Ok - Set
        $changeset->update( branch_classification => $new_value );
        return 1;
    }

    # Return the current changeset branch classification
    else {
        return $changeset ? $changeset->branch_classification : '';
    }
}
#------------------------------------------------------------------------------
#  install_sighandler()
#       Signal handler routine
#  Params:
#       Signal Name - the name of the signal causing the routine to run
#  Returns:
#       nothing
#------------------------------------------------------------------------------
sub install_sighandler {
    $SIG{'INT'}  = \&sig_handler if exists $SIG{'INT'};
    $SIG{'HUP'}  = \&sig_handler if exists $SIG{'HUP'};
    $SIG{'QUIT'} = \&sig_handler if exists $SIG{'QUIT'};
    $SIG{'TERM'} = \&sig_handler if exists $SIG{'TERM'};
}

sub sig_handler {
    my ($sig) = @_;
    warn("\nCaught signal $sig -- aborting cc_updver_comp.\n");
    cc_view_exit(1);
}

