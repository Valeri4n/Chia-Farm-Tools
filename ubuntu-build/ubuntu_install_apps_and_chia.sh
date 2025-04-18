#!/bin/bash
#
# Copyright 2025 by Valerian
#
# This script will install all programs and drives needed to farm chia for a fresh Ubuntu build.
# Ensure plot drives are physically connected prior to running but do not mount them.
# The script will mount drives and load into chia.
# Script must be run as root. Run with '|tee -a ubuntu_build.txt' at end to log progress
#
# Launch with:
# wget https://raw.githubusercontent.com/Valeri4n/Chia-Farm-Tools/refs/heads/main/ubuntu-build/ubuntu_install_apps_and_chia.sh
# chmod +x ubuntu_install_apps_and_chia.sh
# sudo ./ubuntu_install_apps_and_chia.sh|tee -a ubuntu_build.txt

setup_tmux(){
  if [[ ! -f /home/${this_user}/.tmux.conf ]]; then
    cp /usr/share/doc/tmux/example_tmux.conf /home/${this_user}/.tmux.conf
    chown ${this_user}: /home/${this_user}/.tmux.conf
  fi
  if [[ $(cat /home/${this_user}/.tmux.conf|grep "set -g mouse on"|grep -v "#"|wc -l) -eq 0 ]]; then
    echo "# Enable mouse mode" >> /home/${this_user}/.tmux.conf
    echo "set -g mouse on" >> /home/${this_user}/.tmux.conf
  fi
}

create_tmux_session(){
  session=install
  tmux has-session -t $session 2>/dev/null
  if [ $? != 0 ]; then
    tmux new-session -s $session
  else
    tmux a -t $session
    printf "\n\n*******************************************"
    printf "\n***** SYSTEM DID NOT REBOOT. EXITING. *****"
    printf "\n*******************************************\n\n"
    ls -la /home/${this_user}/.InintializingUbuntuBuild*|sort -k 8
    exit
  fi
}

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
      #exit 1
    fi
  done
}

maximize_drivespace(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  touch /home/${this_user}/.InintializingUbuntuBuild_drivespace_started-${this_user}-${this_time}
  echo "MAXIMIZING MAIN DRIVE SPACE"
  name=$(df -h /home|sed -n 2p|awk '{print $1}')
  sudo lvextend -l +100%FREE $name
  sudo resize $name
  echo
  tput setaf 3
  df -h /home
  echo
  tput sgr0
  touch /home/${this_user}/.InintializingUbuntuBuild_drivespace_finished-${this_user}-$(date +%y%m%d.%H:%M:%S)
  rm /home/${this_user}/.InintializingUbuntuBuild_drivespace_started-${this_user}-${this_time}
  printf "\n\n*******************************************"
  printf "\n********** MAXIMIZED DRIVE SPACE **********"
  printf "\n*******************************************\n\n"
  sleep 15
}

install_apps(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  touch /home/${this_user}/.InintializingUbuntuBuild_apps_started-${this_user}-${this_time}
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
  sudo apt install -y ca-certificates curl gnupg samba cifs-utils smartmontools mdadm xfsprogs ledmon dos2unix ${tmux_install}${linux_image}
  if [[ ! -z $tmux_install ]]; then
    setup_tmux
  fi
  #sudo smbpasswd -a <<<samba username>>> Only needed if using samba mounts
  touch /home/${this_user}/.InintializingUbuntuBuild_apps_finished-${this_user}-$(date +%y%m%d.%H:%M:%S)
  rm /home/${this_user}/.InintializingUbuntuBuild_apps_started-${this_user}-${this_time}
  printf "\n\n*******************************************"
  printf "\n************* INSTALLED APPS **************"
  printf "\n*******************************************\n\n"
  sleep 15
}

install_headers(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  touch /home/${this_user}/.InintializingUbuntuBuild_headers_started-${this_user}-${this_time}
  echo "INSTALLING LINUX-HEADERS"
  sudo apt install linux-headers-$(uname -r)
  touch /home/${this_user}/.InintializingUbuntuBuild_headers_finished-${this_user}-$(date +%y%m%d.%H:%M:%S)
  rm /home/${this_user}/.InintializingUbuntuBuild_headers_started-${this_user}-${this_time}
  printf "\n\n*******************************************"
  printf "\n************ INSTALLED HEADERS ************"
  printf "\n*******************************************\n\n"
  sleep 15
}

install_cuda(){
  tmux new-session
  this_time=$(date +%y%m%d.%H:%M:%S)
  touch /home/${this_user}/.InintializingUbuntuBuild_cuda_started-${this_user}-${this_time}
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
  touch /home/${this_user}/.InintializingUbuntuBuild_cuda_finished-${this_user}-$(date +%y%m%d.%H:%M:%S)
  rm /home/${this_user}/.InintializingUbuntuBuild_cuda_started-${this_user}-${this_time}
  printf "\n\n*******************************************"
  printf "\n************* INSTALLED CUDA **************"
  printf "\n*******************************************\n\n"
  sleep 15
}

verify_cuda(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  touch /home/${this_user}/.InintializingUbuntuBuild_cudaVerify_started-${this_user}-${this_time}
  echo "VERIFYING CUDA INSTALL"
  if [[ $(nvidia-smi|sed -n 3p|grep -c "Driver Version") -eq 0 ]]; then
    printf "\n\n************************************************"
    printf "\nNVIDIA-SMI DOES NOT APPEAR TO BE WORKING.\n\nTROUBLESHOOT TO FIND ERROR AND RUN SCRIPT AGAIN.\n"
    printf "\n\n************************************************"
    exit 1
  else
    printf "\nCUDA INSTALL WAS SUCCESSFUL\n"
  fi
  touch /home/${this_user}/.InintializingUbuntuBuild_cudaVerify_finished-${this_user}-$(date +%y%m%d.%H:%M:%S)
  rm /home/${this_user}/.InintializingUbuntuBuild_cudaVerify_started-${this_user}-${this_time}
  printf "\n\n*******************************************"
  printf "\n************** VERIFIED CUDA **************"
  printf "\n*******************************************\n\n"
  sleep 2
}

install_chia(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  touch /home/${this_user}/.InintializingUbuntuBuild_chia_started-${this_user}-${this_time}
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
  touch /home/${this_user}/.InintializingUbuntuBuild_chia_finished-${this_user}-$(date +%y%m%d.%H:%M:%S)
  rm /home/${this_user}/.InintializingUbuntuBuild_chia_started-${this_user}-${this_time}
  printf "\n\n*******************************************"
  printf "\n************* INSTALLED CHIA **************"
  printf "\n*******************************************\n\n"
  sleep 2
}

add_plot_drives(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  touch /home/${this_user}/.InintializingUbuntuBuild_drives_started-${this_user}-${this_time}
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
  touch /home/${this_user}/.InintializingUbuntuBuild_drives_finished-${this_user}-$(date +%y%m%d.%H:%M:%S)
  rm /home/${this_user}/.InintializingUbuntuBuild_drives_started-${this_user}-${this_time}
  printf "\n\n*******************************************"
  printf "\n************** ADDED DRIVES ***************"
  printf "\n*******************************************\n\n"
  sleep 2
}

start_chia(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  touch /home/${this_user}/.InintializingUbuntuBuild_chiaEnd_started-${this_user}-${this_time}
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
  touch /home/${this_user}/.InintializingUbuntuBuild_chiaEnd_finished-${this_user}-$(date +%y%m%d.%H:%M:%S)
  rm /home/${this_user}/.InintializingUbuntuBuild_chiaEnd_started-${this_user}-${this_time}
  printf "\n\n*******************************************"
  printf "\n************** STARTED CHIA ***************"
  printf "\n*******************************************\n\n"
  sleep 2
  printf "\n\n*******************************************"
  printf "\nUbuntu build installed sucessfully!"
  printf "\n*******************************************\n\n"
  ls -la /home/${this_user}/.InintializingUbuntuBuild*|sort -k 8
}

has_errors=false
SCRIPTPATH=$(realpath "$0")
if [[ -z $1 ]]; then
  this_user=$(echo $USER)
  echo 1|select-editor
  (sudo crontab -l 2>/dev/null; echo "@reboot sleep 5; $SCRIPTPATH ${this_user}|tee -a /home/${this_user}/ubuntu_build.txt")|sudo crontab -
fi
if [ -f /home/${this_user}/.InintializingUbuntuBuild_*_started-* ]; then
  create_tmux_session
  printf "\n\n*******************************************"
  printf "\nScript error in $(echo .InintializingUbuntuBuild_*_started-*|awk -F- '{print $2}')!"
  printf "\n*******************************************\n\n"
  exit
fi
if [ -f .InintializingUbuntuBuild_cuda_finished* ]; then
  create_tmux_session
  check_root
  verify_cuda
  verify_internet
  install_chia
  add_plot_drives
  start_chia
  for file in $(ls -a /home/${this_user}/.InintializingUbuntuBuild_*_started-* 2>/dev/null); do
    has_errors=true
    touch Ubuntu_build_error_in_$(echo $file|awk -F- '{print $2}')
  done
  if ! $has_errors; then
    touch Ubuntu_build_completed_successfully-$(date +%y%m%d.%H:%M:%S)
  fi
  sudo crontab -l|grep -v "${SCRIPTPATH} ${this_user}"|sudo crontab -
  exit
elif [ -f .InintializingUbuntuBuild_headers_finished* ]; then
  create_tmux_session
  check_root
  verify_internet
  install_cuda
  sudo reboot
elif [ -f .InintializingUbuntuBuild_apps_finished* ]; then
  create_tmux_session
  check_root
  verify_internet
  install_headers
  sudo reboot
else
  if [[ $(which tmux|wc -l) -eq 1 ]]; then
    setup_tmux
    create_tmux_session
    tmux_install=""
  else
    tmux_install="tmux "
  fi
  check_root
  verify_internet
  maximize_drivespace
  install_apps
  sudo reboot
fi
