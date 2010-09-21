#!/usr/bin/perl

# Script for adding start/end poster and convert to frikanalen acceptable avi format anamporphic PAL with pillarboxing
# Script is work in progress 2010-09-04 /JB
# standard backggrund for NUUG is in ./lib/graphic/tv-bg.png (relative to script location in svn-tree)
# metafile format is like this:
#
#presenter=Jørgen Fjeld
#title=Ruby on Rails enterprise behov , en velidg lang tittel som jeg lurer på hvordan vil se ut på forsiden av NUUGS video sldf   lsdkfms msf
#date=2010-03-09
#place=Oslo
#url=http://www.nuug.no
#endnote1=Redaktør:
#endnote2=NUUG
#endnote3=
#endnote4=email: sekretariat@nuug.no
#

use strict;
use warnings;

use Data::Dumper;
use Getopt::Std;

my %opts;
my $intro_length = 2;
my $pid = $$;

getopts('i:m:o:b:s', \%opts);

my $workdir = "./fk-temp-$pid";
#my $startposter = "$workdir/startposter.png";
my $startposter = "$workdir/startposter.jpg";
#my $endposter = "$workdir/endposter.png";
my $endposter = "$workdir/endposter.jpg";
my $startposter_dv = "$workdir/startposter.dv";
my $endposter_dv = "$workdir/endposter.dv";
my $metafile;
my $srcfile;
my $srtfile;
my $bgfile;
my $outputfile;
my $normalize_cmd = "/usr/bin/normalize-audio";
# http://normalize.nongnu.org/
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


`mkdir -p $workdir`;

if ( $ARGV[0] && $ARGV[0] eq 'front' ) {
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
 $srtfile = getsrtfile();
}




create_startposter_png($startposter,$bgfile);
create_endposter_png($endposter,$bgfile);
gen_dv_from_png($startposter,3,$startposter_dv);
gen_dv_from_png($endposter,3,$endposter_dv);
my $normalized_video_body = gen_video_body($srcfile);
glue_dv($opts{'o'},$startposter_dv,$normalized_video_body,$endposter_dv);

#### Functions #########

sub usage {
 print"Usage: $0 -i inputfile.dv -m metafile -o outputfile.avi -b backgroundfile.png [-s /dir/where/srtfiles/are ] \n\n";
 print "If -s is given the script expects a file named <basename_of_raw_file>.srt \n";
 print "located in the path given as arg to -s option\n\n";
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

sub count_words_n_space {
 my $word = shift;
 my $count = 0;
 while ( $word =~ /(.)/g ) { $count++; }
 $count++;
 return $count;
}

sub break_title {
 my $title = shift;
 print $title;
 my $cols = 30;
 my $count = 0 ;
 my $ln = 0;
 my @lines;
 my @words = split(" ",$title);
 foreach my $word (@words) {
  $count += count_words_n_space($word);
  if ($count < $cols ) {
   $lines[$ln] .= "$word ";
  } else {
   print "$lines[$ln]\n";
   $count = 0;
   $ln++;
   $count += count_words_n_space($word);
   $lines[$ln] .= "$word ";
  }
 }
 return \@lines;
}

sub create_startposter_png {
 my $name = shift;
 my $title_lines = break_title($meta->{'title'});
 my $bgfile = shift;
 my $f = `convert $bgfile -pointsize 72 -fill white -gravity NorthWest -draw "text 450,167 \'$meta->{'presenter'}:\'" -pointsize 60 -draw "text 450,300 \'$title_lines->[0]\'" -draw "text 450,380 \'$title_lines->[1]\'" -draw "text 450,460 \'$title_lines->[2]\'" -draw "text 450,540 \'$title_lines->[3]\'" -pointsize 36 -pointsize 36 -draw "text 52,790 \'$meta->{'url'}\'" -draw "text 750,640 \'$meta->{'place'}: $meta->{'date'}\'" $name || echo  -n -1`;
 if ( $f eq -1 ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
}

sub create_endposter_png {
 # $cmd_body .= " -draw "text $left_margin,$pos \'$n: $meta->{$n}\'"
 my %keyword_map = (
        "introduction" => "Introdusert av",
        "editor" => "Redaktor",
        "email" => "E-post",
        "organizer" => "Organisert av",
        "camera" => "Kamera-ansvarlig",
        "sound" => "Lyd-ansvarlig",
        "videomixer" => "Videomixer-ansvarlig",
        );
 my $line_distance = 52;
 my $text_size = 40;
 my $pos = 180;
 my $left_margin = 450;
 my $cmd_body = "";
 my @endnotes;
 my @endnote_tags = ("introduction","organizer","camera","sound","videomixer","editor","email" );
 foreach my $n ( @endnote_tags ) {
  if ($meta->{$n} ) {

   # Only show organizer if introduction and organizer are identical.
   next if ("introduction" eq $n && $meta->{$n} eq $meta->{'organizer'});

   push(@endnotes,"$keyword_map{$n}: $meta->{$n}");
  }
 }
 foreach my $line ( @endnotes ) {
  $cmd_body .= "  -draw \"text $left_margin,$pos \'$line \'\"";
  $pos += $line_distance;
 }
 my $name = shift;
 my $bgfile = shift;
 my $f = `convert $bgfile -pointsize $text_size -fill white -gravity NorthWest $cmd_body -pointsize 36 -draw "text 52,790 \'$meta->{'url'}\'" -draw "text 750,640 \'$meta->{'place'}: $meta->{'date'}\'" $name|| echo  -n -1`;
 if ( $f eq -1 ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
}

sub gen_dv_from_png {

my $png_file = shift;
my $length = shift;
my $outputvid = shift;
my $f =  `ffmpeg -loop_input -t $length  -i $png_file  -f image2 -f s16le -i /dev/zero -target pal-dv -padleft 150 -padright 150 -s 420x576 -y $outputvid || echo  -n -1`;
 if ( $f eq -1 ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
}

sub gen_video_body {
 my $source = shift;
 my $mod_dv;
 if ( $meta->{'aspect'} eq "4:3" || $opts{'s'} ) {
   my $cmd ;
   $mod_dv = "$workdir/mod.dv";
   $cmd = "mencoder -oac pcm -of lavf -ovc lavc -lavcopts vcodec=dvvideo:vhq:vqmin=2:vqmax=2:vme=1:keyint=25:vbitrate=2140:vpass=1 ";
   if ( $meta->{'aspect'} eq "4:3" ) {
     $cmd .= "-vf-add expand=1000::::: -vf-add scale=720:576 ";
   }
   if ( $srtfile ) {
    $cmd .= " -sub $srtfile -utf8 ";
   }
   $cmd .= "-o $mod_dv $source ";
   #print "Command= $cmd \n\n";
   my $f = `$cmd  || echo  -n -1` ;
    if ( $f eq -1 ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
   $source = $mod_dv;
 }
 my $dest = normalize_sound($source);
 return $dest;
}

sub normalize_sound {
 my $dvfile = shift;
 my $new_dvfile = "$workdir/normalized-body.dv";
 my $f = `ffmpeg -i $dvfile  -ac 2 -vn -f wav -y $workdir/sound.wav  || echo  -n -1`;
 if ( $f eq -1 ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
 $f = `$normalize_cmd -a $soundlevel_dbfs   $workdir/sound.wav || echo  -n -1`;
 if ( $f eq -1 ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
 $f = `ffmpeg -i $workdir/sound.wav -ac 2 -acodec copy  -i $dvfile -vcodec copy  -map 1:0 -map 0.0 -f dv -y $new_dvfile || echo  -n -1`;
 if ( $f eq -1 ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
 return $new_dvfile;
}


sub glue_dv {
 my $outfile = shift;
 my @infiles = @_;
 my $cmd = 'cat '.join(' ',@infiles).' |  ffmpeg -i -  -aspect 16:9 -acodec pcm_s16le -vcodec dvvideo -y '.$outfile.' -f avi'  ;
# my $cmd = 'cat '.join(' ',@infiles).' |  dvgrab -size 0 -stdin -f dv2 -opendml '.$outfile  ;
 my $f = `$cmd  || echo  -n -1`;
 if ( $f eq -1 ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
 if ( -d $workdir ) {
   `rm -rf $workdir`;
 }
}


sub getsrtfile {
 my $base = $opts{'i'};
 $base =~ s/\..+$//; # Could be .dv or .avi or whatnot. This strips it off anyway.
 return "$opts{'s'}/$base.srt";
}
