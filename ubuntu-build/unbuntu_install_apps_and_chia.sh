#!/bin/bash
#
# Copyright 2025 by Valerian
#
# This script will install all programs and drives needed to farm chia for a fresh Ubuntu build.
# Ensure plot drives are physically connected prior to running but do not mount them.
# The script will mount drives and load into chia.
# Script must be run as root.

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
  host="8.8.8.8" # Google Public DNS
  count=1
  timeout=2
  if ping -c $count -W $timeout $host > /dev/null 2>&1; then
    echo "Internet connection is UP"
    exit 0
  else
    echo "Internet connection is DOWN"
    exit 1
  fi
  # check DNS working
  host="google.com" # Google Website
  if ping -c $count -W $timeout $host > /dev/null 2>&1; then
    echo "DNS is working"
    exit 0
  else
    echo "DNS is NOT working"
    exit 1
  fi
}

maximize_drivespace(){
  echo "MAXIMIZING MAIN DRIVE SPACE"
  name=$(df -h /home|sed -n 2p|awk '{print $1}')
  sudo lvextend -l +100%FREE $name
  sudo resize $name
  echo
  tput setaf 3
  df -h /home
  echo
  tput sgr0
}

install_apps(){
  echo "INSTALLING APPS"
  ## Initial app install  
  # Replace `<<<your timezone>>>` with your timezone. Get list with `timedatectl list-timezones`  
  # Replace `<<<samba username>>>` with your own  
  # ```
  # sudo timedatectl set-timezone <<<your timezone>>>
  linux_image="linux-image-generic-hwe-$(lsb_release -a 2>/dev/null|grep Release|awk '{print $2}')"
  export DEBIAN_FRONTEND=noninteractive
  sudo apt update
  sudo apt full-upgrade -y
  sudo apt install -y ca-certificates curl gnupg samba cifs-utils smartmontools mdadm xfsprogs\
  ledmon tmux ${linux_image}
  #sudo smbpasswd -a <<<samba username>>> Only needed if using samba mounts
}

install_headers(){
  echo "INSTALLING LINUX-HEADERS"
  sudo apt install linux-headers-$(uname -r)
}

install_cuda(){
  echo "INSTALLING CUDA"
  ## Install cuda and nvidia  
  os=$(lsb_release -a 2>/dev/null|grep Distributor|awk '{print $3}'|sed 's/[A-Z]/\L&/g')
  release=$(lsb_release -a 2>/dev/null|grep Release|awk '{print $2}'|sed 's/\.//g')
  distro=${os}${release}
  arch=$(uname -p)
  wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-keyring_1.1-1_all.deb
  sudo dpkg -i cuda-keyring_1.1-1_all.deb
  wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-archive-keyring.gpg
  sudo mv cuda-archive-keyring.gpg /usr/share/keyrings/cuda-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg]\
  https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/\
  /"|sudo tee /etc/apt/sources.list.d/cuda-$distro-$arch.list
  wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.pin
  sudo mv cuda-$distro.pin /etc/apt/preferences.d/cuda-repository-pin-600
  sudo apt update
  sudo apt install -y cuda
  sudo apt install -y nvidia-gds
  sudo apt autoremove -y
}

verify_cuda(){
  echo "VERIFYING CUDA INSTALL"
  if [[ $(nvidia-smi|sed -n 3p|grep -c "Driver Version") -eq 0 ]]; then
    printf "\nNVIDIA-SMI DOES NOT APPEAR TO BE WORKING.\n\nTROUBLESHOOT TO FIND ERROR AND RUN SCRIPT AGAIN.\n"
    rm /var/run/rebooting-for-cuda
    sudo update-rc.d myupdate remove
    touch /var/run/rebooting-for-cuda
    sudo update-rc.d myupdate defaults
    exit 1
  else
    printf "\nCUDA INSTALL SUCCESSFUL\n"
  fi
}

install_chia(){
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
}

add_plot_drives(){
  echo "MOUNTING AND ADDING PLOT DRIVES"
  drive_count=0
  sudo chown -R $USER: /mnt
  #lsblk -l -o fstype,name,type,fssize,mountpoint|grep -e 'ext4.* sd'|grep -v -e LVM -e boot -e /
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
}

start_chia(){
  echo "STARTING CHIA"
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
  chia init
  nohup /usr/bin/chia-blockchain &
}

if [ -f /var/run/rebooting-for-cuda ]; then
  check_root
  verify_cuda
  rm /var/run/rebooting-for-cuda
  sudo update-rc.d myupdate remove
  verify_internet
  install_chia
  add_plot_drives
  start_chia
elif [ -f /var/run/rebooting-for-headers ]; then
  check_root
  verify_internet
  install_cuda
  rm /var/run/rebooting-for-headers
  sudo update-rc.d myupdate remove
  touch /var/run/rebooting-for-cuda
  sudo update-rc.d myupdate defaults
  sudo reboot
elif [ -f /var/run/rebooting-for-apps ]; then
  check_root
  verify_internet
  install_headers
  rm /var/run/rebooting-for-apps
  sudo update-rc.d myupdate remove
  touch /var/run/rebooting-for-headers
  sudo update-rc.d myupdate defaults
  sudo reboot
else
  check_root
  verify_internet
  maximize_drivespace
  install_apps
  touch /var/run/rebooting-for-apps
  sudo update-rc.d myupdate defaults
  sudo reboot
fi
