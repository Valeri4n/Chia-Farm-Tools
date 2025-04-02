#!/bin/bash
# 
# Copyright 2025 by Valerian
#
# Maxime drive utilization of partition
# This is useful on a new Ubuntu build where the partition may not have been
#   fully utilized on initial install.
# Also helpful is using a VM and wanting to expand the size of the filesystem
#
# Note: Current version of script will not say if drive space was expanded.

check_root(){
  echo "CHECKING RUN AS ROOT"
  # Ensure run as root
  if [[ $(/usr/bin/id -u) -ne 0 ]]; then
      echo "Not running as root, exiting."
      exit
  fi
}

initialize(){
  echo 2
#  has_errors=false
  echo 3
  SCRIPTPATH=$(realpath "$0")
  echo 4
  iteration=$(echo $SCRIPTPATH|awk -F/ '{print $4}'|awk -F- '{print $1}')
  echo 5
  exec 2>&1>& ubuntu_build-$iteration.txt
  echo 6
}

maximize_drivespace(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  drive_size=$(lsblk -b -o name,size,fssize|grep ubuntu|awk '{print $2}')
  fs_size=$(lsblk -b -o name,size,fssize|grep ubuntu|awk '{print $3}')
  if [[ $drive_size -eq $fs_size ]]; then
    echo "Filesystem already maximized. Exiting"
    exit
  fi
  echo "MAXIMIZING MAIN DRIVE SPACE"
  name=$(df -h /home|sed -n 2p|awk '{print $1}')
  sudo lvextend -l +100%FREE $name
  sudo resize $name
  echo
  tput setaf 3
  df -h /home
  echo
  tput sgr0
  final_fs_size=$(lsblk -b -o name,size,fssize|grep ubuntu|awk '{print $3}')
  if [[ $final_fs_size -eq $fs_size ]]; then
    msg="********** FINISHED - NO CHANGES **********"
    msg1="Exiting"
    sleep_time=0
    reboot_system=false
  else
    msg="********** MAXIMIZED DRIVE SPACE **********"
    reboot_system=true
    msg1="Rebooting"
    sleep_time=5
  fi
  printf "\n\n*******************************************"
  printf "\n${msg}"
  printf "\n*******************************************\n\n"
  echo $msg1
  sleep ${sleep_time}
  if $reboot_system; then
    sudo reboot
  fi
}

check_root
initialize
maximize_drivespace
