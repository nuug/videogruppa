#!/usr/bin/perl

# Script for adding start/end poster and convert to frikanalen acceptable avi format anamporphic PAL with pillarboxing
# Script is work in progress 2010-08-07 /JB
# metafile format is like this:
# 
# cat test.meta
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
my $intro_length = 2;

getopts('i:m:o:b:s:e', \%opts);

my $metafile;
my $srcfile;
my $srtfile;
my $bgfile;
my $outputfile;
my $workdir = "./fk-temp";

#foreach (keys %opts ) { print "$_\n"; };
print "-";
if ( $opts{'m'} ) { 
 $metafile = $opts{'m'} ; 
} else { 
 usage();
 exit 1;
}
print "-";
if ( $opts{'o'} ) { 
 $outputfile = $opts{'o'} ; 
} else { 
 usage();
 exit 1;
}
print "-";

if ( $opts{'b'} ) { 
 $bgfile = $opts{'b'} ; 
} else { 
 usage();
 exit 1;
}
print "-";

if ( $opts{'i'} ) { 
 $srcfile = $opts{'i'} ; 
} else { 
 usage();
 exit 1;
}
print "-";

if ( $opts{'s'} ) { 
 $srtfile = $opts{'s'} ; 
 print "Using subtitle file:  $srtfile \n";
}

if ( -d $workdir ) {
 `rm -rf $workdir`;
}

`mkdir $workdir`;

my $startposter = new File::Temp( UNLINK => 0, SUFFIX => '.png' );
my $startposter_name = $startposter->filename();
$startposter->close();
my $endposter = new File::Temp( UNLINK => 0, SUFFIX => '.png' );
my $endposter_name = $endposter->filename();
$endposter->close();
my $meta = read_meta();

my $front_poster_dv = gen_intro_dv($startposter_name,3);
my $video_body_dv = gen_video_body($srcfile); 
glue_dv($opts{'o'},$front_poster_dv,$video_body_dv);

#### Functions #########

sub usage {
 print"Usage: $0 -i inputfile.dv -m metafile -o outputfile.avi -b backgroundfile.png [-s subtitlefile.srt -e] \n";
 print "-e option does pillarboxing of 4/3 content into anamorphic 4/3\n";
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

sub gen_intro_dv {
my $png_file = shift;
my $length = shift;
my $outputvid = "$workdir/front-poster.dv";
 create_startposter();
`ffmpeg -loop_input -t $length -i $png_file  -f image2 -f s16le -i /dev/zero -target pal-dv -y $outputvid`;
 return $outputvid;
}

sub gen_video_body {
 my $source = shift; 
 my $dest = "$workdir/body.dv";
 if ( ! $opts{'e'} && ! $opts{'s'} ) {
  print "No encoding needed\n";
  return $source;
 }
 my $cmd = "mencoder -oac pcm -of lavf -ovc lavc -lavcopts vcodec=dvvideo:vhq:vqmin=2:vqmax=2:vme=1:keyint=25:vbitrate=2140:vpass=1 ";
 if ( $opts{'e'} ) {
   $cmd .= "-vf-add expand=960::::: -vf-add scale=720:576 ";
 } 
 if ( $srtfile ) {
  $cmd .= " -sub $srtfile -utf8 ";
 }
 $cmd .= "-o $dest $source ";
 print "Command= $cmd \n\n";
 system("$cmd");
 return $dest;
}


sub glue_dv {
 my $outfile = shift;
 my @infiles = @_;
 my $cmd = 'cat '.join(' ',@infiles).' |  ffmpeg -i -  -acodec pcm_s16le -vcodec dvvideo -y '.$outfile.' -f avi'  ;
 system($cmd);
}

