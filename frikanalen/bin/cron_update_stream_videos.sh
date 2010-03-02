#!/bin/bash

workdir="/stream/frikanalen-bin"

cd ${workdir}
if  [[ `pwd` == ${workdir} ]]
then
find . -name 'broadcast*.ogv' -mtime +1 -exec rm {} \;
./scheduler -g -o  > download.log 2>&1 & 
fi
