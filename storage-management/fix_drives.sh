#!/bin/sudo bash
# Written by Valerian - Copyright 2022
# This script will unmount, run fsck, and mount drives with errors sowhn in dmesg.

start="No errors found"
dmesg | grep -wv journal | grep EXT4 | awk '{print $3}' | sed 's/(//' | sed 's/)://' | sort -t: -u -k1,1 | while read drive; do
  if [ ! -z $drive ] && [[ ! $drive == error ]] && [[ ! $drive == mount ]] && [[ ! $drive == warning ]]; then
    printf "\n\n$drive has errors. Will attempt to fix.\n"
    umount /dev/$drive
    fsck /dev/$drive -y
    mount /dev/$drive /mnt/$drive
    start="The following drives had errors:"
    sdrive="$sdrive $drive"
  fi
done
dmesg | grep -wv journal | grep EXT4 | awk '{print $5}' | sed 's/)://' | sed 's/)//' | sort -t: -u -k1,1 | while read drive; do
  if [ ! -z $drive ] && [[ ! $drive == error: ]] && [[ ! $drive == mount: ]] && [[ ! $drive == filesystem ]] && [[ ! $drive == to ]] && [[ ! $drive == callbacks ]] && [[ ! $drive == warning ]]; then
    printf "\n\n--$drive has errors. Will attempt to fix.\n"
    umount /dev/$drive
    fsck /dev/$drive -y
    mount /dev/$drive /mnt/$drive
    start="The following drives had errors:"
    sdrive="$sdrive $drive"
  fi
done
DT=`date +"%Y%m%dT%H%M"`
dmesg -T -c > /home/harvest/logs/dmesg-$DT.log
#dmesg -c
sleep 10
dmesg | grep -wv journal | grep EXT4 | awk '{print $3}' | sed 's/(//' | sed 's/)://' | sort -t: -u -k1,1 | while read drive; do
  if [ ! -z $drive ] && [[ ! $drive == error ]] && [[ ! $drive == mount ]] && [[ ! $drive == warning ]]; then
    edrive="$edrive $drive"
  fi
done
dmesg | grep -wv journal | grep EXT4 | awk '{print $5}' | sed 's/)://' | sed 's/)//' | sort -t: -u -k1,1 | while read drive; do
  if [ ! -z $drive ] && [[ ! $drive == error: ]] && [[ ! $drive == mount: ]] && [[ ! $drive == filesystem ]] && [[ ! $drive == to ]] && [[ ! $drive == callbacks ]]; then
    edrive="$edrive $drive"
  fi
done
if [ -z $edrive ] && [ ! -z sdrive ]; then
  end="All drives repaired.\n"
else
  end="\nRepair was attempted and the following drives still have errors: $edrive"
fi
echo "start=$start"
printf "\n\n$start$sdrive.\n$end\n"
