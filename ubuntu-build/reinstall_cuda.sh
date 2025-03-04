#!/bin/bash

# Copyright 2025 by Valerian
#
# If having trouble with cuda (e.g., nvidia-smi won't run), this script
#  will completely uninstall and reinstall cuda and nvidia drivers.

# Ensure run as root
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root, exiting."
    exit
fi

os=$(lsb_release -a 2>/dev/null|grep Distributor|awk '{print $3}'|sed 's/[A-Z]/\L&/g')
release=$(lsb_release -a 2>/dev/null|grep Release|awk '{print $2}'|sed 's/\.//g')
distro=${os}${release}
arch=$(uname -p)

printf "\n************ PURGING PREVIOUS CUDA INSTALL AND NVIDIA DRIVERS ************\n\n"
sudo apt remove --purge '^nvidia-.*' -y
sudo apt remove --purge '^libnvidia-.*' -y
sudo apt remove --purge '^cuda-.*' -y

printf "\n************************* PREPARING FOR INSTALL **************************\n\n"
export DEBIAN_FRONTEND=noninteractive
sudo apt install linux-headers-$(uname -r) -y
wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-archive-keyring.gpg
sudo mv cuda-archive-keyring.gpg /usr/share/keyrings/cuda-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/ /" | sudo tee /etc/apt/sources.list.d/cuda-$distro-$arch.list
wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.pin
sudo mv cuda-$distro.pin /etc/apt/preferences.d/cuda-repository-pin-600
printf "\n***************************** RUNNING UPDATE *****************************\n\n"
sudo apt update
printf "\n**************************** RUNNING UPGRADE *****************************\n\n"
sudo apt full-upgrade -y
printf "\n**************** INSTALLING CUDA AND LATEST NVIDIA DRIVER ****************\n\n"
for i in {1..10}; do
  version_check=$(sudo apt list nvidia-utils-* 2>/dev/null|tail -n $i|awk -F/ '{print $1}'|sed -n 1p)
  if [[ $(echo $version_check|awk -F- '{print $NF}') == "server" ]]; then
    continue
  else
    nvidia_version=$version_check
    break
  fi
done
sudo apt install -y cuda nvidia-cuda-toolkit nvidia-gds $nvidia_version
printf "\n************************* INSTALLING NVIDIA-GDS **************************\n\n"
sudo apt install -y nvidia-gds
printf "\n****************** INSTALLATION COMPLETE - CLEANING UP *******************\n\n"
sudo apt autoremove -y
printf "\n**************************** CHECKING INSTALL ****************************\n\n"
if [[ $(nvidia-smi|sed -n 3p|grep "Driver Version"|wc -l) -eq 0 ]] then
  printf "\nINSTALL DID NOT COMPLETE. CHECK FOR ERRORS.\n\n"
else
  printf "\n******************************* REBOOTING ********************************\n\n"
  sudo reboot
fi
