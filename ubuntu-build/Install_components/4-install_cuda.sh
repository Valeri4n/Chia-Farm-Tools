#!/bin/bash
# 
# Copyright 2025 by Valerian
#
# Install Cuda

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
  exec 2>&1>& ubuntu_build-$iteration.txt
}

install_cuda(){
  tmux new-session
  this_time=$(date +%y%m%d.%H:%M:%S)
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
  printf "\n\n*******************************************"
  printf "\n************* INSTALLED CUDA **************"
  printf "\n*******************************************\n\n"
  sleep 5
  reboot
}

check_root
verify_internet
initialize
install_headers
