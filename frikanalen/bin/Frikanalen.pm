#
# Support library for script talking to the Frikanalen API
#

package Frikanalen;
require Exporter;

# SOAP:Lite må modifiseres til å gjøre ting på MS måten :-/
use SOAP::Lite on_action => sub {sprintf '%s/%s', @_}, ;

our $VERSION = 0.01;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(
                  parse_duration
                  );

# Convert "04:05.12" to 4 * 60 + 5.12
sub parse_duration {
    my $durationstr = shift;
    my @parts = split(/:/, $durationstr);
    my $duration = 0;
    while (my $part = shift @parts) {
        $duration *= 60;
        $duration += int($part);
    }
#    print "$durationstr = $duration\n";
    return $duration;
}

1;
