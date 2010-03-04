#!/bin/bash

workdir="/home/jarle/svn/frikanalen-bin/"

cd ${workdir}

./scheduler -s http://voip.nuug.no:8000/frikanalen.ogv > fk.log 2>&1
