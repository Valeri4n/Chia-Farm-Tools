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
if [[ $(which tmux|wc -l) -ge 1 ]]; then
  setup_tmux
  create_tmux_session
fi
install_headers
