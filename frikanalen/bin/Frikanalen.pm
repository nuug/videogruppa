#
# Support library for script parsing the getfiled/filelog files.
#
# $Id: FileLog.pm 18293 2010-09-17 08:39:47Z pre $
#

package Frikanalen;
require Exporter;

# SOAP:Lite må modifiseres til å gjøre ting på MS måten :-/
use SOAP::Lite on_action => sub {sprintf '%s/%s', @_}, ;

our $VERSION = 0.01;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(
                  getEpgUrls
                  );

sub getEpgUrls {
    my $soap = new SOAP::Lite
        -> uri('http://tempuri.org')
        -> proxy('http://communitysite1.frikanalen.tv/CommunitySite/EpgWebService.asmx');
    my $res;
    my $obj = $soap->GetEpgUrls;
    unless ($obj->fault) {
        return $obj->result->{string};
    } else {
#        print Dumper($obj);
        print $obj->fault->{faultstring}, "\n";
        return undef;
    }
}


1;
