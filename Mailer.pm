#!/usr/cisco/bin/perl5.8 -w 

package Mailer;


use lib '/users/sabind/LOCAL_INSTALLS/my_perl/lib';
use lib '/users/sabind/LOCAL_INSTALLS/my_perl/lib/site_perl/5.22.0';
use lib '/users/sabind/LOCAL_INSTALLS/my_perl/external_libs/lib/site_perl/5.22.0';
use lib "/usr/cisco/packages/dbdoracle/9.2.0";

use strict;
use Exporter;
use MIME::Lite::TT::HTML;

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

    $msg->send();

}

