#!/usr/cisco/bin/perl5.8 -w

use strict;
use warnings;
use lib '/usr/cisco/packages/cisco-perllib';
use lib '/users/sabind/EXTERNAL_LIBS/perl_libs';
use lib '/users/sabind/EXTERNAL_LIBS/perl_libs/lib/site_perl/5.8.8';
use MIME::Lite::TT::HTML;

print "hello\n";

my %hash_ref;
&mail( 'sabind', 'sabind', "[AI::] Found Regression Failures" );
sub mail {

    my ( $from, $to, $subject) = @_;
    chomp( $from, $to, $subject);
    my %options = ();
    $options{INCLUDE_PATH} = "/users/sabind/SCRIPTS/email_templates";

    my $msg = MIME::Lite::TT::HTML->new(
        From        => "$from\@cisco.com",
        To          => "$to\@cisco.com",
        Subject     => "$subject",
        TimeZone    => 'Asia/Shanghai',
        Encoding    => 'quoted-printable',
        Template    => { html => "mail4.html.tt", },
        Charset     => 'utf8',
        TmplOptions => \%options,
        TmplParams  => \%hash_ref,
    );

    $msg->send();

}


%hash_ref = (
                         'REQUEST_DESC' => '(6180676) v155_1_t_throttle NIGHTLY Build',
                         'END_TIME' => undef,
                         'BUILD_SEQ_NUM' => '117',
                         'START_TIME' => '15-JUN-15 03.21.00.000000 AM -07:00',
                         'NUM_IMAGE_LIST_BUILT' => '21',
                         'BUILD_DIR' => '/san2/CPY-v155_1_t_throttle.NIGHTLY_V155_1_T_THROTTLE-20150615_0321-117/vob/ios',
                         'BUILD_SERVER' => 'build-lnx-056',
                         'REQUEST_ID' => '6180676',
                         'LABEL_NAME' => 'NIGHTLY_V155_1_T_THROTTLE_201506150321',
                         'LOGDIR' => '/auto/beyond.build3/155t/logs/v155_1_t_throttle_Nightly//2015-06-15',
                         'REQUEST_TYPE' => 'NIGHTLY',
                         'BRANCH_NAME' => 'v155_1_t_throttle',
                         'NUM_IMAGE_LIST' => '69',
                         'NUM_IMAGE_LIST_FAILED' => '0'
          
        );




=pod
my $username = "8884297747";
my $password = "ankur101";
my $msg = "Hi from pgm";
my $to = "9035770701";
my $obj = Net::SMS::160By2->new($username, $password);
$obj->send_sms($msg, $to);