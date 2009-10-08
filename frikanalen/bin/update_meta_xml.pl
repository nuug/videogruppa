#!/usr/bin/perl

# Author: Jarle Bjørgeengen
# Date: 2009-03-01
# License: GNU General Public license

# Oppdaterer lokalt cachet metadata fra frikanalen i meta.xml
# Nøkkel er $Id for lett oppslag i metadata basert på $Id.
# 
# http://wiki.nuug.no/grupper/video/pubfrikanalen


use SOAP::Lite  on_action => sub {sprintf '%s/%s', @_}, ;

use Encode ;
use Data::Dumper;
use XML::Simple;
my $localvideo_dir = '/data/video/frikanalen';
my $meta_subset = &get_frikanalen_meta_subset('MetaDataVideoId'); # Use 'Id' or 'MetaDataVideoId' as key
#print Dumper($meta_subset);
my $xml = XMLout($meta_subset);

open METAFILE, "> $localvideo_dir/meta.xml" or die "Cannot open $localvideo_dir/meta.xml for write :$!";
print METAFILE "$xml\n";
close METAFILE;


###### Functions ##############

sub get_frikanalen_meta_subset {
# Build metadata structure with id as key
    my $returndata;
    $soap = new SOAP::Lite
	-> uri('http://localhost/CommunitySiteService')
	-> proxy('http://communitysite1.frikanalen.tv/CommunitySiteFacade/CommunitySiteService.asmx');

# Request list of all available videos with all avalable metadata for each video
# constructing the expected xml code for 
# http://communitysite1.frikanalen.tv/CommunitySiteFacade/CommunitySiteService.asmx?op=SearchVideos
# 'Take' is how many records to grab. Just crank it higher than the number of available records,
# and it will return all. 

    my $obj = $soap->SearchVideos(
	    SOAP::Data->name('searcher' => {
		'PredefinedSearchType' => 'Default',
		'Take' => 10000,
		}
		)
	    );
    unless ($obj->fault) {
	my $res = $obj->result;
	my $key = $_[0];
	my $nuug_video_prefix = 'http://www.nuug.no/pub/video/frikanalen/';
#	print Dumper($res);
	foreach my $video (@{$res->{'Data'}->{'Video'}}) {
	    $utf8_id = encode("utf8",'id_'.$video->{$key});
	    $returndata->{$utf8_id}->{'VideoUri'} = encode("utf8",$video->{'VideoUri'});
	    $returndata->{$utf8_id}->{'VideoOgvUri'} = encode("utf8",$video->{'VideoOgvUri'});
	    $returndata->{$utf8_id}->{'ImageUri'} = encode("utf8",$video->{'ImageUri'});
	    $returndata->{$utf8_id}->{'IsActive'} = encode("utf8",$video->{'IsActive'});
	    $returndata->{$utf8_id}->{'UploadDate'} = encode("utf8",$video->{'Details'}->{'UploadDate'});
	    $returndata->{$utf8_id}->{'ogvUri'} = encode("utf8",$nuug_video_prefix.$video->{$key}.'.ogv');
	    $returndata->{$utf8_id}->{'Title'} = encode("utf8",$video->{'Title'});
	    $returndata->{$utf8_id}->{'Length'} = encode("utf8",$video->{'MetaData'}->{'Length'});
	    $returndata->{$utf8_id}->{'Description'} = encode("utf8",$video->{'Description'});
	}
	return $returndata;
    } else {
	print join ', ',
	      $result->faultcode,
	      $result->faultstring;
    }
}
