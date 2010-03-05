#!/usr/bin/perl -w

# Author: Jarle Bjørgeengen
# Date: 2010-03-05
# License: GNU General Public license

# Script to look up meta-data from video-id

#use Data::Dumper;
use XML::Simple;

my $meta_xml;
my $videoid;

if ($ARGV[1]) {
  $meta_xml = XMLin("$ARGV[0]");
  $videoid = "id_".$ARGV[1];
} else { 
 usage();
}
sub usage {
 print "$0: meta-xml-file videoid\n";
}

foreach my $key (keys %{$meta_xml->{$videoid}}) { 
 print "$key: $meta_xml->{$videoid}->{$key}\n"; 
} 

