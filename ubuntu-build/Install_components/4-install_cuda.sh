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

initialize(){
  has_errors=false
  SCRIPTPATH=$(realpath "$0")
  if [[ -z $1 ]]; then
    this_user=$(echo $USER)
    echo 1|select-editor
    (sudo crontab -l 2>/dev/null; echo "@reboot sleep 5; $SCRIPTPATH ${this_user}|tee -a /home/${this_user}/ubuntu_build.txt")|sudo crontab -
  fi
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
  sleep 5
  reboot
}

check_root
initialize
install_headers
