#!/bin/sudo bash
# Locate a drive by serial number and apply a label
#
# Run as ./label_by_serial.sh serial label
# If the partition has a number, include the number in e2label /dev/sd$i$j[number] $label
#
# This is useful when drive name is not known to apply a partition label for the drive's physical location.
# To clear a drive label or to find drive name and mountpoint without a label, press enter for blank label.
# -f to find drive and not replace label

if [ ! "`whoami`" = "root" ]; then
  tput setaf 3
  printf "\nScript must be run as root. Exiting\n\n"
  tput sgr0
  exit 1
fi

serial=$1
label=$2

Flags()
{
  while true; do
    case "$1" in
      -f|--find-only)
        FND=1
        serial=$2
        label=""
        shift 2;;
      --)
        break;;
      *)
        break;;
    esac
  done
}

Flags "$@"

if [ -z $1 ]; then read -p "Enter drive serial: " serial; if [ -z $serial ]; then echo "No drive serial. Exiting."; exit 1; fi; fi
if [ -z $2 ]; then read -p "Enter drive label (enter for none): " label; fi

found=""
skip=0
for i in {a..z}; do
  for j in {0,{a..z}}; do
    if [[ $j == "0" ]]; then k=""; else k=$j; fi
    found=`smartctl -i /dev/sd$i$k 2>/dev/null | grep $serial`
    if [ ! -z "$found" ]; then
      echo "`(tput setaf 7)`$serial /dev/sd$i$k at $label`(tput setaf 6)`"
      if [ $((FND)) -ne 1 ]; then e2label /dev/sd$i$k $label; fi
      lsblk -o name,label,mountpoint,size /dev/sd$i$k | sed -n 2p
      tput sgr0
      exit 1
    fi
  done
done
tput setaf 3
echo "Serial $serial not found."
tput sgr0
