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

Initialize(){
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
  printf "\n**************** FINISHED *****************"
  printf "\n*******************************************\n\n"
  echo "Reboot if needed"
}

initialize
setup_tmux
create_tmux_session
maximize_drivespace
