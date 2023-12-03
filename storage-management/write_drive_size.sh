#!/bin/bash
#
# Copyright 2023 by Valerian

# This script will add the drive size and nft poitn files to a drive
# Inpout values for mountpoint, SRC drive true or false, and nft NAME
# SRC is true when it is a plotter output cache drive. False when a storage drive.

mountpoint=/mnt/cache
SRC=true
NFT=NAME

drive=$(mount|grep $mountpoint)
if $SRC; then nft_sw="_"; else nft_sw="-"; fi
space=$(df ${drive}|sed -n 2p|awk '{print $2}')
size=$(lsblk -o size ${drive}|sed -n 2p|sed 's/ //g')
if [[ $(echo $size|tail -c 2) == G ]]; then
  size=$(bc <<< "scale=2 ; $(echo $size|head -c -2) / 1000")
  size=$(printf "%'0.2f" "$size")T
fi
touch ${mountpoint}/nft${nft_sw}${NFT}
new_file=${mountpoint}/drive-size-${space}-${size}
touch $new_file
echo "$new_file nft${nft_sw}${NFT}"
