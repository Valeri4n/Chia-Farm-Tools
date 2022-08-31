#!/bin/sudo bash
# Written by Valerian - Copyright 2022
# This script retrieves drive serial numbers with labels
# and current name with output to file

if [ ! "`whoami`" = "root" ]; then
    printf "\nPlease run script as root. Exiting\n\n"
    exit 1
fi

path="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
hostnm=`hostname`
DT=`date +"%y%m%d-%I%M"`
filename="$path/$DT-$TM$hostnm-drivelist.txt"
echo "Creating file $filename"
while read -r line; do
  if [[ $line == 'r'*'s'*'d'* ]]; then
    one=`echo "$line" | awk '{print $1}'`
    two=`echo "$line" | awk '{print $2}'`
    thr=`echo "$line" | awk '{print $3}'`
    fou=`echo "$line" | awk '{print $4}'`
    if [ $((onelen)) -lt ${#one} ] || [ -z $onelen ]; then onelen=${#one}; fi
    if [ $((twolen)) -lt ${#two} ] || [ -z $twolen ]; then twolen=${#two}; fi
    if [ $((thrlen)) -lt ${#thr} ] || [ -z $thrlen ]; then thrlen=${#thr}; fi
    if [ $((foulen)) -lt ${#fou} ] || [ -z $foulen ]; then foulen=${#fou}; fi
  fi
done < <(lsblk -o label,size,name,mountpoint | sort)
onelen=-$(($onelen + 2))
twolen=$(($twolen))
thrlen=-$(($thrlen + 2))
foulen=-$(($foulen + 2))
while read -r line; do
  if [[ $line == 'r'*'s'*'d'* ]]; then
    device="/dev/`echo $line | awk '{print $3}'`"
    serial=`smartctl -i $device | grep 'Serial number:' | awk '{print $3}'`
    one=`echo "$line" | awk '{print $1}'`
    two=`echo "$line" | awk '{print $2}'`
    thr=`echo "$line" | awk '{print $3}'`
    fou=`echo "$line" | awk '{print $4}'`
    printf "%${onelen}s%${twolen}s  %${thrlen}s%${foulen}s%s\n" $one $two $thr $fou $serial >> $filename
  fi
done < <(lsblk -o label,size,name,mountpoint | sort)
chown 1000 $filename
chgrp 1000 $filename
