#!/usr/bin/perl -w

# Author: Jarle Bjørgeengen
# Date: 2009-03-01
# License: GNU General Public license

# Script for å levere inkeltvideoer basert på $Id
#
# http://wiki.nuug.no/grupper/video/pubfrikanalen

use strict;
use warnings;

use XML::Simple;
use CGI qw/:standard/;
use URI::Escape;

binmode STDOUT, ":utf8";

my $query = new CGI;
my $nuug_frikanalen_url = 'http://www.nuug.no/pub/video/frikanalen/';
my $videoid = $query->param("videoId");
my $playlist = $query->param("playlist");
my $lengde;

my $metainfo = "/home/ftp/pub/video/frikanalen/meta.xml";
my $ref = XMLin($metainfo);

my $id = "id_$videoid";
my $duration = $ref->{$id}->{'Length'};
if (! exists  $ref->{$id} ) {
   print STDERR "Unable to look up $id\n";
}
my $title = $ref->{$id}->{Title};
my $description = $ref->{$id}->{Description};
my $organization = $ref->{$id}->{Organization};
my $org_escaped = uri_escape($organization);
my $length = int($ref->{$id}->{Length});
my $seconds = ($length%60);
my $minutes = int(($length%3600)/60);
my $hours = int($length/3600);
my $date = $ref->{$id}->{UploadDate};
$date =~ s/T.+$//;
my $ogvurl = $ref->{$id}->{ogvUri};
my $wmvurl = $ref->{$id}->{VideoUri};
my $playlisturl = $nuug_frikanalen_url . url(-relative=>1) . "?playlist=$videoid.m3u" ;
my $imageuri = $ref->{$id}->{'ImageUri'};

if ($hours) {
   $lengde = (sprintf('%2dt %2dm',$hours,$minutes));
} else {
   $lengde = (sprintf('%2dm %2ds', $minutes, $seconds));
}

if ($playlist) {
   $playlist =~ /(^.+)\.m3u/;
   my $id = "id_$1";
   my $ogvurl = $ref->{$id}->{ogvUri};
   print "Content-type: audio/x-mpegurl\n\n";
   print "$ogvurl";
   exit 0;
} else {

   print "Content-type: text/html; charset=UTF-8\n\n";

   print <<"EOF";
   <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
   <html>
   <head>
   <meta http-equiv="content-type" content="text/html; charset=UTF-8">
   <title>Frikanalen - med &aring;pne standarder</title>
   <link href="style1.css" rel="stylesheet" type="text/css">
   </head>
   <body>
   <div id="page">
   <div id="top"><img src="logo.png" alt="Frikanalen">
   <p id="av"><span class="overskrift">TV FOR ALLE</span><br>
   Dette er en alternativ presentasjon av filmene som sendes p&aring;
   <a href="http://www.frikanalen.no/">Frikanalen</a> i Norge.
   Denne alternative presentasjonen benytter &aring;pne standarder og er laget av
   <a href="http://www.nuug.no/">NUUG</a>s videogruppe.</p>
   <table border="0" cellpadding="0" cellspacing="0" id="custom-menu">
     <tbody>
       <tr>
         <td><a href="http://www.frikanalen.no/om"><img alt="OM FRIKANALEN" src="om.png"></a></td>
         <td><a href="http://www.frikanalen.no/lage-tv"><img alt="LAGE TV P&Aring; FRIKANALEN" src="lage-tv.png"></a></td>
         <td><a href="http://www.frikanalen.no/se"><img alt="SE P&Aring; FRIKANALEN" src="se.png"></a></td>
       </tr>
     </tbody>
   </table>
   </div>
   <div id="content_video">
        <h1>$title</h1>
        <p>$description</p>
        <p><b>Organisasjon:</b> <a href="frontpage.cgi?org=$org_escaped">$organization</a></p>
        <applet code="com.fluendo.player.Cortado.class"
        archive="http://www.nuug.no/tools/cortado-unsigned.jar"
        width="640" height="320">
        <param name="url" value="$ogvurl"/>
        <param name="local" value="false"/>
        <param name="showStatus" value="show"/>
        <param name="bufferSize" value="500"/>
        <param name="duration" value="$duration"/>
        <param name="keepaspect" value="true"/>
       <img src="$imageuri" width="640" height="320" border="0" alt="preview">
        </applet>
        <p><table cellpadding=5>
        <tr><td>Lengde:</td><td> $lengde </td></tr>
        <tr><td>Dato:</td><td> $date </td></tr>
        </table>
        <p>Dersom du ikke ser noe video p&aring; denne siden, har du en nettleser uten fungerende java-st&oslash;tte. F&oslash;lgende lenker kan benyttes dersom dette er tilfelle, eller du &oslash;nsker mere kontroll p&aring; s&oslash;king (playlist url) eller laste ned hele filen (Ogg Theora) . Vi har ogs&aring;  lagt inn direktelink til Windows Media url p&aring; frikanalen sin side.
        <p>Video URLs:
        <br><a href="$playlisturl">Playlist url (m3u) </a>for ekstern avspiller. <a href="http://www.videolan.org">(VLC fungerer  godt p&aring; alle platformer .)</a>
        <br><a href="$ogvurl">Ogg Theora</a>
        <br><a href="$wmvurl">Windows Media</a>
        <br><a href="frontpage.cgi">Tilbake</a></p>
        </div>
        <div id="footer">
        &copy; 2009 Foreningen Frikanalen, design
    <a href="http://www.wildweb.no" target="_blank">Wild Web</a>
        </div>
        </div>
        </body>
        </html>
EOF
}

