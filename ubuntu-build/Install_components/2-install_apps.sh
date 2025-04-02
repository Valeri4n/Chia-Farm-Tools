#!/bin/bash
# 
# Copyright 2025 by Valerian
#
# Install apps for new Ubuntu load

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
  # Replace `<<<your timezone>>>` with your timezone. Get list with `timedatectl list-timezones` 
  time_zone="America/Chicago"
  has_errors=false
  SCRIPTPATH=$(realpath "$0")
  iteration=$(echo $SCRIPTPATH|awk -F/ '{print $4}'|awk -F- '{print $1}')
  exec &> >(tee ubuntu_build-$iteration.txt)
}

install_apps(){
  this_time=$(date +%y%m%d.%H:%M:%S)
  echo "INSTALLING APPS"
  sudo timedatectl set-timezone $time_zone
  linux_image="linux-image-generic-hwe-$(lsb_release -a 2>/dev/null|grep Release|awk '{print $2}')"
  export DEBIAN_FRONTEND=noninteractive
  sudo apt update
  sudo NEEDRESTART_MODE=a apt dist-upgrade -y
  sudo apt install -y ca-certificates curl gnupg samba cifs-utils smartmontools mdadm xfsprogs ledmon dos2unix tmux openssh-server ${linux_image}
  sudo smbpasswd -a $this_user # Only needed if using samba mounts
  sudo systemctl enable ssh
  sudo systemctl start ssh
  printf "\n\n*******************************************"
  printf "\n************* INSTALLED APPS **************"
  printf "\n*******************************************\n\n"
  sleep 5
  #sudo reboot
}

check_root
verify_internet
initialize
install_apps
