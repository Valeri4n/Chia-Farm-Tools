#!/bin/bash
# Copyright 2023 by Valerian

# Run as many instances of this script in parallel as needed to move plots from cache.

#- Added exit on error
#- Improved drive handling
#- Fixed random errors

version() {
  printf "\n plot_mover.sh version = 1.3.6* test \n\n"
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
        help; exit 1
        shift 1;;
      -m|--manual)
        manual=true
        shift 1;;
      -f|--force)
        force=true; forced=" AND FORCED"
        shift 1;;
      -o|--overlap)
        num_overlap=$2
        if [[ -z $num_overlap ]] || [ $((num_overlap)) -lt 1 ] || [ $((num_overlap)) -gt 9 ]; then
          printf "\nOverlap is 1-9. 1 is single drive write at a time to any one drive. Default is 2, allowing for 2 concurrent writes to any one drive. Exiting."
          exit 1
        fi
        shift 2;;
      -v|--version)
        exit 1
        shift 1;;
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
  waited=false
  overlap_str="overlap:2"
  tput_hi=`(tput setaf 3)`
  tput_lo=`(tput setaf 6)`
  tput_off=`(tput sgr0)`
}

#k32 C0=108836000
#k33 C0=230000000
#k34 C0=462000000
set -e
version
SRC=$1 # Source drive to move plots from
DST=$2 # Destination directory where the plot drives are mounted

if [ -z $1 ] || [ -z $2 ]; then
  echo "Must enter source first followed by drive destination, -h for help: ./plot_mover.sh /cache/path /mnt"
  echo "Exiting"
  exit 1
fi

set_variables
flags "${@:3}"
if $force && ! $manual; then printf "\nFORCE MUST BE USED IN MAUAL MODE. EXITING.\n\n"; exit 1; fi
if $manual; then 
  printf "\nPLOT MOVER OPERATING IN MANUAL$forced MODE\n"
else
  NFT=$(basename $(find $SRC -type f -name nft_* 2>/dev/null) 2>/dev/null|sed 's/_/-/g')
  if [[ -z $NFT ]]; then
    echo "No nft_file specified in $SRC. Use nft_file or manual mode. -h for help." 1>&2
    exit 1
  fi
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

printf "SRC=$SRC  DST=$DST  $overlap_str\n\n"

while true; do
  # Look for drives not in use first, even if allowing overlapping drive writes.
  if $look_reset; then look_reset=false; second_look=false; transferred=false; fi # Reset second_look
  while read plot 2>/dev/null; do
    # ----------------------------------------
    # Look to see if plots exist in SRC drive. Don't proceed until they do.
    if [[ -f $plot ]]; then
      plot_name=`echo ${plot##*/}`
      n=$(($RANDOM % 30 )) # randomize the sleep timer 0-3 seconds
      sleep_time=`printf '%s.%s\n' $(( n / 10 )) $(( n % 10 ))`
      sleep ${sleep_time} # sleep timers to help prevent duplicate plot moves
      if [ $(ps aux|grep $plot_name|grep -v -e --color -e "grep"|wc -l) -eq 0 ]; then
        if ! $manual; then NFT=$(basename $(find $SRC -type f -name nft_* 2>/dev/null)|sed 's/_/-/g'); fi
        if ! $manual && [[ -z $NFT ]]; then
          echo "No nft_file specified in $SRC. Use nft_file or manual mode. -h for help." 1>&2
          exit 1
        fi
        # determine the plot size
        plot_size=`du -k $plot 2>/dev/null|cut -f1`
        # ----------------------------------------
        # Look to see if the destination drive currently has any other plots actively being copied to it. If so, skip that drive.
        #drive_cnt=0
        #for drive in $DST/*; do drive_cnt=$(($drive_cnt+1)); done
        #loop_cnt=0
        #drive_in_use=0
        for drive in $DST/* ; do
          #loop_cnt=$(($loop_cnt+1))
          #if [ $loop_cnt -gt $drive_cnt ] && ! $manual; then break; fi
          if [ $(mount|grep "$drive "|wc -l) -eq 0 ] && ! $force; then continue; fi # skip location if not mounted and not forced.
          if $manual || $one_drive; then drive=$DST; fi
          if [ $(ls -la $drive/.plot-* 2>/dev/null|wc -l) -ge 1 ]; then
            #drive_in_use=$(($drive_in_use+1))
            checkDT=`date "+%Y%m%d"`
            checkTM=`date "+%-H%M"`
            if [[ ${checkTM:0:1} == "0" ]]; then checkTM=${checkTM:1}; fi # Handles 00 hour
            if [[ ${checkTM:0:1} == "0" ]]; then checkTM=${checkTM:1}; fi # Handles <10 minutes in 00 hour
            for hidden_rsync in $drive/.plot-*; do # Remove any old rsync sessions
              sleep 1
              rsyncDT=`date -r $hidden_rsync "+%Y%m%d" 2>/dev/null`
              rsyncTM=`date -r $hidden_rsync "+%-H%M" 2>/dev/null`
              if [[ ${rsyncTM:0:1} == "0" ]]; then rsyncTM=${rsyncTM:1}; fi # Handles 00 hour
              if [[ ${rsyncTM:0:1} == "0" ]]; then rsyncTM=${rsyncTM:1}; fi # Handles <10 minutes in 00 hour
              if [[ ! -z rsyncDT ]] && [ $((rsyncDT)) -lt $((checkDT)) ]; then
                rm_hidden_rsync=true
              #elif [[ ! -z rsyncTM ]] && [ $((${rsyncTM##+(0)})) -lt $((${checkTM##+(0)})) ]; then
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
                  if $waited; then waited=false; echo; fi
                  printf "\r${tput_lo} $NFT -> $drive${tput_hi}$overlap_num${tput_off}"
                  finLOC=$drive
                  # Move the plot
                  used=`du $SRC|awk '{print $1}'|tail -1`
                  size=`ls $SRC/drive-size-* 2>/dev/null|awk -F "drive-size-" '{print $2}'`
                  full=`printf "%.0f" $(awk "BEGIN {print $used/$size*100}")`
                  DT=`date +"%m-%d"`; TM=`date +"%T"`
                  num_plots=`ls $SRC/*.plot 2>/dev/null|wc -l`
                  if [ $((num_plots)) -eq 1 ]; then mult=""; else mult="s"; fi
                  # Verify file not already being moved and not exceeding max mvoes to destination.
                  n=$(($RANDOM % 50 )) # randomize the sleep timer 0-5 seconds
                  sleep_time=`printf '%s.%s\n' $(( n / 10 )) $(( n % 10 ))`
                  sleep ${sleep_time} # sleep timers to help prevent duplicate plot moves
                  num_xfers=$(ls -la $drive/.plot-* 2>/dev/null|wc -l)
                  if ! $manual && [ $num_xfers -gt $overlap_check ]; then
                    second_look=false
                    continue
                  fi
                  if $second_look; then overlap_report="${tput_hi}:$(($num_xfers+1))${tput_lo}"; else overlap_report=""; fi
                  if [ $(ps aux|grep $plot_name|grep -v -e --color|wc -l) -gt 1 ]; then break; fi
                  printf "${tput_lo}\n$DT $TM ${tput_hi}$full"%%" - $num_plots plot$mult${tput_off}\n"
                  # move the plot from SRC to farm
                  ls $plot 2>/dev/null| xargs -P1 -I% rsync -vhW --chown=$USER:$USER --chmod=0744 --progress --remove-source-files % $finLOC/
                  finLOC=""
                  waited=true
                  transferred=true
                  break # exit the loop after successfully moving a plot
                fi
              fi
            fi
          fi
        done
        if [[ -z $finLOC ]]; then # If empty drive space not found
          if $transferred; then
            reset_var=true
          #elif [ $drives_busy -gt 0 ] && $overlap && ! $second_look; then
          elif $overlap && ! $second_look; then
            second_look=true # Look again with overlap, if used
            look_reset=false
          else
            reset_var=true
            printf "No drive space found. Waiting 60 seconds to recheck.\n"
            sleep 60
          fi
        fi
      fi
    else
      for i in 1 to 10; do
        cnt=$(($cnt + 1))
        sp="-\|/"
        DT=`date +"%m-%d"`; TM=`date +"%T"`
        printf "\r$DT $TM  \b${sp:cnt%${#sp}:1} on plots $SRC"
        sleep 0.5
      done
    fi
  done <<<$(ls $SRC/*.plot 2>/dev/null)
  #err=$?; [[ $err != 0 ]] && echo; echo "ERROR: $error_str:$err" && exit $err
  if $transferred; then reset_var=true; fi
  for i in 1 to 10; do
    cnt=$(($cnt + 1))
    sp="-\|/"
    DT=`date +"%m-%d"`; TM=`date +"%T"`
    printf "\r$DT $TM  \b${sp:cnt%${#sp}:1}  waiting $SRC"
    sleep 0.5
    waited=true
  done
done
