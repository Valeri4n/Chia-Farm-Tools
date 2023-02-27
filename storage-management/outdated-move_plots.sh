#!/bin/bash
# Copyright 2022 by Valerian
#
# This moves plots from the source drive specified to a locally mounted storage drive
# 
# If automating movement of plots from source to multiple destination drives,
#   create a file called nft-NAME on source and all destination locations. This will automatically
#   fill all of the destination drives for as long as the script runs. Script will wait
#   for more plots to be made and continue moving plots automatically.
#   This will ensure those plots are moved to only locations specified and is great way to auto manage storage
#
# If running multiple concurrent scripts, this will not copy plots to same drive at the same time
#   unless change COINcide to true

COIN=false

#k32=108836000
#k33=230000000
#k34=462000000

# SRC is the single source directory to watch for plots
SRC=/mnt/cache
# DEST is what comes after the MOUNT location. /mnt/plots/dest1, /mnt/plots/dest2 would be DEST=plots/dest
#   DEST is the portion of the mount location that doesn't change
DEST=/mnt/sd

NFT=$(basename $(find $SRC -type f -name nft-* 2>/dev/null))
if [ -z $NFT ]; then
  auto=false
  echo "nft file not found. Running for existing plots only."
else
  auto=true
  echo "nft file found. Running continuously for existing and new plots."
fi
printf "\n"
while true; do
  for plot in $SRC/*.plot; do
    # ----------------------------------------
    # Look to see if plots exist in source drive. Don't proceed until they do.
    if [ -f $plot ]; then
      # determine the plot size
      plot_size=`du -k "$plot" | cut -f1`
      # ----------------------------------------
      # Look to see if the destination drive currently has any other plots actively being copied to it. If so, skip that drive.
      for dst in $DEST* ; do
        if [ "$(ls -la $dst/.plot-* 2>/dev/null | wc -l)" -eq 0 ] || [ $COIN == true ]; then
          if [ -f $dst/$NFT ] || [ $auto == false ]; then
            AVAIL=$(df $dst --output=avail | awk -F "[[:space:]]+" '{print $1}' | tail -n 1)
            if [ $((AVAIL)) -gt $((plot_size)) ]; then
              printf " -> $dst"
              finLOC=$dst
              break
            fi
          fi
        fi
      done
      # ----------------------------------------
      # Plots exist and there is space in a destination drive. Move all the plot.
      if [ ! -z $finLOC ]; then
        DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
        printf "\n\n$DT $TM - Moving ${plot:0:36}...plot to $finLOC\n"
        ls $plot | xargs -P1 -I% rsync -vhW --chmod=0766 --progress --remove-source-files % $finLOC/ 2>/dev/null
        if [[ $? -gt 0 ]]; then
          DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
          printf "\r$DT $TM File still incoming. Waiting 10 minutes...\n"
          sleep 600
        else
          echo ""
        fi
      else
        printf "No drive space found. Waiting 60 seconds to recheck.\n"
        sleep 60
      fi
    elif [ $auto == true ]; then
      cnt=$(($cnt + 1))
      sp="-\|/"
      DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
      printf "\r$DT $TM  \b${sp:cnt%${#sp}:1} Waiting for new plots in $SRC"
      sleep 0.2
    fi
  done
done
