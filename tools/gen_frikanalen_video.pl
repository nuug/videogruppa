#!/usr/bin/perl

# Script for adding start/end poster and convert to frikanalen acceptable avi format anamporphic PAL with pillarboxing
# Script is work in progress 2010-08-07 /JB
# cat test.meta
# metafile format is like this:
# title1=Dette er Tittlelen
# title2=Dette er  andre linje i Tittlelen
# title3=Dette er øæå 3. linje i Tittlelen
# presenter=Even stikkbakken
# date-place=2010-08-07 - Oslo
# url=http://www.nuug.no

use strict;
use warnings;

use Data::Dumper;
use Getopt::Std;
use File::Temp;

my %opts;

getopts('m:o:b:', \%opts);

my $metafile;
my $bgfile;
my $outputfile;

#foreach (keys %opts ) { print "$_\n"; };

if ( $opts{'m'} ) { 
 $metafile = $opts{'m'} ; 
} else { 
 usage();
 exit 1;
}
if ( $opts{'o'} ) { 
 $outputfile = $opts{'o'} ; 
} else { 
 usage();
 exit 1;
}

if ( $opts{'b'} ) { 
 $bgfile = $opts{'b'} ; 
} else { 
 usage();
 exit 1;
}

my $startposter = new File::Temp( UNLINK => 0, SUFFIX => '.png' );
my $startposter_name = $startposter->filename();
$startposter->close();
my $endposter = new File::Temp( UNLINK => 0, SUFFIX => '.png' );
my $endposter_name = $endposter->filename();
$endposter->close();
my $meta = read_meta();

create_startposter();

#### Functions #########

sub usage {
 print"Usage: $0 -m metafile -o outputfile -b bgfile\n";
}

sub read_meta {
 my $ret;
 open M, "$metafile" or die "Cannot open $metafile for read :$!";
 while (<M>) {
  chomp;
  my @l = split("=",$_);
  $ret->{$l[0]} = $l[1];
 }
 close M;
 return $ret;
}

sub create_startposter {
 my $f = `convert $bgfile -pointsize 72 -fill white -gravity NorthWest -draw "text 450,167 \'$meta->{'presenter'}:\'" -pointsize 60 -draw "text 450,300 \'$meta->{'title1'}\'" -draw "text 450,380 \'$meta->{'title2'}\'" -draw "text 450,460 \'$meta->{'title3'}\'" -pointsize 36 -pointsize 36 -draw "text 52,790 \'$meta->{'url'}\'" -draw "text 750,640 \'$meta->{'date-place'}\'" $startposter_name`;
 print "$startposter_name\n";
 print $f;
}

