#!/bin/bash

declare -r latest_url="http://www.mcs.anl.gov/research/projects/waggle/downloads/waggle_images/base/latest.txt"
declare -r branch=$(git branch)
declare -A dates
dates=([develop]=20170307 [v2.5.1]=20170307)
date=${dates[$branch]}
if [ "x$date" == "x" ]; then
  curl ${latest_url} 2>&1 | sed -n 's/..*\([0-9]\{8\}\).img.xz/\1/p'
else
  echo $date
fi
