#!/usr/bin/perl -w

# Author: Jarle Bjørgeengen
# Date: 2009-03-01
# License: GNU General Public license

# Inngansportal til Frikanalen sine videoer i theora format
#
# http://wiki.nuug.no/grupper/video/pubfrikanalen

use strict;
use warnings;

use XML::Simple;
use CGI qw/:standard/;
# SOAP:Lite må modifiseres til å gjøre ting på MS måten :-/
use SOAP::Lite  on_action => sub {sprintf '%s/%s', @_}, ;
use Data::Dumper;
use Date::Parse;
use POSIX qw(strftime);
use Encode;
use URI::Escape;

my $query = new CGI;
my $nuug_frikanalen_url = 'http://www.nuug.no/pub/video/frikanalen/';
my $scripturl = url();
my $category = $query->param("category");
my $cat = $category ? "category=$category" : "";
my $organization = $query->param("organization");
my $org_escaped = uri_escape($organization);
my $org = $organization ? "organization=$org_escaped" : "";
my $editor = $query->param("editor");
my $ed_escaped = uri_escape($editor);
my $ed = $editor ? "editor=$ed_escaped" : "";
my $sort = $query->param("sort");
my $sor = $sort ? "sort=$sort" : "";
my $searchtype = $sort ? "$sort" : "MostRecent";
my $page = $query->param("page") ;
if ( ! $page ) { $page = 0; } 
my $video_count = 0;
my $videos_per_page = 20;
my $offset = $page ? $page * $videos_per_page : 0;
my $rss = $query->param("rss");
my $metainfo = "/home/ftp/pub/video/frikanalen/meta.xml";
my $ref = XMLin($metainfo);
my $videodir = '/data/video/frikanalen';

binmode STDOUT, ":utf8";

if (defined $rss) {
   generate_rss();
   exit 0;
} else {
   &printheader;
   &printbody;
   &printfooter;
   exit 0;
}
###########################################

sub get_categories {
 # Returnerer referanse med "array of hashrefs". Hver hashref inneholder variablene 'Name' og 'Id'.
 # Kun 'Name' er brukt.
 my $soap = new SOAP::Lite
 -> uri('http://localhost/CommunitySiteService')
 -> proxy('http://communitysite1.frikanalen.tv/CommunitySiteFacade/CommunitySiteService.asmx');
 my $res;
 my $obj = $soap->SearchCategories(SOAP::Data->name('searcher' => {
     }
   )
 );
 unless ($obj->fault) {
   my @categories;
   $res = $obj->result;
   #print Dumper($res);
   #foreach my $category (@{$res->{'Data'}->{'Category'}}) {
   #  print "$category->{Name} $category->{Id}\n";
   #}
   return $res->{'Data'}->{'Category'};
 } else {
   print join ', ',
   $res->faultcode,
   $res->faultstring;
 }

}

sub get_organizations {
 my $soap = new SOAP::Lite
 -> uri('http://localhost/CommunitySiteService')
 -> proxy('http://communitysite1.frikanalen.tv/CommunitySiteFacade/CommunitySiteService.asmx');
 my $res;
 my $soap_response = $soap->GetOrganizations;
 unless ($soap_response->fault) {
   my $res = $soap_response->result;
   return $res->{'Data'}->{'string'};
 } else {
   print join ', ',
   $soap_response->faultcode,
   $soap_response->faultstring;
 }
}

sub get_editors {
 my $soap = new SOAP::Lite
 -> uri('http://localhost/CommunitySiteService')
 -> proxy('http://communitysite1.frikanalen.tv/CommunitySiteFacade/CommunitySiteService.asmx');
 my $res;
 my $soap_response = $soap->GetEditors;
 unless ($soap_response->fault) {
   my $res = $soap_response->result;
   return $res->{'Data'}->{'string'};
 } else {
   print join ', ',
   $soap_response->faultcode,
   $soap_response->faultstring;
 }
}

sub searchvids {
 # Returnerer referanse med "array of hashrefs". Hashref inneholder metadata og urler
 # til videoer. Bruk Dumper til å titte på.
 my $returndata ;
 my $res;
 my $obj;
 my $soap = new SOAP::Lite
 -> uri('http://localhost/CommunitySiteService')
 -> proxy('http://communitysite1.frikanalen.tv/CommunitySiteFacade/CommunitySiteService.asmx');
 if ($category) {
   $obj = $soap->SearchVideos(
     SOAP::Data->name('searcher' => {
          'PredefinedSearchType' => $searchtype,
          'CategoryName' => $category,
          'Take' => 10000,
        }
     )
   );

 } elsif ($organization) {
   $organization = SOAP::Data->type(string => encode("utf8",$organization));
   $obj = $soap->SearchVideos(
     SOAP::Data->name('searcher' => {
          'PredefinedSearchType' => $searchtype,
          'Organization' => $organization,
          'Take' => 10000,
        }
     )
   );
  } elsif ($editor) {
   $editor = SOAP::Data->type(string => encode("utf8",$editor));
   $obj = $soap->SearchVideos(
     SOAP::Data->name('searcher' => {
          'PredefinedSearchType' => $searchtype,
          'Editor' => $editor,
          'Take' => 10000,
        }
     )
   );
 } else {
   $obj = $soap->SearchVideos(
     SOAP::Data->name('searcher' => {
          'PredefinedSearchType' => $searchtype,
          'Take' => 10000,
        }
     )
   );
 }


 unless ($obj->fault) {
   $res = $obj->result;
      if ( ref($res->{'Data'}->{'Video'}) eq 'HASH') {
       return [ $res->{'Data'}->{'Video'} ];
      }
   return $res->{'Data'}->{'Video'};
 } else {
   print join ', ',
   $res->faultcode,
   $res->faultstring;
 }

}

sub printheader {
 # Skriver ut toppen av forsiden + høyremeny med kategorier,
 # sorteringstyper og link til rss tilbake til
 # megselv?category=$category;sort=¤sort
 my $menu;
 if ($organization) {
    $menu = "org";
 } elsif ($editor) {
    $menu = "ed";
 } else {
    $menu = "cat";
 }
 my $arg = join(";", $sor,$cat,$org,$ed);
 my $categories = &get_categories;
 my $organizations = &get_organizations;
 my $editors = &get_editors;
 my %searchtypes = ("Nyeste", "MostRecent", "Tittel", "OrderByTitle", "Topp vurderte", "TopRated", "Mest sett", "MostViewed", "Mest diskutert", "MostDiscussed");
 my $search;
 print "Content-type: text/html; charset=UTF-8\n\n";
 # Page header
 print <<EOF;
 <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
 <html>
 <head>
 <meta http-equiv="content-type" content="text/html; charset=UTF-8">
 <title>Frikanalen - med &aring;pne standarder</title>
 <link href="style1.css" rel="stylesheet" type="text/css">
 <script type="text/javascript" src="hide.js"></script>
 </head>
EOF
 print "<body onload=\"show_" . $menu . "();\">";
 print <<EOF;
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
 <div id="content">
EOF
 # Kategorier
 print "<div id=\"kategorier\"><div class=\"list\"><h2>&nbsp;Kategorier</h2>";
 print "<div id=\"choose_cat\"><ul><li><a href=\"#\" onclick=\"show_cat();\">[ velg ]</a></li></ul></div>";
 my $all_cat = $category ? "<div id=\"list_cat\"><ul><li><a href=\"$scripturl?$sor\">Alle</a></li>" : "<div id=\"list_cat\"><ul><li class=\"active\"><img src=\"bullet.png\" alt=\"&gt;\"> Alle</li>";
 print "$all_cat";
 foreach my $cat (@{$categories}) {
   if (defined $category && $cat->{'Name'} eq $category) {
     print "<li class=\"active\"><img src=\"bullet.png\" alt=\"&gt;\"> $cat->{'Name'}</li>";
   } else {
     print "<li><a href=\"$scripturl\?category=$cat->{'Name'};$sor\" >$cat->{'Name'}</a></li>";
   }
 }
 print "</ul></div></div>";
 # Organisasjoner
 print "<div class=\"list\"><h2>&nbsp;Organisasjoner</h2>";
 print "<div id=\"choose_org\"><ul><li><a href=\"#\" onclick=\"show_org();\">[ velg ]</a></li></ul></div>";
 my $all_org = $organization ? "<div id=\"list_org\"><ul><li><a href=\"$scripturl?$sor\">Alle</a></li>" : "<div id=\"list_org\"><ul><li class=\"active\"><img src=\"bullet.png\" alt=\"&gt;\"> Alle</li>";
 print "$all_org";
 foreach (@{$organizations}) {
    $org_escaped = uri_escape($_);
    if (defined $organization && $_ eq $organization){
      print "<li class=\"active\"><img src=\"bullet.png\" alt=\"&gt;\"> $_</li>";
    } else {
      print "<li><a href=\"$scripturl\?organization=$org_escaped;$sor\" >$_</a></li>";
    }
}
 print "</ul></div></div>";
 # Redaktører
 print "<div class=\"list\"><h2>&nbsp;Redakt&oslash;rer</h2>";
 print "<div id=\"choose_ed\"><ul><li><a href=\"#\" onclick=\"show_ed();\">[ velg ]</a></li></ul></div>";
 my $all_ed = $editor ? "<div id=\"list_ed\"><ul><li><a href=\"$scripturl?$sor\">Alle</a></li>" : "<div id=\"list_ed\"><ul><li class=\"active\"><img src=\"bullet.png\" alt=\"&gt;\"> Alle</li>";
 print "$all_ed";
 foreach (@{$editors}) {
    $ed_escaped = uri_escape($_);
    if (defined $editor && $_ eq $editor) {
      print "<li class=\"active\"><img src=\"bullet.png\" alt=\"&gt;\"> $_</li>";
    } else {
      print "<li><a href=\"$scripturl\?editor=$ed_escaped;$sor\" >$_</a></li>";
    }
}
 print "</ul></div></div>";
 # Sorteringer
 print "&nbsp;<h2>SORTER</h2>";
 print "<ul>";
  foreach $search (sort keys %searchtypes) {
    if ($searchtypes{$search} eq $searchtype) {
      print "<li class=\"active\"><img src=\"bullet.png\" alt=\"&gt;\"> $search</li>";
    } else {
      print "<li><a href=\"$scripturl\?sort=$searchtypes{$search};$org\">$search</a></li>";
    }
 }
 # Link til rss
 print <<EOF;
  </ul>
 <div id="rss">
 <p><a href="$scripturl\?rss=1;$cat">RSS</a> for
   <a href="http://subscribe.getmiro.com/?url1=$scripturl\?rss=1;$arg">Miro</a></p>
 </div>
 </div>
EOF
}

sub printbody {
 # Returnerer kroppen til htmltabellen. Innholdet er avhengig av $category
 my $videos = &searchvids($category,$organization,$editor);
 $video_count = (@{$videos});
 # print Dumper($videos);
 print "<div id=\"videos\">\n";
 print "<ul>\n";
 # Bruk paging. GM. 01.06.09
 # foreach my $video (@{$videos}) {
 for (my $x = 0; $x < $videos_per_page; $x++) {
   my $video = (@{$videos}[$x+$offset]);
   my $title = $video->{'Title'};
   my $id = $video->{'MetaDataVideoId'};
   # Use local thumb JB. 10.03.09
   my $imageuri = './thumbs/'.$id.'.jpg';
   # ...hvis lokal thumb finnes. GM. 08.06.09
   unless (-e $imageuri) {
     $imageuri = $video->{'ImageUri'};
   }
   my $ogvurl = "$nuug_frikanalen_url$id.ogv";
   my $description = $video->{'Description'};
   my $length = $video->{'MetaData'}->{'Length'};
   my $seconds = ($length%60);
   my $minutes = int(($length%3600)/60);
   my $hours = int($length/3600);
   my $videouri = "${nuug_frikanalen_url}fetchvideo.cgi\?videoId=$id";
   my $ogvfile = "$id.ogv";
   my $num = $id; $num =~ s/^id_//;
   my $uploaddate = $video->{'Details'}->{'UploadDate'};

   if (-e "$videodir/$ogvfile") {
     print "<li><div class=\"container\"><div class=\"description\"><a href=\"$videouri\">";
     print "<img src=\"$imageuri\" align=\"left\" border=\"0\" width=\"64\" alt=\"thumbnail\"><strong>$title</strong>\n";
     if ($hours) {
          print "\ (Lengde: ".(sprintf('%2dt %2dm',$hours,$minutes)).') </a><br>';
     } else {
          print "\ (Lengde: ".(sprintf('%2dm %2ds', $minutes, $seconds)).') </a><br>';
     }
     print "Publisert: $uploaddate<br>\n" if $uploaddate;
     print "$description\n" if $description;
     print "</div><div class=\"spacer\"></div></div></li>\n";
   }
 }
 print "</ul>\n";
 print "</div>\n";
}

sub printfooter {
 # List argumenter for sortering, kategorier, organisasjon og redaktør
 my $arg = join(";", $sor,$cat,$org,$ed);
 # Hvis mer enn en side med videoer, skriv ut pager-links
 if ($video_count > $videos_per_page) {
  my $pagenum = (int(($video_count-1) / $videos_per_page)+1);
  my $previous = $page - 1;
  my $current = $page;
  my $next = $page + 1;
  print "<div id=\"pager\">\n";
  print "<p>&nbsp;</p>\n";
  if ($current > 0) {
    print "<a href=\"$scripturl\?page=$previous;$arg\">Forrige</a> ";
  }
  if ($current == 0) {
    print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 1 ";
  } else {
        print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href=\"$scripturl\?page=0;$arg\">1</a> ";
  }
  for (my $x = 1; $x < $pagenum; $x++) {
    my $p = $x + 1;
    if ($x == $current) {
     print "$p ";
    } else {
         print "<a href=\"$scripturl\?page=$x;$arg\">$p</a> ";
    }
  }
  print "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
  unless ($next == $pagenum) {
    print " <a href=\"$scripturl\?page=$next;$arg\">Neste</a>\n";
  }
  print "</div>\n";
 }
 # Skriv ut footer
 print <<EOF;
  <div id=\"footer\">
  &nbsp;<br>
  &copy; 2009 Foreningen Frikanalen, design
 <a href="http://www.wildweb.no" target="_blank">Wild Web</a>
 </div>
 </div>
 </div>
 </html>
EOF
}

sub videosort {
   my $res = $b->{'Details'}->{'UploadDate'} cmp $a->{'Details'}->{'UploadDate'};
   $res = $b->{'MetaDataVideoId'} <=> $a->{'MetaDataVideoId'} if 0 == $res;
   return $res;
}
sub generate_rss {
   print_rss_header();

   my $videos = &searchvids($category,$organization,$editor);

   foreach my $video ( sort videosort @{$videos} ) {
        my $id = $video->{'MetaDataVideoId'};
        my $videouri = "${nuug_frikanalen_url}fetchvideo.cgi\?videoId=$id";
        my $ogvfile = "$id.ogv";
        my $num = $id; $num =~ s/^id_//;

# print STDERR Dumper($video);

       my $oggfilepath = "$videodir/$ogvfile";
       my $date = format_rss_date($video->{'Details'}->{'UploadDate'});

        if ( -e $oggfilepath ) {
            my $size = (stat($oggfilepath))[7];
            item($video->{'Title'}, $date, $videouri, $video->{'Description'},
                 "$nuug_frikanalen_url$id.ogv", "application/ogg", $size,
                 $video->{'ImageUri'}, int($video->{'MetaData'}->{'Length'}));
        }
   }
   print_rss_footer();
}

sub format_rss_date {
   my ($isodate) = @_;
   $isodate =~ s/^(\d{4})(\d{2})(\d{2})/$1-$2-$3/;
   my $time = str2time($isodate);

   return strftime("%a, %d %b %Y %H:%M:%S %z", gmtime($time));
}

sub item {
   my ($title, $date, $link, $desc,
       $enclurl, $encltype, $enclsize, $thumb, $duration) = @_;
   $enclurl = $link unless defined $enclurl;
   $title = escapeHTML($title);
   $desc = escapeHTML($desc);
   print <<EOF;
   <item>
     <title>$title</title>
EOF
   print "      <link>$link</link>\n" if $link;
   print "      <guid>$link</guid>\n" if $link;
   print "      <description>$desc</description>\n" if $desc;
   print "       <pubDate>$date</pubDate>\n" if $date;
   print <<EOF if $thumb;
     <itunes:image href="$thumb"/>
EOF
   print "      <itunes:duration>$duration</itunes:duration>\n" if ($duration);
   print <<EOF
     <enclosure url="$enclurl" type="$encltype" length="$enclsize" />
   </item>

EOF
}

sub print_rss_header {
   my $selfurl = self_url();
   my $cat = defined $category ? $category : "";
 print <<EOF;
Content-type: text/xml

<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
 xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
 xmlns:atom="http://www.w3.org/2005/Atom"
 xml:lang='nb-NO'>


 <channel>
   <title>Frikanalen $cat</title>
   <link>http://www.frikanalen.no/</link>
   <atom:link href="$selfurl" rel="self" type="text/xml" />
   <description>Frikanalen recordings.</description>

   <copyright>(c)</copyright>
   <language>nb</language>
   <itunes:author>Frikanalen</itunes:author>
   <itunes:subtitle>Collected recordings</itunes:subtitle>
   <itunes:summary>Broadcasted on the public TV channel.</itunes:summary>
   <itunes:owner>
       <itunes:name>Frikanalen</itunes:name>
       <itunes:email>post\@frikanalen.no</itunes:email>
   </itunes:owner>
   <itunes:keywords>Frikanalen, $cat</itunes:keywords>
   <image>
       <title>Frikanalen $cat</title>
       <url>http://www.frikanalen.no/images/frikanal_logo_sv_bakgrunn_f.gif</url>
       <link>http://www.frikanalen.no/</link>
   </image>
   <itunes:image href="http://www.frikanalen.no/images/frikanal_logo_sv_bakgrunn_f.gif"/>
   <itunes:explicit>no</itunes:explicit>
   <itunes:category text="TV &amp; Film" />

EOF
}

sub print_rss_footer {
   print <<EOF;
 </channel>
</rss>
EOF
}

