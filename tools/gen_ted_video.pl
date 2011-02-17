#!/usr/bin/perl

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
#
# PS: IF this script is used on an sshfs mounted filesystem, the option sshfs -o workaround=rename must be used . 
# If not, normalize-audio will just silently fail and no audio normalization will take place. 

use strict;
use warnings;

use Data::Dumper;
use Getopt::Std;

my %opts;
my $intro_length = 10;
my $pid = $$;

getopts('di:m:o:b:s:S:', \%opts);
my $debug = $opts{d} || 0;
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




#create_startposter_png($startposter,$bgfile);
#create_endposter_png($endposter,$bgfile);
#gen_dv_from_png($startposter,$intro_length,$startposter_dv);
#gen_dv_from_png($endposter,$intro_length,$endposter_dv);
my $normalized_video_body = gen_video_body($srcfile);
glue_dv($opts{'o'},$normalized_video_body,$endposter_dv);

#### Functions #########

sub usage {
  print"Usage: $0 -i inputfile.dv -m metafile -o outputfile.avi -b backgroundfile.png [-s /dir/where/srtfiles/are ] \n\n";
  print "If -s is given the script expects a file named <basename_of_raw_file>.srt \n";
  print "located in the path given as arg to -s option\n\n";
}

sub read_meta {
  my $ret;

  # Set some default values
  $ret->{'url'} = 'http://www.nuug.no/';
  $ret->{'email'} = 'sekretariat@nuug.no';
  $ret->{'editor'} = 'Jarle Bjørgeengen';

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
      "editor" => "Redaktør",
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

sub gen_dv_from_png {

  my $png_file = shift;
  my $length = shift;
  my $outputvid = shift;
  my $f = "ffmpeg -loop_input -t $length  -i $png_file  -f image2 -f s16le -i /dev/zero -target pal-dv -padleft 150 -padright 150 -s 420x576 -y $outputvid";
  if ( !runcmd($f) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
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
      $cmd .= " -sub $srtfile -utf8 $subdelay -sub-bg-alpha 80 -sub-bg-color 50 -subfont-text-scale 3 -subpos 90 -subwidth 90  ";
    }
    $cmd .= "-o $mod_dv $source ";
    if ( !runcmd($cmd) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
    $source = $mod_dv;
  }
  my $dest = normalize_sound($source);
  return $dest;
}

sub normalize_sound {
  my $dvfile = shift;
  my $new_dvfile = "$workdir/normalized-body.dv";
  my $f = "ffmpeg -i $dvfile  -ac 2 -vn -f wav -y $workdir/sound.wav";
  if ( !runcmd($f) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
  $f = "$normalize_cmd -a $soundlevel_dbfs   $workdir/sound.wav";
  if ( !runcmd($f) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
  $f = "ffmpeg -i $workdir/sound.wav -ac 2 -acodec copy  -i $dvfile -vcodec copy  -map 1:0 -map 0.0 -f dv -y $new_dvfile";
  if ( !runcmd($f) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
  return $new_dvfile;
}


sub glue_dv {
  my $outfile = shift;
  my $infile = shift;
  my $ffmpeg = "ffmpeg -i $infile  -aspect 16:9 -acodec pcm_s16le -vcodec dvvideo -y ".$outfile.' -f avi'  ;
  if ( !runcmd($ffmpeg) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
# my $cmd = 'cat '.join(' ',@infiles).' |  dvgrab -size 0 -stdin -f dv2 -opendml '.$outfile  ;
#savetemp();
 if ( -d $workdir ) {
   `rm -rf $workdir`;
 }
}


sub savetemp {
  my $outfile_base = $opts{'o'};
  $outfile_base =~ s/.+\.avi$//;
  print $outfile_base;
  my $f = "mv \"$workdir/startposter.dv\" \"$outfile_base-starposter.dv\"";
  if ( !runcmd($f) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
  $f = "mv \"$workdir/endposter.dv\" \"$outfile_base-endposter.dv\"";
  if ( !runcmd($f) ) { die "Failed to execute system command in" . (caller(0))[3] ."\n"; }
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
