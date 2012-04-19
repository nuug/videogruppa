#!/usr/bin/perl

# Author: Jarle Bjørgeengen
# Date: 2009-03-01
# License: GNU General Public license

# Script for å sync'e over nye ogv filer fra frikanalen
# Avhenger av meta.xml produsert av update_meta_xml.pl
#
# http://wiki.nuug.no/grupper/video/pubfrikanalen

#use Data::Dumper;
use XML::Simple;
my $localvideo_dir = '/data/video/frikanalen';
my $localthumbs_dir = '/data/video/frikanalen/thumbs';
my $meta = XMLin("$localvideo_dir/meta.xml");

# Make sure convert is in the path
$ENV{PATH} = $ENV{PATH} . ":/usr/local/bin";

print " Local videos $#localvideos\n";
&get_new_vids;

###### Functions #######

sub get_new_vids {
  foreach my $metaid (keys %$meta) {
    $metaid =~ /id_(.+)/;
    $file_id = $1;
    print "Checking if $file_id is already here\n" if $ARGV[0] eq "debug";
    # Uncomment this line if you want to refresh _all_ thumbs.
        #&get_thumb($meta->{$metaid}->{'ImageUri'},$file_id);
    $exists = 'false';
    unless ( -f "$localvideo_dir/$file_id.ogv") {
      print "Fetching video $file_id \n" if $ARGV[0] eq "debug";
      if  ($meta->{$metaid}->{'VideoOgvUri'} =~ /^http:/) {
        get_scp_vid($meta->{$metaid}->{'VideoOgvUri'},$file_id);
      }
    } else {
      print "$file_id is here\n" if  $ARGV[0] eq "debug";
    }
    unless ( -f "$localthumbs_dir/$file_id.jpg") {
      get_thumb($meta->{$metaid}->{'ImageUri'},$file_id);
    }
  }
}


sub get_thumb {
  my ($url, $file_id) = @_;
  # foreach my $metaid (keys %$meta) {
    print "Fetching thumbnail for video $file_id\n";
    `/usr/local/bin/wget --quiet -O - $url |convert - -scale 25%  $localthumbs_dir/$file_id.jpg`;
    # }
}


sub get_http_vid {
  my ($url, $file_id) = @_;
  my $r = 1;
  print "Fetching  video $file_id\n";
  while ($r != 0 ) {
    $r = `/usr/local/bin/wget --quiet -r -O "$localvideo_dir/$file_id.ogv" "$url"`;
  }
}

sub get_mms_vid {
  my ($url, $file_id) = @_;
  my $r = 1;
  print "Fetching  video $file_id\n";
  while ($r != 0 ) {
    $r =  `mplayer -dumpstream -dumpfile "$localvideo_dir/$file_id.wmv" $url > /dev/null 2>&1`;
  }
}

# Ny metode for Ã¥ komme rundt ikke-fungerende ur'er mot frontent.frikanalen.tv
# Jarle 2012-04-19 

sub get_scp_vid {
 my $url = shift;
 my $file_id = shift;
 $url =~ /^http:\/\/frontend\.frikanalen\.tv\/media\/(.+)$/;
 my $src_path = $1;
 my $ssh_loc = 'jarle@borch.frikanalen.no:/mnt/media/';
 my $ssh_id_file = '/home/jarle/.ssh/id_tx_fk';
 print "Getting $file_id.ogv\n";
 `/usr/bin/scp -q -i $ssh_id_file $ssh_loc$src_path $localvideo_dir/$file_id.ogv`; 
}

