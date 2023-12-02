#!/bin/bash
#
# Copyright 2023 by Valerian

# This script will add the drive size and nft poitn files to a drive
# Inpout values for path, SRC drive True or False, and nft NAME

path=
SRC=true
nft=NAME

drive=$(mount|grep $path)
if $SRC; then nft_sw="_"; else nft_sw="-"; fi
space=$(df ${drive}|sed -n 2p|awk '{print $2}')
size=$(lsblk -o size ${drive}|sed -n 2p|sed 's/ //g')
if [[ $(echo $size|tail -c 2) == G ]]; then
  size=$(bc <<< "scale=2 ; $(echo $size|head -c -2) / 1000")
  size=$(printf "%'0.2f" "$size")T
fi
touch ${path}/nft${nft_sw}${NFT}
new_file=${path}/drive-size-${space}-${size}
touch $new_file
echo "$new_file nft${nft_sw}${NFT}"
