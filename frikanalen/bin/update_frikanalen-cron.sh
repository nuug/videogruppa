#!/bin/sh

bindir="/data/video/frikanalen/bin"
htmldir="/data/video/frikanalen"

echo "###### `date` #####"

echo "Updating meta.xml" 
> $htmldir/meta.xml

c=0
while true ; do 
 c=$(expr $c + 1 )
 echo "Take $c"
 $bindir/update_meta_xml.pl $htmldir/meta.xml

 # Verify a successfull download
 if [ "$(wc -l < $htmldir/meta.xml)" -lt 50 ]; then
  sleep 30
 else
  break
 fi
done

$bindir/update_video_diff.pl
