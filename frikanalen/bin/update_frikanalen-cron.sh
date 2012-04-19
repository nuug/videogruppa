#!/bin/sh

bindir="/data/video/frikanalen/bin"
htmldir="/data/video/frikanalen"

echo "###### `date` #####"

echo "Updating meta.xml" 
> $htmldir/meta.xml

#c=0
# c=$(expr $c + 1 )
# echo "Take $c"
 $bindir/update_meta_xml.pl $htmldir/meta_new.xml
 if [ !  -f $htmldir/meta_new.xml ]
 then 
  echo "Failed to download new metadata file. "
  exit 1
 fi

 # Verify a successfull download
 if [ "$(wc -l $htmldir/meta_new.xml|awk '{print $1}')" -lt 50 ]; then
  sleep 30
 else
  mv $htmldir/meta_new.xml $htmldir/meta.xml
  $bindir/update_video_diff.pl
 fi
