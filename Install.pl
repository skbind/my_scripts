#!/users/sabind/LOCAL_INSTALLS/my_perl/bin/perl
use warnings;
use strict;
use lib '/users/sabind/LOCAL_INSTALLS/my_perl/external_libs/lib/site_perl/5.22.0';

use Data::Dumper;
use MIME::Lite;
use MIME::Lite::TT::HTML;
use Email::Date::Format;
use MIME::Types;
use Mail::Address;
use Tie::IxHash;
print "hello\n";


=pod

MY PERL:
/users/sabind/LOCAL_INSTALLS/my_perl/bin/perl


INSTALL PERL LOCALLY:
-----------------------------------------------------

 http://www.cpan.org/src/
 
 Module:
 http://search.cpan.org/~timb/DBI-1.633/DBI.pm

 How to install from source

     wget http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz
     tar -xzf perl-5.22.0.tar.gz
     cd perl-5.22.0
     ./Configure -des -Dprefix=$HOME/localperl
     make
     make test
     make install


LIBS:
------------------------------------------------------

%	/users/sabind/LOCAL_INSTALLS/my_perl/lib
%	/users/sabind/LOCAL_INSTALLS/my_perl/external_libs/lib/site_perl/5.22.0


Installing perl module:
------------------------------------------------------

%	wget http://search.cpan.org/CPAN/authors/id/R/RJ/RJBS/MIME-Lite-3.030.tar.gz
%	tar xzf  MailTools-2.14.tar.gz
%	cd MailTools-2.14
%	/users/sabind/LOCAL_INSTALLS/my_perl/bin/perl Makefile.PL PREFIX=/users/sabind/LOCAL_INSTALLS/my_perl/external_libs
%	make
%	make insatll

Installing perl module (Modules don't have Makefile.PL):
------------------------------------------------------

% /users/sabind/LOCAL_INSTALLS/my_perl/bin/perl Build.PL # you may not be able to provide your local path
# run 'Build installdeps' if any dependent modules requre to be installed. 
% ./Build && ./Build test
% ./Build install