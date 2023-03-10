#!/bin/sudo bash
#
# Copywrite 2023 by Valerian
#
# Run by using
# ./eject_drive.sh [indentifier]
# Identifier can be drive name, label, mountpoint, serial, or wwn

input_value=$1

get_mount() {
# if [ $1 = '-l' ] && [ ! -z $2 ]; then
  MOUNT=(`lsblk -o mountpoint,label,name,serial,wwn,size | grep "$input_value " | awk '{print $1}'`)
  PART=`df -h $MOUNT|awk '{print$1}'|awk -F/ '{print $3}'|sed -n 2p`
# else
#   MOUNT=0
#   PART=$1
# fi
}

if [ ! "`whoami`" = "root" ]; then
  printf "\nPlease run script as root. Exiting\n\n"
  exit 1
fi
##for i in "${MOUNT[@]}"; do
  #if [[ "$i" = 0 ]]; then
    get_mount
    DIR=$PART
    found=`mount|grep "${DIR} "|awk '{print $1}'|wc -l`
    if [ $((found)) -eq 0 ]; then continue; fi
    #PART=`mount|grep "${DIR} "|awk '{print $1}'`
    mountpoint=`mount|grep "${DIR} "|awk '{print $3}'`
  # else
  #   PART=`df -h $i|awk '{print$1}'|awk -F/ '{print $3}'|sed -n 2p`
  #   mountpoint=" from $i"
  # fi
  
  DRIVE=${PART//[[:digit:]]/}
  echo
  echo "Locating and unmounting $mountpoint"
  ledctl locate=/dev/$DRIVE &
  umount /dev/$PART
  echo "Deactivating LVM partition of /dev/$PART"
  vgchange -an /dev/$PART
  echo "  And trying /dev/$DRIVE for good measure"
  vgchange -an /dev/$DRIVE
  echo "Spinning down /dev/$DRIVE"
  hdparm -Y /dev/$DRIVE
  echo "Preparing kernel to unplug /dev/$DRIVE"
  echo 1 | tee /sys/block/$DRIVE/device/delete
  while true; do
    sleep 1
    completed=`lsblk | grep $DRIVE | wc -l`
    if [ $(($completed)) -eq 0 ]; then break; fi
  done
  printf "\n $DRIVE ready to remove.\n\n"
#done

#These are for usb attached storage
#echo "Powering off /dev/$DRIVE"
#udisksctl power-off -b /dev/$DRIVE
