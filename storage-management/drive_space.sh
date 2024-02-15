#!/bin/bash
#
# Copyright 2024 by Valerian

# Best to execute this in a tmux pane. It will cycel every 5 minutes to show space remaining while replotting.
# Change mountpoint to match your setup

mountpoint=/mnt/sd

while true; do
  clear
  df -h|grep "${mountpoint}\|Used"|grep -v -e 100%
  echo
  tput setaf 6
  date
  tput setaf 3
  printf "\n $(df -h|grep "${mountpoint}"|grep -v -e 100%|wc -l) drives have space\n\n"
  tput sgr0
  sleep 300
done
