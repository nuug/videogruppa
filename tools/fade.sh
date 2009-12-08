#!/bin/bash
count=0
file="NUUG-logo-2-150-2.png"

echo "Generating intro frame images"

# Generate 50 fade-in frames 
for i in {1..50}; do
  count=`expr $count + 1`
  echo "Generating intro frame image $file ($count)"
#  convert -fill black -colorize $i% NUUG-logo-2-150-2.png test-$i.png
done

for i in {1..50}; do
  count=`expr $count + 1`
  echo "Generating intro frame image $file ($count)"
  #cp 51 $count
done

for i in {1..50}; do
count=`expr $count + 1`
echo "Generating intro frame image $file ($count)"
#cp 51 $count
done

