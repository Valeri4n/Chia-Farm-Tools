#!/bin/sudo bash
# Written by Valerian - Copyright 2022
# This script looks at drive temperatures for all drive names entered after calling the script
# ./drive_temp_check.sh sda sdrw sddt    , etc.

if [ ! "`whoami`" = "root" ]; then
    printf "\nPlease run script as root. Exiting\n\n"
    exit 1
fi

if [ $# -eq 0 ]; then echo "$0: Missing arguments"; exit 1; fi
drive=( "$@" )
cnt=10
arr_len=${#drive[@]}
imax=$(($arr_len - 1))

for (( i=0; i<=$imax; i++ )); do
  header="$header ${drive[$i]}"
done
echo
while true; do
  temps=""
  if [ $((cnt)) -eq 10 ]; then
    cnt=0
    echo "                                  $header"
  fi
  for (( i=0; i<=$imax; i++ )); do
    temp=`smartctl -a /dev/"${drive[$i]}" 2>/dev/null | grep 'Current Drive Temperature:' | awk '{print $4}'`
    temps="$temps   $temp"
  done
  today=`date`
  cnt=$(($cnt + 1))
  echo " $today $temps"
  sleep 60
done
