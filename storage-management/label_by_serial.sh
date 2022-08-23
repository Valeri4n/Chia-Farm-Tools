#!/bin/sudo bash
# Written by Valerian - Copyright 2022
# Locate a drive by serial number and apply a label
#
# Run as ./label_by_serial.sh serial label
# If the partition has a number, include the number in e2label /dev/sd$i$j[number] $label
#
# This is useful when drive name is not known to apply a partition label for the drive's physical location.
# To clear a drive label or to find drive name and mountpoint, press enter for blank label

if [ ! "`whoami`" = "root" ]; then
  printf "\nPlease run script as root. Exiting\n\n"
  exit 1
fi

serial=$1
label=$2

if [ -z $1 ]; then read -p "Enter drive serial: " serial; if [ -z $serial ]; then echo "No drive serial. Exiting."; exit 1; fi; fi
if [ -z $2 ]; then read -p "Enter drive label (enter for none): " label; fi

found=""
skip=0
for i in {a..z}; do
  for j in {a..z}; do
    found=`smartctl -i /dev/sd$i$j 2>/dev/null | grep $serial`
    if [ ! -z "$found" ]; then
      echo "$serial /dev/sd$i$j at $label"
      e2label /dev/sd$i$j $label
      lsblk -o name,label,mountpoint,size | grep sd$i$j
      exit 1
    fi
  done
done
tput setaf 3
echo "Serial $serial not found."
tput sgr0
