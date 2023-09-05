#!/bin/sudo bash
#
# Copyright 2023 by Valerian
#
# Locate a drive by serial number and apply a label
#
# Run as ./label_by_serial.sh serial label
# If the partition has a number, include the number in e2label /dev/sd$i$j[number] $label
#
# This is useful when drive name is not known to apply a partition label for the drive's physical location.
# To clear a drive label or to find drive name and mountpoint without a label, press enter for blank label.
# -f to find drive and not replace label
#set -x
if [ ! "`whoami`" = "root" ]; then
  tput setaf 3
  printf "\nScript must be run as root. Exiting\n\n"
  tput sgr0
  exit 1
fi

Flags()
{
  while true; do
    case "$1" in
      -d|--drive) # label by drive name
        DRV=1
        drive=$2
        label=$3
        shift 2;;
      -f|--find-only)
        FND=1
        serial=$2
        label=""
        shift 2;;
      -n|--name)
        name=-$2
        shift 2;;
      -s|--size-serial) # apply label SIZE-SERIAL
        SIZ=1
        serial=$1
        shift 1;;
      --)
        break;;
      *)
        break;;
    esac
  done
}

if [ ! $((FND)) -eq 1 ] && [ ! $((DRV)) -eq 1 ]; then
  serial=$1
  label=$2
fi

Flags "$@"

if [ -z $1 ]; then read -p "Enter drive serial or wwn: " serial; if [ -z $serial ]; then echo "No drive serial. Exiting."; exit 1; fi; fi
if [ -z $2 ]; then read -p "Enter drive label (enter for none): " label; fi

found=""
skip=0
if [ $((DRV)) -ne 1 ]; then
  for i in {a..z}; do
    for j in {0,{a..z}}; do
      if [[ $j == "0" ]]; then k=""; else k=$j; fi
      found=`lsblk -o size,serial,wwn,fstype /dev/sd$i$k 2>/dev/null|grep -i $serial`
      if [ ! -z "$found" ]; then
        drive=sd$i$k
        echo "`(tput setaf 7)`$serial /dev/sd$i$k at $label`(tput setaf 6)`"
      fi
    done
  done
fi
if [ $((FND)) -ne 1 ] || [ ! -z $found ]; then
  this_drive=`lsblk -o size,serial,wwn,fstype /dev/$drive|sed -n 2p`
  type=`echo $this_drive|awk '{print $4}'`
  if [ $((SIZ)) -eq 1 ]; then
    size=`echo $this_drive|awk '{print $1}'`
    serial=`echo $this_drive|awk '{print $2}'`
    wwn=`echo $this_drive|awk '{print $3}'`
    label=$size-$serial$name
  fi
  if [ $type = ntfs ]; then
    #ntfslabel /dev/$drive $label
    tune2fs -f -L $label /dev/$drive
  else
    e2label /dev/$drive $label
  fi
  lsblk -o name,label,mountpoint,size /dev/sd$i$k | sed -n 2p
  tput sgr0
  exit 1
fi

tput setaf 3
echo "Identifier $serial not found."
tput sgr0
