#!/bin/bash
# 
# Copyright 2025 by Valerian
#
# Install Linux Headers. Needed for Cuda to work.

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
  sleep 5
  sudo reboot
}

check_root
initialize
install_headers
