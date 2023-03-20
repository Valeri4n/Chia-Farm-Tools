#!/bin/bash
# Copyright 2023 by Valerian
# version 1.1

# Run as many instances of this script in parallel as needed to move plots from cache.
# This will look to see if a plot is already being moved. If not, it will move it. If so, it will go to the next plot.

help()
{
  echo 
  echo "The purpose of this script is to move plots from a source location to destination. The plots"
  echo "may be moved locally within the same system or across mounted shared drives across a network."
  echo "Run this script on the destination system so that it may determine the remaining space available"
  echo "on the destination drive before sending a plot to it."
  echo 
  echo "Ideally, to make the best use of this script to automate the transfer of plots, a pointer file is"
  echo "used to designate where to send the plots. This farmer/contract pair for the plots will be in the"
  echo "form of nft_SomeName with the underscore on source drive and nft-SomeName with the dash on the"
  echo "destination drive. This pointer file will also ensure that the drive is mounted prior to moving"
  echo "plots to it. The pointer file may be added manually to destination drives or automatically with"
  echo "the -n flag if using the format_drive.sh script in this repository."
  echo 
  echo "The source can be a cache drive for plotting or another drive that needs to be cleared of plots."
  echo "If moving plots from plotter output cache automatically, the nft_SomeName file must be used."
  echo "Note the underscore which is necessary to prevent trying to write to cache drive if in the same"
  echo "mount directory as the destiantion plot drives. This mode is called automatic. The other mode"
  echo "is called manual."
  echo 
  echo "The destination is the mount directory where the connected drives are mounted If running in"
  echo "automatic mode. For example, if /mnt is used to mount the drives /dev/sde and /dev/sdf into the"
  echo "mountpoints /mnt/sde and /mnt/sdf, etc., then /mnt should be specified as the destination."
  echo "The nft-SomeName pointer file must be used in all of destination drives for automatic mode."
  echo "If using manual mode, the destination is specified as /mnt/name. If sending to drive sdf, the"
  echo "destination will be /mnt/sdf for the mountpoint in the example above. The nft pointer file is not"
  echo "needed if using manual mode."
  echo 
  echo "In automatic mode, as many instances of this script may be run as needed to keep the plot cache"
  echo "drive cleared of plots. Multiple instances should deconflict themselves on the same machine by"
  echo "looking for which plots are actively being moved and the hidden file rsync uses when actively"
  echo "moving a file so that only one plot should be moved to any one destination drive at a time, but"
  echo "there may be occassional overlap to the destination drive. A farm with multiple destination drives"
  echo "may have as many plots moving concurrently as there are drives with free space attached. There is"
  echo "the remote possiblity that a plot could be duplicated, but this is extremely rare and should never"
  echo "occur except possibly when moving large numbers of plots concurrently from the same source drive."
  echo
  echo "Usage:"
  echo " ./plot_mover.sh <source> <destination mount location> [options]"
  echo 
  echo "Options:"
  echo "  -h, --help     Print help, usage and options to run the script."
  echo "  -m, --manual   Used to move plots to a single destination location. This is useful when"
  echo "			             wanting to fill a single drive with plots. This option will not look for other"
  echo "                   instances of plots being moved to the drive and will move plots concurrently."
  echo "  -v, --version  Provides version number and exits"
  echo 
}

flags()
{
  while true; do
    case $1 in
      -h|--help)
        help=true
        shift 1;;
      -m|--manual)
        manual=true
        printf "\nPLOT MOVER OPERATING IN MANUAL MODE\n"
        shift 1;;
      -v|--version)
        manual=true
        printf "\nplot_mover.sh version = 1.1\n\n"
        exit 1
        shift 1;;
      --)
        break;;
      *)
        break;;
    esac
  done
}

manual=false
flags "${@}"
flags "${@:3}"

if [ -z $1 ] || [ -z $2 ]; then
  echo "Must enter source first followed by drive destination, -h for help: ./plot_mover.sh /cache/path /mnt"
  echo "Exiting"
  exit 1
fi

SRC=$1 # Source drive to move plots from
DST=$2 # Destination directory where the plot drives are mounted

#k32 C0=108836000
#k33 C0=230000000
#k34 C0=462000000

# Determine the size of the SRC drive for % usage calculation
if ! $manual && [ "$(ls $SRC/drive-size-* 2>/dev/null|wc -l)" -eq 0 ]; then
  size=`df $SRC|awk '{print $2}'|sed -n 2p`
  touch $SRC/drive-size-$size
fi

# Determine if only one drive was input
if [ $(mount|grep "$DST "|wc -l) -eq 1 ]; then one_drive=true; else one_drive=false; fi

echo
while true; do
  ls $SRC/*.plot 2>/dev/null | while read plot; do
    # ----------------------------------------
    # Look to see if plots exist in SRC drive. Don't proceed until they do.
    if [ -f $plot ]; then
      plot_name=`echo ${plot##*/}`
      (( n = RANDOM % 30 )) # randomize the sleep timer 0-3 seconds
      sleep_time=`printf '%s.%s\n' $(( n / 10 )) $(( n % 10 ))`
      sleep ${sleep_time} # sleep timers to help prevent duplicate plot moves
      plot_moving=`ps aux | grep $plot_name|grep -v -e --color -e "grep"|wc -l`
      if [ $((plot_moving )) -eq 0 ]; then
        if ! $manual; then NFT=$(basename $(find $SRC -type f -name nft_* 2>/dev/null)|sed 's/_/-/g'); fi
        if ! $manual && [[ -z $NFT ]]; then
          echo "No nft_file specified. Use nft_file or manual mode. -h for help." 1>&2
          exit 1
        fi
        # determine the plot size
        plot_size=`du -k "$plot" | cut -f1`
        # ----------------------------------------
        # Look to see if the destination drive currently has any other plots actively being copied to it. If so, skip that drive.
        for drive in $DST/* ; do
          if $manual || $one_drive; then drive=$DST; fi
          if [ "$(ls -la $drive/.plot-* 2>/dev/null|wc -l)" -ge 1 ]; then
            checkDT=`date "+%Y%m%d"`
            checkTM=`date "+%-H%M"`
            for hidden_rsync in $drive/.plot-*; do # Remove any old rsync sessions
              sleep 1
              rsyncDT=`date -r $hidden_rsync "+%Y%m%d"`
              rsyncTM=`date -r $hidden_rsync "+%-H%M"`
              if [ $((rsyncDT)) -lt $((checkDT)) ]; then
                rm_hidden_rsync=true
              elif [ $((rsyncTM)) -lt $((checkTM)) ]; then
                rm_hidden_rsync=true
              else
                rm_hidden_rsync=false
              fi
              ps aux|grep $hidden_rsync|grep -v -e --color -e grep -e watch
              if $rm_hidden_rsync && [ $(ps aux|grep $hidden_rsync|grep -v -e --color -e grep -e watch|wc -l) -lt 1 ]; then
                rm $hidden_rsync
              fi
            done
          fi
          # (( n = RANDOM % 30 )) # randomize the sleep timer 0-3 seconds
          # sleep_time=`printf '%s.%s\n' $(( n / 10 )) $(( n % 10 ))`
          # sleep ${sleep_time} # sleep timers to help prevent duplicate plot moves
          if $manual || [ "$(ls -la $drive/.plot-* 2>/dev/null|wc -l)" -eq 0 ]; then
            if $manual; then
              number_of_moves=$(ls -la $drive/.plot-* 2>/dev/null|wc -l)
              size_needed=$(($(($number_of_moves+1))*$plot_size))
            else
              size_needed=$plot_size
            fi
            if $manual || [ -f $drive/$NFT ]; then
              AVAIL=$(df $drive --output=avail|awk -F "[[:space:]]+" '{print $1}'|tail -n 1)
              if [ $((AVAIL)) -gt $((size_needed)) ]; then
                if $manual || [ "$(ls -la $drive/.plot-* 2>/dev/null|wc -l)" -eq 0 ]; then
                  printf " -> $drive"
                  finLOC=$drive
                  break
                fi
              fi
            fi
          fi
        done
        # ----------------------------------------
        # Plots exist and there is space in a destination drive. Move all the plots.
        if [ ! -z $finLOC ]; then
          used=`du $SRC|awk '{print $1}'|tail -1`
          size=`ls $SRC/drive-size-*|awk -F "drive-size-" '{print $2}'`
          full=`printf "%.0f" $(awk "BEGIN {print $used/$size*100}")`
          DT=`date +"%m-%d"`; TM=`date +"%T"`
          num_plots=`ls $SRC/*.plot|wc -l`
          if [ $((num_plots)) -eq 1 ]; then mult=""; else mult="s"; fi
          (( n = RANDOM % 50 )) # randomize the sleep timer 0-5 seconds
          sleep_time=`printf '%s.%s\n' $(( n / 10 )) $(( n % 10 ))`
          sleep ${sleep_time} # sleep timers to help prevent duplicate plot moves
          if ! $manual && [ "$(ls -la $drive/.plot-* 2>/dev/null|wc -l)" -gt 1 ]; then continue; fi
          plot_moving=`ps aux|grep $plot_name|grep -v -e --color|wc -l`
          if [ $((plot_moving )) -gt 1 ]; then break; fi
          tput_hi=`(tput setaf 3)`
          tput_lo=`(tput setaf 6)`
          tput_off=`(tput sgr0)`
          printf "${tput_lo}\n\n$DT $TM ${tput_hi}$full"%%" - $num_plots plot$mult${tput_lo} -> $finLOC $NFT\n${tput_off}"
          # move the plot from SRC to farm
          ls $plot | xargs -P1 -I% rsync -vhW --chown=$USER:$USER --chmod=0744 --progress --remove-source-files % $finLOC/
          finLOC=""
          break # exit the loop after successfully moving a plot
        else
          printf "No drive space found. Waiting 60 seconds to recheck.\n"
          sleep 60
        fi
      fi
    else
      cnt=$(($cnt + 1))
      sp="-\|/"
      DT=`date +"%m-%d"`; TM=`date +"%T"`
      printf "\r$DT $TM  \b${sp:cnt%${#sp}:1} no plots $1 $NFT"
      sleep 0.2
    fi
  done
  err=$?; [[ $err != 0 ]] && exit $err
  cnt=$(($cnt + 1))
  sp="-\|/"
  DT=`date +"%m-%d"`; TM=`date +"%T"`
  printf "\r$DT $TM  \b${sp:cnt%${#sp}:1} waiting $1 $NFT"
  sleep 1
done
