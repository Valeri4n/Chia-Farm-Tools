#!/bin/bash
# Copyright 2023 by Valerian

# Run as many instances of this script in parallel as needed to move plots from cache.

# - Running test cases

version() {
  printf "\n plot_mover.sh version = 1.3.6* test  \n\n"
}

help() {
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
  echo "needed if using manual mode. A drive must be mounted in destination unless using -m and -f."
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
  echo "'SomeName' can be any name you choose to use. Associating a name with the farmer/contract pair can be"
  echo "useful when plotting for multiple farmer or contract keys. The Chia GUI displays a name on the Pool"
  echo "Overview page that is generated when a Plot NFT is created. This name could be used here as a"
  echo "convenient means of keeping track of various Plot NFTs."
  echo 
  echo "  Automatic Mode:"
  echo "    Source file = nft_SomeName"
  echo "    Destination = nft-SomeName"
  echo
  echo "Usage:"
  echo " ./plot_mover.sh <source> <destination mount location> [options]"
  echo 
  echo "Options:"
  echo "  -h, --help     Print help, usage and options to run the script."
  echo "  -f, --force    Force plots to transfer even if destination directory is not a mounted drive."
  echo "  -m, --manual   Used to move plots to a single destination location. This is useful when"
  echo "                   wanting to fill a single drive with plots. This option will not look for other"
  echo "                   instances of plots being moved to the drive and will move plots concurrently."
  echo "                   The nft_SomeName/nft-SomeName pointer files are not needed in manual mode."
  echo "  -o, --overlap  Allows concurrently overlapping writes to destination drives. Specify the number of"
  echo "                   concurrent writes allowed to one drive at a time. If set to 1, no overlap occurs."
  echo "                   example: -o 2 -> permits two concurrent writes to a drive. Default overlap is 2."
  echo "                   If manually specifying write overlap, the minimum is 1, and maximum is 9."
  echo "                   Overlap may be useful when the number of plot_mover instances exceeds the number of"
  echo "                   drives to fill, but performance may be reduced. Script will seek drives not in use first."
  echo "  -v, --version  Provides version number and exits."
  echo 
}

flags() {
  while true; do
    case $1 in
      -h|--help)
        help; exit 1; shift 1;;
      -m|--manual)
        manual=true; shift 1;;
      -f|--force)
        force=true; forced=" AND FORCED"; shift 1;;
      -o|--overlap)
        num_overlap=$2
        if [[ -z $num_overlap ]] || [ $((num_overlap)) -lt 1 ] || [ $((num_overlap)) -gt 9 ]; then
          printf "\nOverlap is 1-9. 1 is no overlapping drive writes. Default 2. Exiting."
          exit 1
        fi
        shift 2;;
      -v|--version)
        version; exit 1; shift 1;;
      --)
        break;;
      *)
        break;;
    esac
  done
}

set_variables() {
  overlap=true
  num_overlap=2
  manual=false
  force=false
  overlap_str="overlap:2"
  tput_hi=`(tput setaf 3)`
  tput_lo=`(tput setaf 6)`
  tput_off=`(tput sgr0)`
}

#k32 C0=108836000
#k33 C0=230000000
#k34 C0=462000000

version
set_variables
flags "${@:3}"
SRC=$1 # Source drive to move plots from
DST=$2 # Destination directory where the plot drives are mounted

if [ -z $1 ] || [ -z $2 ]; then
  echo "Must enter source first followed by drive destination, -h for help: ./plot_mover.sh /cache/path /mnt"
  echo "Exiting"
  exit 1
fi

if $force && ! $manual; then printf "\nFORCE MUST BE USED IN MAUAL MODE. EXITING.\n\n"; exit 1; fi
if $manual; then printf "\nPLOT MOVER OPERATING IN MANUAL$forced MODE\n"; fi
if [[ -z $num_overlap ]] || [ $((num_overlap)) -lt 1 ] || [ $((num_overlap)) -gt 9 ]; then
  printf "\nOverlap is 1-9. 1 is no overlapping drive writes. Default 2. Exiting."
  exit 1
fi
if [ $num_overlap = 1 ]; then
  overlap=false
  overlap_str="overlap:0"
else
  overlap=true
  overlap_str="${tput_hi}overlap:$num_overlap${tput_off}"
fi

num_overlap=$(($num_overlap - 1))

# Determine the size of the SRC drive for % usage calculation
if [ "$(ls $SRC/drive-size-* 2>/dev/null|wc -l)" -eq 0 ]; then
  touch $SRC/drive-size-$(df $SRC|awk '{print $2}'|sed -n 2p)
fi

# Determine if only one drive was input
if [ $(mount|grep "$DST "|wc -l) -eq 1 ]; then one_drive=true; else one_drive=false; fi

echo "SRC=$SRC  DST=$DST  $overlap_str"
echo
while true; do
  # Look for drives not in use first, even if allowing overlapping drive writes.
  second_look=false # Reset second_look
  transferred=false
set -x
  ls $SRC/*.plot 2>/dev/null|while read plot; do
set +x
    # ----------------------------------------
    # Look to see if plots exist in SRC drive. Don't proceed until they do.
    if [ -f $plot ]; then
set -x
      plot_name=`echo ${plot##*/}`
set +x
      (( n = RANDOM % 30 )) # randomize the sleep timer 0-3 seconds
      sleep_time=`printf '%s.%s\n' $(( n / 10 )) $(( n % 10 ))`
      sleep ${sleep_time} # sleep timers to help prevent duplicate plot moves
set -x
      if [ $(ps aux|grep $plot_name|grep -v -e --color -e "grep"|wc -l) -eq 0 ]; then
        if ! $manual; then NFT=$(basename $(find $SRC -type f -name nft_* 2>/dev/null)|sed 's/_/-/g'); fi
        if ! $manual && [[ -z $NFT ]]; then
          echo "No nft_file specified. Use nft_file or manual mode. -h for help." 1>&2
          exit 1
        fi
        # determine the plot size
        plot_size=`du -k "$plot"|cut -f1`
set +x
        # ----------------------------------------
        # Look to see if the destination drive currently has any other plots actively being copied to it. If so, skip that drive.
set -x
count=0
        for drive in $DST/* ; do
          if [ $(mount|grep "$drive "|wc -l) -eq 0 ] && ! $force; then continue; fi # skip location if not mounted and not forced.
          if $manual || $one_drive; then drive=$DST; fi
set +x
count=$(($count+1))
if [ $((count)) -gt 2 ]; then exit 1; fi
          if [ $(ls -la $drive/.plot-* 2>/dev/null|wc -l) -ge 1 ]; then
            checkDT=`date "+%Y%m%d"`
            checkTM=`date "+%-H%M"`
            if [[ ${checkTM:0:1} == "0" ]]; then checkTM=${checkTM:1}; fi # Handles 00 hour
            if [[ ${checkTM:0:1} == "0" ]]; then checkTM=${checkTM:1}; fi # Handles <10 minutes in 00 hour
            for hidden_rsync in $drive/.plot-*; do # Remove any old rsync sessions
              sleep 1
              rsyncDT=`date -r $hidden_rsync "+%Y%m%d"` 2>/dev/null
              rsyncTM=`date -r $hidden_rsync "+%-H%M"` 2>/dev/null
              if [[ ${rsyncTM:0:1} == "0" ]]; then rsyncTM=${rsyncTM:1}; fi # Handles 00 hour
              if [[ ${rsyncTM:0:1} == "0" ]]; then rsyncTM=${rsyncTM:1}; fi # Handles <10 minutes in 00 hour
              if [[ ! -z rsyncDT ]] && [ $((rsyncDT)) -lt $((checkDT)) ]; then
                rm_hidden_rsync=true
              elif [[ ! -z rsyncTM ]] && [ $((${rsyncTM##+(0)})) -lt $((${checkTM##+(0)})) ]; then
                rm_hidden_rsync=true
              else
                rm_hidden_rsync=false
              fi
              if $rm_hidden_rsync && [ $(ps aux|grep $hidden_rsync|grep -v -e --color -e grep -e watch|wc -l) -lt 1 ]; then
                rm $hidden_rsync
              fi
            done
          fi
          if $second_look; then overlap_check=$num_overlap; else overlap_check=0; fi
          if $manual || [ "$(ls -la $drive/.plot-* 2>/dev/null|wc -l)" -le $overlap_check ]; then
            if $manual; then
              number_of_moves=$(ls -la $drive/.plot-* 2>/dev/null|wc -l)
              size_needed=$(($(($number_of_moves+1))*$plot_size))
            else
              size_needed=$plot_size
            fi
            if $manual || [ -f $drive/$NFT ]; then
              AVAIL=$(df $drive --output=avail|awk -F "[[:space:]]+" '{print $1}'|tail -n 1)
              if [ $((AVAIL)) -gt $((size_needed)) ]; then
                if $manual || [ $(ls -la $drive/.plot-* 2>/dev/null|wc -l) -le $overlap_check ]; then
                  printf " -> $drive$overlap_num"
                  finLOC=$drive
                  # Move the plot
                  used=`du $SRC|awk '{print $1}'|tail -1`
                  size=`ls $SRC/drive-size-* 2>/dev/null|awk -F "drive-size-" '{print $2}'`
                  full=`printf "%.0f" $(awk "BEGIN {print $used/$size*100}")`
                  DT=`date +"%m-%d"`; TM=`date +"%T"`
                  num_plots=`ls $SRC/*.plot 2>/dev/null|wc -l`
                  if [ $((num_plots)) -eq 1 ]; then mult=""; else mult="s"; fi
                  # Verify file not already being moved and not exceeding max mvoes to destination.
                  (( n = RANDOM % 50 )) # randomize the sleep timer 0-5 seconds
                  sleep_time=`printf '%s.%s\n' $(( n / 10 )) $(( n % 10 ))`
                  sleep ${sleep_time} # sleep timers to help prevent duplicate plot moves
                  num_xfers=$(ls -la $drive/.plot-* 2>/dev/null|wc -l)
                  if ! $manual && [ $num_xfers -gt $overlap_check ]; then
                    second_look=false
                    continue
                  fi
                  if $second_look; then overlap_report="${tput_hi}:$(($num_xfers+1))${tput_lo}"; else overlap_report=""; fi
                  if [ $(ps aux|grep $plot_name|grep -v -e --color|wc -l) -gt 1 ]; then break; fi
                  printf "${tput_lo}\n\n$DT $TM ${tput_hi}$full"%%" - $num_plots plot$mult${tput_lo} -> $finLOC$overlap_report $NFT\n${tput_off}"
                  # move the plot from SRC to farm
                  ls $plot 2>/dev/null| xargs -P1 -I% rsync -vhW --chown=$USER:$USER --chmod=0744 --progress --remove-source-files % $finLOC/
                  finLOC=""
                  transferred=true
                  break # exit the loop after successfully moving a plot
                fi
              fi
            fi
          fi
        done
        if [ -z $finLOC ]; then # If empty drive space not found
          if $transferred; then
            transferred=false
          elif $overlap; then
            second_look=true # Look again with overlap, if used
          else
            printf "No drive space found. Waiting 60 seconds to recheck.\n"
            sleep 60
          fi
        fi
      fi
set +x
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