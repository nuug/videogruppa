#!/usr/bin/bash

workdir="/stream/frikanalen-bin"

cd ${workdir}

if  [[ `pwd` == ${workdir} ]]
then
./scheduler -s http://voip.nuug.no:8000/frikanalen.ogv > fk.log 2>&1
fi
