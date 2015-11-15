#!/depot/perl-5.8.3/bin/perl

package Mail;

use strict;
use Exporter;
use MIME::Lite::TT::HTML;
use Data::Dumper;

my @ISA    = ("Exporter");
my @Export = ("mail");

sub mail {

    my ( $from, $to, $subject, $hash_ref, $template ) = @_;
    chomp( $from, $to, $subject, $hash_ref, $template );

    my %params  = %{$hash_ref};
    my %options = ();
    $options{INCLUDE_PATH} = "/users/sabind/SCRIPTS/email_templates";

    my $msg = MIME::Lite::TT::HTML->new(
        From        => "$from\@cisco.com",
        To          => "$to\@cisco.com",
        Subject     => "$subject",
        TimeZone    => 'Asia/Shanghai',
        Encoding    => 'quoted-printable',
        Template    => { html => "$template", },
        Charset     => 'utf8',
        TmplOptions => \%options,
        TmplParams  => \%params,
    );
    #my $attach = $params{'tsv_log'};
    #chomp($attach);
    #print "attach = $attach\n";
    #$msg->attach(
    #Type     => 'TEXT',
    #Path     => "$attach",
	#) if( -e "$attach");

    $msg->send();

}

