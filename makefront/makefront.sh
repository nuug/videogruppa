#!/bin/bash

set -e

LANG=nb_NO
export LANG

# Makefront av Hans-Petter "Atluxity" Fjeld <atluxity@gmail.com>
# CC-BY-SA 3.0
echo "Startet Makefront, laget for NUUG 2009."

#Lag et unikt filnavn å spytte ut
count=0
while [ -e NUUG-vid_front${count}.png ]; do
   count=`expr ${count} + 1`
done
echo "Output til filen NUUG-vid_front${count}.png..."

#Starte med å putte NUUG-logoen på video-bakgrunnen.
composite -geometry +52+167 NUUG-logo-2-150.png NUUG-vid_bg.png NUUG-vid_front${count}.png
echo "Laget trinn 1 av 3..."

#Putte CC-BY-SA-logoen på der igjen
composite -geometry +632+770 cc-by-sa.png NUUG-vid_front${count}.png NUUG-vid_front${count}.png
echo "Laget trinn 2 av 3..."

#Sette opp standard innhold i variabler for debugging
#presenter="Foredragsholder"
#title="Tittel"
#timeplace="Tid og sted"

#Spør om input til variabler
echo "Skriv inn navnet på foredragsholder (maks 25 tegn): "
read presenter

echo "Skriv inn tittelen til foredraget (maks 25 tegn): "
read title

echo "Skriv inn tid for foredraget: (`date +%d.\ %B\ %Y`)"
read time
if [ -z "${time}" ] ; then
   time=`date +%d.\ %B\ %Y`
fi

echo "Skriv inn sted for foredraget: "
read place
if [ -z "${place}" ] ; then
   timeplace="${time}"
else
   timeplace="${time} - ${place}"
fi

#Sette tekst på bildet
echo "Setter teksten på bildet..."
convert NUUG-vid_front${count}.png -pointsize 72 -fill white \
  -draw "text 400,167 '${presenter}'" -draw "text 400,267 '${title}'" \
  -pointsize 40 -draw "text 400,567 '${timeplace}'" NUUG-vid_front${count}.png
echo "Laget trinn 3 av 3 (NUUG-vid_front${count}.png opprettet)."

# Convert to PAL size
#convert -size 720x576 \
#  NUUG-vid_front${count}.png NUUG-vid_front${count}-pal.png

echo "Makefront avslutter"

exit 0
