#!/bin/bash
# test
# ikke i svn

FILENAME=`./csv $2 $1 filename`
LOGO=`./csv $2 $1 logo`
NAME=`./csv $2 $1 name`
TITLE=`./csv $2 $1 title`
WHAT=`./csv $2 $1 what`
DATE=`./csv $2 $1 date`
LOCATION=`./csv $2 $1 location`
LICENSE=`./csv $2 $1 license`
TAKK=`./csv $2 $1 takk`
URL=`./csv $2 $1 url`

if [ -z "$1" ]; then
	echo "Usage: $0 <video-file> [<csv-file>]"
	exit 1
fi

# filename er problemet
echo "Filename: $FILENAME"
echo "Logo: $LOGO"
echo "Name: $NAME"
echo "Title: $TITLE"
echo "What: $WHAT"
echo "Date: $DATE"
echo "Location: $LOCATION"
echo "License: $LICENSE"
echo "Takk: $TAKK"
echo "URL: $URL"
