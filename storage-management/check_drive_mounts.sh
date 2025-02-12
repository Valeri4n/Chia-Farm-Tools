#!/bin/bash

# Copyright 2025 by Valerian
#
# This will check drive mounts every X number of seconds.
# Run this script with sudo privilege.
# If any drives are attached to the system and not mounted, 
#   it will mount them automatically.
# This script is tailored for drives that do not have partitions.
#   It might require modification to work with partitions. 
# Change parameters as desired.

type=ext4
mount_path=/mnt/
time=10

while true; do
  cnt=$(lsblk -o mountpoint,name,fstype|grep " sd.*${type}"|grep -v /mnt/|wc -l)
  if [ $cnt -gt 0 ]; then
    while IFS= read -r line; do
      mount /dev/$line
      echo "mounted $line at $(date)"
    done < <( lsblk -o mountpoint,name,fstype|grep " sd.*${type}"|grep -v ${mount_path}|awk '{print $1}' )
  fi
  sleep ${time}
done
