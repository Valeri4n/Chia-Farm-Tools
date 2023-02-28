#!/bin/bash
# Copyright 2023 by Valerian

# Run as many instances of this script in parallel as needed to move plots from cache.
# This will look to see if a plot is already being moved. If not, it will move it. If so, it will go to the next plot.
# Moves plots from the cache drive specified, ex. 5 for cache5, to a storage drive locally

# You will need to have a name for the plots being made in both the cache source drive and the destination drive.
#   This script will move plots to drives with that same pointer file in them.
#   For example, create a file called nft-SomeName on the cache drive and also put that file into all the drives you want 
#     filled with those sets of plots and it will fill them. Create a name for each farmer/contract pair and this can be 
#     used as a way to organize plots. If you only have one farmer and one contract, then you only need one name.

if [ -z $1 ] || [ -z $2 ]; then
  echo "Must enter cache path first followed by final storage path: ./plot_mover.sh /cache/path /mnt/storage"
  echo "Exiting"
  exit
fi

echo
echo "Using plotter cache drive $1"
echo "Plots will be moved to automatically fill all drives mounted in $2"
echo "Simply run plotter continually plotting to cache location"
echo "Run as many instances of this script as needed to move plots faster. Multiple instances will deconflict themselves on teh same machine."
echo

CACHE=$1 # Source drive
MOUNT=$2 # Destination directory

#k32 C0=108836000
#k33 C0=230000000
#k34 C0=462000000

#Cache drive location - change as needed
#CACHE=/svr/$1/cache$2
# Farm drive location - change as needed. It will iterate all drives in this directory
#MOUNT=/mnt

size_pointer=`ls $CACHE/drive-size-* 2>/dev/null|wc -l`
if [ $((size_pointer)) -eq 0 ]; then
  size=`df $CACHE|awk '{print $2}'|sed -n 2p`
  touch $CACHE/drive-size-$size
fi

printf "\n"
while true; do
  ls $CACHE/*.plot 2>/dev/null | while read plot; do
    # ----------------------------------------
    # Look to see if plots exist in cache drive. Don't proceed until they do.
    if [ -f $plot ]; then
      plot_moving=`ps aux | grep $plot | grep -v -e --color -e "grep" | wc -l`
      if [ $((plot_moving )) -eq 0 ]; then
        NFT=$(basename $(find $CACHE -type f -name nft-* 2>/dev/null))
        # determine the plot size
        plot_size=`du -k "$plot" | cut -f1`
        # ----------------------------------------
        # Look to see if the destination drive currently has any other plots actively being copied to it. If so, skip that drive.
        for sd__ in $MOUNT/sd* ; do
          if [ "$(ls -la $sd__/.plot-* 2>/dev/null | wc -l)" -eq 0 ]; then # && [[ $NFT == ]]; then
            if [ -f $sd__/$NFT ]; then
              AVAIL=$(df $sd__ --output=avail | awk -F "[[:space:]]+" '{print $1}' | tail -n 1)
              if [ $((AVAIL)) -gt $((plot_size)) ]; then
                if [ "$(ls -la $sd__/.plot-* 2>/dev/null | wc -l)" -eq 0 ]; then
                  printf " -> $sd__"
                  finLOC=$sd__
                  break
                fi
              fi
            fi
          fi
        done
        # ----------------------------------------
        # Plots exist and there is space in a destination drive. Move all the plot.
        if [ ! -z $finLOC ]; then
          used=`du $CACHE|awk '{print $1}'`
          size=`ls $CACHE/drive-size-*|awk -F "drive-size-" '{print $2}'`
          full=`printf "%.0f" $(awk "BEGIN {print $used/$size*100}")`
          DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
          num_plots=`ls $CACHE/*.plot|wc -l`
          if [ $((num_plots)) -eq 1 ]; then mult=""; else mult="s"; fi
          (( n = RANDOM % 30 ))
          sleep_time=`printf '%s.%s\n' $(( n / 10 )) $(( n % 10 ))`
          sleep ${sleep_time}
          plot_moving=`ps aux | grep $plot | grep -v -e --color | wc -l`
          if [ $((plot_moving )) -gt 1 ]; then break; fi
          tput_hi=`(tput setaf 3)`
          tput_lo=`(tput setaf 6)`
          tput_off=`(tput sgr0)`
          printf "${tput_lo}\n\n$DT-$TM ${tput_hi}$full"%%" with $num_plots plot$mult${tput_lo} -> $finLOC\n${tput_off}"
          ls $plot | xargs -P1 -I% rsync -vhW --chown=$USER:$USER --chmod=0744 --progress --remove-source-files % $finLOC/
          break
        else
          printf "No drive space found. Waiting 60 seconds to recheck.\n"
          sleep 10
        fi
      fi
    else
      cnt=$(($cnt + 1))
      sp="-\|/"
      DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
      printf "\r$DT $TM  \b${sp:cnt%${#sp}:1} no plots $1/cache$2"
      sleep 0.2
    fi
  done
  cnt=$(($cnt + 1))
  sp="-\|/"
  DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
  printf "\r$DT $TM  \b${sp:cnt%${#sp}:1} waiting $1/cache$2"
  sleep 1
done
