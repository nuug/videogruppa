#!/usr/bin/perl
#
# Script for adding start/end poster and convert to frikanalen
# acceptable avi format anamporphic PAL with pillarboxing
#
# DV PAL Anamophic i en AVI-fil eller på en DV/DVCam-tape (25 Mbit DV,
# 25 fps, interlaced, lower field first, 720x576
#
# See also
# http://www.frikanalen.tv/lage-tv/mange-spør-om-formater-og-logistikk
# http://kevinlocke.name/bits/2012/08/25/letterboxing-with-ffmpeg-avconv-for-mobile/
# (export INPUT_FILE=Nina_Paley_tribute-to-EFF.m4v OUTPUT_FILE=Nina_Paley_tribute-to-EFF.avi MAX_WIDTH=720 MAX_HEIGHT=576; avconv     -i "$INPUT_FILE"     -map 0     -vf "scale=iw*sar*min($MAX_WIDTH/(iw*sar)\,$MAX_HEIGHT/ih):ih*min($MAX_WIDTH/(iw*sar)\,$MAX_HEIGHT/ih),pad=$MAX_WIDTH:$MAX_HEIGHT:(ow-iw)/2:(oh-ih)/2"     -c:v libx264     -vprofile baseline -level 30     -c:a libvo_aacenc     "$OUTPUT_FILE")

# Script is work in progress 2010-09-04 /JB
# standard backggrund for NUUG is in ./lib/graphic/tv-bg.png (relative
# to script location in svn-tree)
#
# ffmpeg tip for videos with wrong field order
# http://ffmpeg.org/ffmpeg-all.html#yadif-1
# -vf yadif=parity=tff or bff (top field first or bottom field first)
#
# metafile format is like this:
#
#title=Radioamatørenes sporingssystem
#presenter=Øyvind Hanssen
#date=2009-03-17
#place=Oslo
#venue=Høgskolen i Oslo
#url=http://www.nuug.no/
#organizer=Petter Reinholdtsen
#introduction=Petter Reinholdtsen
#email=sekretariat@nuug.no
#aspect=4:3
#camera=Stian Hübener, Hans Petter Fjeld
#videomixer=Ole Kristian Lien
#sound=?
#spokenlanguage=no
#clipin=1:20
#clipout=1:20:20
#
# PS: If this script is used on an sshfs mounted filesystem, the
# option sshfs -o workaround=rename must be used .  If not,
# normalize-audio will just silently fail and no audio normalization
# will take place.

use strict;
use warnings;

use Data::Dumper;
use Getopt::Std;
use File::Spec;

my %opts;
my $intro_length = 7;
my $pid = $$;

getopts('di:m:o:b:s:S:', \%opts);
my $debug = $opts{d} || 0;
my $workdir = "./fk-temp-$pid";
my $startposter = "$workdir/startposter.jpg";
my $endposter = "$workdir/endposter.jpg";
my $tmp_dvfile = "$workdir/before-normalize.dv";
my $metafile;
my $srcfile;
my $srtfile;
my $bgfile;
my $outputfile;

# FIXME: should be -23 LUFS, but normalize-audio do not understand that scale
my $soundlevel_dbfs = '-17dBFS';

my $MAX_WIDTH = 720;
my $MAX_HEIGHT = 576;

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
  # Convert to absolute path to make sure file names with colon in them are
  # not interpreted as URLs.
  $srcfile = File::Spec->rel2abs($opts{'i'});
} else {
  usage();
  exit 1;
}
my $subdelay = "";

if ( $opts{'s'} ) {
  $srtfile = getsrtfile();
  if ( ! -f $srtfile ) {
   print "$srtfile does not exist\n";
   exit 1 ;
  }
  if ( $opts{'S'} ) {
   $subdelay = "-subdelay $opts{'S'}";
  }
}



`mkdir -p $workdir`;

create_startposter_png($startposter,$bgfile);
create_endposter_png($endposter,$bgfile);
my $outfile = File::Spec->rel2abs($opts{'o'});

my $framerate = 25; # frames per second
my $durationframes = $intro_length * $framerate;
my @cmd = ("melt");

# Define output profile
push(@cmd, "-profile", "dv_pal_wide");

# Add intro page for a few seconds.
push(@cmd, $startposter, "out=$durationframes");

# Then the video itself
push(@cmd, "$srcfile");

push(@cmd, "in=" . duration2sec($meta->{'clipin'}) * $framerate)
     if (exists $meta->{'clipin'});
push(@cmd, "out=" . duration2sec($meta->{'clipout'}) * $framerate)
     if (exists $meta->{'clipout'});

# Next, the out image
push(@cmd, $endposter, "out=$durationframes");

# The outfile must be a .dv file for melt to pick good defaults.  If
# it is .avi, the video quality is very bad.
push(@cmd, "-consumer", "avformat:$tmp_dvfile"),

# FIXME missing subtitle handling
runcmd(@cmd
# http://www.mltframework.org/bin/view/MLT/ConsumerAvformat#field_order
# http://www.frikanalen.tv/lage-tv/mange-spør-om-formater-og-logistikk
# lower field first
#      , "field_order=tb"
     );

normalize_audio($tmp_dvfile, $outfile);

if ( -d $workdir ) {
    `rm -rf $workdir`;
}

#### Functions #########

sub usage {
    print <<EOF;
Usage: $0 -i inputfile.dv -m metafile -o outputfile.avi -b backgroundfile.png [-s /dir/where/srtfiles/are ]

If -s is given the script expects a file named <basename_of_raw_file>.srt
located in the path given as arg to -s option
EOF
}

sub duration2sec {
    my $str = shift;
    my $duration = 0.0;
    for my $part (split(/:/, $str)) {
        $duration *= 60.0;
        $duration += $part;
    }
    return $duration;
}

sub read_meta {
  my $ret;

  # Set some default values
  $ret->{'url'} = 'http://www.nuug.no/';
  $ret->{'email'} = 'sekretariat@nuug.no';
#  $ret->{'editor'} = 'Petter Reinholdtsen';

  open M, "$metafile" or die "Cannot open $metafile for read :$!";
  while (<M>) {
    chomp;
    my @l = split("=",$_);
    if (defined $l[1]) {
       $ret->{$l[0]} = $l[1];
    }
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
#  print $title;
  my $cols = 29;
  my $count = 0 ;
  my $ln = 0;
  my @lines = ('', '', '', '');
  my @words = split(" ",$title);
  foreach my $word (@words) {
    $count += count_words_n_space($word);
    if ($count < $cols ) {
      $lines[$ln] .= "$word ";
    } else {
#      print "$lines[$ln]\n";
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
  my @cmd =
      ("convert", "$bgfile",
       "-fill", "white", "-gravity", "NorthWest",
       "-pointsize", "36",
       "-draw", "\"text 450,167 \'Foreningen NUUG presenterer\'\"",
       "-pointsize", "72",
       "-draw", "\"text 450,247 \'$meta->{'presenter'}\'\"",
       "-pointsize", "60",
       "-draw", "\"text 450,380 \'$title_lines->[0]\'\"",
       "-draw", "\"text 450,460 \'$title_lines->[1]\'\"",
       "-draw", "\"text 450,540 \'$title_lines->[2]\'\"",
       "-draw", "\"text 450,620 \'$title_lines->[3]\'\"",
       "-pointsize", "36",
       "-draw", "\"text 52,790 \'$meta->{'url'}\'\"",
       "-draw", "\"text 52,826 \'$meta->{'email'}\'\"",
       "-draw", "\"text 750,640 \'$meta->{'place'}, $meta->{'date'}\'\" $name");

  if ( !runcmd(@cmd) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
}

sub create_endposter_png {
# $cmd_body .= " -draw "text $left_margin,$pos \'$n: $meta->{$n}\'"
  my %keyword_map = (
      "introduction" => "Introdusert av",
#      "editor" => "Redaktør",
      "venue" => "Lokaler",
      "organizer" => "Organisert av",
      "camera" => "Kamera",
      "sound" => "Lydoppsett",
      "videomixer" => "Videomiks",
      "teksting" => "Teksting",
      );
  my $line_distance = 52;
  my $text_size = 40;
  my $pos = 180;
  my $left_margin = 450;
  my $cmd_body = "";
  my @endnotes;
  my @endnote_tags = ("introduction","organizer", "venue","camera","sound","videomixer","editor","teksting" );
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
  my @cmd =
      ("convert", "$bgfile",
       "-pointsize", "$text_size",
       "-fill", "white",
       "-gravity", "NorthWest",
       "$cmd_body",
       "-pointsize", "36",
       "-draw", "\"text 52,790 \'$meta->{'url'}\'\"",
       "-draw", "\"text 52,826 \'$meta->{'email'}\'\"",
       "-draw", "\"text 750,640 \'$meta->{'place'}, $meta->{'date'}\'\" $name");
  if ( !runcmd(@cmd) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
}

sub normalize_audio {
    my ($sourcedv, $targetdv) = @_;
    my $f = "ffmpeg -i $sourcedv -ac 2 -vn -f wav -y $workdir/sound.wav";
    if ( !runcmd($f) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
    $f = "normalize-audio -a $soundlevel_dbfs $workdir/sound.wav";
    if ( !runcmd($f) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
    $f = "ffmpeg -i $sourcedv -i $workdir/sound.wav -map 0.0 -map 1.0 -acodec copy -vcodec copy -y $targetdv";
    if ( !runcmd($f) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
    return $targetdv;
}

sub getsrtfile {
    $opts{'i'} =~ /.+\/(.+)\..+$/; # Could be .dv or .avi or whatnot. This strips it off anyway.
    return "$opts{'s'}/$1.srt";
}

sub runcmd {
  my $cmd = join(" ", @_);
  print "Cmd: $cmd\n" if $debug;
  my $f = `$cmd  || echo  -n -1`;
  return 0 if ( $f eq -1 );
  return 1;
}
