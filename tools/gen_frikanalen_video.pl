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

my %opts;
my $intro_length = 2;

getopts('i:m:o:b:s:e', \%opts);

my $workdir = "./fk-temp";
my $startposter = "$workdir/startposter.png";
my $endposter = "$workdir/endposter.png";
my $startposter_dv = "$workdir/startposter.dv";
my $endposter_dv = "$workdir/endposter.dv";
my $metafile;
my $srcfile;
my $srtfile;
my $bgfile;
my $outputfile;
my $normalize_cmd = "/usr/local/bin/normalize";
my $soundlevel_dbfs = '-18dBFS';

#foreach (keys %opts ) { print "$_\n"; };
if ( $opts{'m'} ) { 
 $metafile = $opts{'m'} ; 
} else { 
 usage();
 exit 1;
}

my $meta = read_meta();

if ( $opts{'b'} ) { 
 $bgfile = $opts{'b'} ; 
} else { 
 usage();
 exit 1;
}

if ( -d $workdir ) {
 `rm -rf $workdir`;
}

`mkdir -p $workdir`;

if ( $ARGV[0] eq 'front' ) {
 create_startposter_png($startposter,$bgfile);  
 print "Frontpage in $startposter\n";
 print "Check it out !\n";
 exit ;
}

if ( $opts{'o'} ) { 
 $outputfile = $opts{'o'} ; 
} else { 
 usage();
 exit 1;
}

if ( $opts{'i'} ) { 
 $srcfile = $opts{'i'} ; 
} else { 
 usage();
 exit 1;
}

if ( $opts{'s'} ) { 
 $srtfile = $opts{'s'} ; 
 print "Using subtitle file:  $srtfile \n";
}




create_startposter_png($startposter,$bgfile);
create_endposter_png($endposter,$bgfile);
gen_dv_from_png($startposter,3,$startposter_dv);
gen_dv_from_png($endposter,3,$endposter_dv);
my $normalized_video_body = gen_video_body($srcfile); 
glue_dv($opts{'o'},$startposter_dv,$normalized_video_body,$endposter_dv);

#### Functions #########

sub usage {
 print"Usage: $0 -i inputfile.dv -m metafile -o outputfile.avi -b backgroundfile.png [-s subtitlefile.srt -e] \n";
 print "-e option does pillarboxing of 4/3 content into anamorphic 4/3\n";
 print "To only produce a frontpage png file to check layout:\n";
 print "$0 -m metafile -b backgroundfile front\n\n";
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

sub create_startposter_png {
 my $name = shift;
 my $bgfile = shift;
 my $f = `convert $bgfile -pointsize 72 -fill white -gravity NorthWest -draw "text 450,167 \'$meta->{'presenter'}:\'" -pointsize 60 -draw "text 450,300 \'$meta->{'title1'}\'" -draw "text 450,380 \'$meta->{'title2'}\'" -draw "text 450,460 \'$meta->{'title3'}\'" -pointsize 36 -pointsize 36 -draw "text 52,790 \'$meta->{'url'}\'" -draw "text 750,640 \'$meta->{'date-place'}\'" $name`;
 print $f;
}

sub create_endposter_png {
 my $name = shift;
 my $bgfile = shift;
 my $f = `convert $bgfile -pointsize 72 -fill white -gravity NorthWest -draw "text 450,167 \'$meta->{'endnote1'}\'" -pointsize 60 -draw "text 450,300 \'$meta->{'endnote2'}\'" -draw "text 450,380 \'$meta->{'endnote3'}\'" -draw "text 450,460 \'$meta->{'endnote4'}\'" -pointsize 36 -pointsize 36 -draw "text 52,790 \'$meta->{'url'}\'" -draw "text 750,640 \'$meta->{'date-place'}\'" $name`;
 print $f;
}

sub gen_dv_from_png {

my $png_file = shift;
my $length = shift;
my $outputvid = shift;
`ffmpeg -loop_input -t $length -i $png_file  -f image2 -f s16le -i /dev/zero -target pal-dv -y $outputvid`;
}

sub gen_video_body {
 my $source = shift; 
 my $mod_dv;
 if ( $opts{'e'} || $opts{'s'} ) {
   my $cmd ;
   $mod_dv = "$workdir/mod.dv";
   $cmd = "mencoder -oac pcm -of lavf -ovc lavc -lavcopts vcodec=dvvideo:vhq:vqmin=2:vqmax=2:vme=1:keyint=25:vbitrate=2140:vpass=1 ";
   if ( $opts{'e'} ) {
     $cmd .= "-vf-add expand=960::::: -vf-add scale=720:576 ";
   } 
   if ( $srtfile ) {
    $cmd .= " -sub $srtfile -utf8 ";
   }
   $cmd .= "-o $mod_dv $source ";
   #print "Command= $cmd \n\n";
   system("$cmd");
   $source = $mod_dv;
 }
 my $dest = normalize_sound($source); 
 return $dest;
}

sub normalize_sound {
 my $dvfile = shift;
 my $new_dvfile = "$workdir/normalized-body.dv";
 system("ffmpeg -i $dvfile  -ac 2 -vn -f wav -y $workdir/sound.wav");
 system("$normalize_cmd -a $soundlevel_dbfs   $workdir/sound.wav");
 my $normret = ($? >> 8);
 system("ffmpeg -i $workdir/sound.wav -ac 2 -acodec copy  -i $dvfile -vcodec copy  -map 1:0 -map 0.0 -f dv -y $new_dvfile");
 my $ffret = ($? >> 8);
 print "-- ". $ffret ." -- ". $normret ."\n";
 if ( $ffret == 0 && $normret == 0 ) { 
   system("rm $workdir/sound.wav $dvfile");
 } else { die "Soundfile extraction or re-merge failed\n"; }
 return $new_dvfile;
}


sub glue_dv {
 my $outfile = shift;
 my @infiles = @_;
 my $cmd = 'cat '.join(' ',@infiles).' |  ffmpeg -i -  -acodec pcm_s16le -vcodec dvvideo -y '.$outfile.' -f avi'  ;
 system($cmd);
}

