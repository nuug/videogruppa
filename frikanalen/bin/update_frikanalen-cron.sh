#!/usr/local/bin/bash

typeset -i c=0
bindir="/data/video/frikanalen/bin/"
htmldir="/data/video/frikanalen/"

echo "###### `date` #####"

echo "Updating meta.xml" 
> ${htmldir}meta.xml

while  [[ true ]]; do 
 c=$c+1
 echo "Take $c"
 ${bindir}update_meta_xml.pl
 if [[ $(wc -l ${htmldir}meta.xml|awk '{print $1}') -lt 50 ]]
 then
  sleep 30
 else
  break
 fi
done

${bindir}/update_video_diff.pl



