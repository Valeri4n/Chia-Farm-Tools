#!/bin/bash
# 
# Copyright 2025 by Valerian
#
# Verify cuda and install chia.
# This script will look for the chia db file in one of the loaded HDDs and copy it to the chia folder.
# All plot drives will be loaded automatically into the system and chia app.

check_root(){
  echo "CHECKING RUN AS ROOT"
  # Ensure run as root
  if [[ $(/usr/bin/id -u) -ne 0 ]]; then
      echo "Not running as root, exiting."
      exit
  fi
}

verify_internet(){
  echo "VERIFY INTERNET CONNECTIVITY"
  # check internet connectivity
  #host="8.8.8.8" # Google Public DNS
  count=1
  timeout=2
  for host in {8.8.8.8,google.com}; do
    if [[ "$host" == "google.com" ]]; then
      msg="DNS"
    else
      msg="INTERNET"
    fi
    if [[ $(ping -c $count -W $timeout $host|grep -c "1 received") -eq 1 ]]; then
      echo "$msg is working"
    else
      echo "$msg is NOT working"
      exit 1
    fi
  done
}

initialize(){
  has_errors=false
  SCRIPTPATH=$(realpath "$0")
  iteration=$(echo $SCRIPTPATH|awk -F/ '{print $4}'|awk -F- '{print $1}')
  exec &> >(tee ubuntu_build-$iteration.txt)
}

verify_cuda(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  echo "VERIFYING CUDA INSTALL"
  if [[ $(nvidia-smi|sed -n 3p|grep -c "Driver Version") -eq 0 ]]; then
    printf "\n\n************************************************"
    printf "\nNVIDIA-SMI DOES NOT APPEAR TO BE WORKING.\n\nTROUBLESHOOT TO FIND ERROR AND RUN SCRIPT AGAIN.\n"
    printf "\n\n************************************************"
    exit 1
  else
    printf "\nCUDA INSTALL WAS SUCCESSFUL\n"
  fi
  printf "\n\n*******************************************"
  printf "\n************** VERIFIED CUDA **************"
  printf "\n*******************************************\n\n"
  sleep 2
}

install_chia(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  ## Install chia-blockchain-cli  
  echo "INSTALLING CHIA-BLOCKCHAIN"
  if [[ $(dpkg -l ubuntu-desktop|grep -c desktop) -eq 0 ]]; then
    cli="-cli"
  else
    cli=""
  fi
  curl -sL https://repo.chia.net/FD39E6D3.pubkey.asc | sudo gpg --dearmor -o /usr/share/keyrings/chia.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/chia.gpg] https://repo.chia.net/debian/\
  stable main"|sudo tee /etc/apt/sources.list.d/chia.list > /dev/null
  sudo apt update
  sudo apt install -y chia-blockchain${cli}
  printf "\n\n*******************************************"
  printf "\n************* INSTALLED CHIA **************"
  printf "\n*******************************************\n\n"
  sleep 2
}

add_plot_drives(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  echo "MOUNTING AND ADDING PLOT DRIVES"
  drive_count=0
  sudo chown -R $USER: /mnt
  for drive in $(lsblk -l -o fstype,name,type,fssize,mountpoint|grep -e 'ext4.* sd'|grep -v -e LVM -e boot |awk '{print $2}'); do
    echo "Processing drive $drive"
    mkdir /mnt/${drive}
    echo "/dev/${drive} /mnt/${drive} ext4 defaults,nofail 0 0"|sudo tee -a /etc/fstab
    sudo systemctl daemon-reload
    sudo mount /mnt/${drive}
    chia plots add -d /mnt/${drive}
    drive_count=$((drive_count + 1))
  done
  if [ $drive_count -gt 0 ]; then
    if [ $drive_count -gt 1 ]; then
      drive_plural="s"
    else
      drive_plural=""
    fi
    echo "Mounted and loaded $drive_count drive${drive_plural} into chia harvester"
  else
    echo "No drives were mounted or loaded into chia harvester. Manually add drives later."
  fi
  printf "\n\n*******************************************"
  printf "\n********* ADDED DRIVES TO SYSTEM **********"
  printf "\n*******************************************\n\n"
  sleep 2
}

start_chia(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  #copy the db file
  db_file="blockchain_v2_mainnet.sqlite"
  db_path=$(find /mnt -name ${db_file} 2>/dev/null)
  if [[ ! -z $db_path ]]; then
    echo "COPYING CHIA DB FILE"
    db_chia_folder="/home/$USER/.chia/mainnet/db/"
    mkdir -p $db_chia_folder
    rsync -WhP ${db_path} ${db_chia_folder}${db_file}
  fi
  key_folder=".chia_keys"
  key_path=$(find /mnt -name ${key_folder} 2>/dev/null)
  if [[ ! -z $key_path ]]; then
    echo "COPYING CHIA KEYS FOLDER"
    key_chia_folder="/home/$USER/"
    rsync -WhrP ${key_path} ${key_chia_folder}${key_folder}
  fi
  echo "STARTING CHIA"
  chia init
  nohup /usr/bin/chia-blockchain &
  printf "\n\n*******************************************"
  printf "\n************** STARTED CHIA ***************"
  printf "\n*******************************************\n\n"
  sleep 2
  printf "\n\n*******************************************"
  printf "\n** UBUNTU BUILD INSTALLED SUCCESSFULLY! ***"
  printf "\n*******************************************\n\n"
}

check_root
verify_internet
initialize
verify_cuda
install_chia
add_plot_drives
start_chia
