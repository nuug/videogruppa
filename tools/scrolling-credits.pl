#!/usr/bin/perl

use GD; 
use GD::Text;
use strict;
use warnings;

#my $ref = new GD::Image(100,100);
#my $white = $ref->colorAllocate(255,255,255);
#my $black = $ref->colorAllocate(0,0,0);
my $blankMap = new GD::Image(720,540);
my $white = $blankMap->colorAllocate(255,255,255);
my $black = $blankMap->colorAllocate(0,0,0);

my @positions = (); 
my @elements = ();
my $gdfont = "/usr/share/fonts/truetype/ttf-liberation/LiberationSans-Regular.ttf";
my $fontsize = 20;
my $linespace = 1.3;
my $left = 0;
my @bounds;
$bounds[1] = 150;


my $bgfile = "/home/jarle/svn/nuug-video/tools/lib/graphic/tv-bg-pal-size.png";

my $im = newFromPng GD::Image($bgfile);

#my $white = $im->colorAllocate(255,255,255);
#my $black = $im->colorAllocate(  0,  0,  0);
$im->interlaced(undef);
$im->transparent(-1);
#$im->colorDeallocate($white);
#$white = $im->colorAllocate(255,255,255);
#$im->rectangle(0,0,99,99,$black);
#$im->rectangle(0,0,59,99,$black);

my $line = "Dette er en test på øæåØÆÅ";
@bounds = $im->stringFT($black,$gdfont,$fontsize,0,220,130,$line);

#$im->string(gdMediumBoldFont,200,300,$line,$white);

writefile('foo.png');
#read_elements("elements.txt");

print join("-",@elements)."\n";
print join("-",@positions)."\n";

sub read_elements {
 my $file = shift ;
 my $position = 100;
 my $line_distance = 30;

 open F, "$file" or die "Cannot open $file for read :$!";
 while (<F>) {
  chomp;
  push(@elements,$_);
  push(@positions,$position);
  $position += $line_distance;
 }
close F;
}

sub writefile {
 my $f = shift;
 open(F,">",$f);
 binmode F; 
 print F $im->png;
 close F;
}

