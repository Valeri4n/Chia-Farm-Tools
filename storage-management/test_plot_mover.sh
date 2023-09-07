#!/bin/bash
# Copyright 2023 by Valerian

# Run as many instances of this script in parallel as needed to move plots from cache.

# - This is a test, use at your own risk
# - Added capability to replace plots with compressed plots
# - Improved status reporting
# - Fixed removal of old rsync files

version() {
  printf "\n plot_mover.sh v2.0*test by Valerian\n\n"
}

help() {
  echo 
  echo "The purpose of this script is to move plots from a source location to destination. The plots"
  echo "may be moved locally within the same system or across mounted shared drives across a network."
  echo "Run this script on the destination system so that it may determine the remaining space available"
  echo "on the destination drive before sending a plot to it."
  echo
  echo "This script has only been tested with plots made by chia's bladebit plotter. It may not work"
  echo "with different naming formats used by other plotters. If there is an issue, feel free to constact"
  echo "me and I can update it it to handle the other case."
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
  echo "  -r, --replot   Specify compression type plots to replace, -r c0. Options c0-c09."
  echo "                   Available space will be filled first. After, plots of type will be randomly deleted and"
  echo "                   and replaced with new plots. Can specify a single drive with -m and -r."
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
      -r|--replot)
        replot=true
        plot_type=$2
        replot_maxcnt=24
        comp_str=" compressed"
        if [[ -z $2 ]] || ( ! [ ${2:0:1} = c ] && ! [ ${2:0:1} = C ] ) || ! [[ ${2:1:2} =~ ^[0-9]+$ ]] || [ ${#2} -ne 2 ]; then
          echo "Replot -r must be used with c0-c09. c0 is also used for legacy plots without c0 specified."
          exit 1
        else
          echo "${tput_hi}Replacing $plot_type plots${tput_off}"
        fi
        shift 2;;
      -v|--version)
        exit 1
        shift 1;;
      -t|--test)
        test=true
        shift 1;;
      --)
        break;;
      *)
        break;;
    esac
  done
}

waiting() {
  if [[ ${waitcnt} -eq 0 ]]; then
  if $plot_found; then
    wait_str="checking drives "
    waitcnt=0
  elif $no_drive_space; then
    wait_str="No drive space    " # found. Waiting 60 seconds to recheck. "
    waitcnt=$wnct
  elif $no_plots; then
    wait_str="waiting on$comp_str plots.... "
    waitcnt=$wcnt
  elif $look_for_plots; then
    wait_str="checking source "
    waitcnt=0
  fi
  fi
  max_str=16
  cnt=$(($cnt + 1))
  if [ $((wcnt+1)) -gt $((${#wait_str})) ]; then
    wcnt=0
    waitcnt=$wcnt
  fi
  wstart1=$waitcnt
  if [ $(($waitcnt+$max_str)) -gt $((${#wait_str})) ]; then
    wend1=${#wait_str}
    wstart2=0
    if [[ -z ${waitcnt} ]]; then waitcnt=0; fi
    wend2=$((${max_str} - ${#wait_str} + ${waitcnt}))
  else
    wend1=$max_str
    wend2=0
  fi
  wait_str0=${wait_str:${wstart1}:${wend1}}${wait_str:${wstart2}:${wend2}}
  sp="-\|/"
  TM=`date +"%T"`
  wait_string="$TM  ${sp:cnt%${#sp}:1} $wait_str0: $SRC"
  wait_len=${#wait_string}
  if [ $((move_len)) -gt $((wait_len)) ]; then
    len_diff=$(($move_len-$wait_len))
    for ((s=1; s<=$len_diff; s++)) do
      len_space="$len_space "
    done
  fi
  printf "\r$TM  \b${sp:cnt%${#sp}:1} $wait_str0: $SRC$len_space$this"
  checked=true
  len_space=""
  wcnt=$(($wcnt+1))
  if $slp; then sleep 0.5; fi
}

set_variables() {
  overlap=true
  num_overlap=2
  manual=false
  force=false
  waited=false
  replot=false
  comp_str=""
  test=false
  plot_found=false
  slp=true
  overlap_str="overlap:2"
  tput_hi=`(tput setaf 3)`
  tput_lo=`(tput setaf 6)`
  tput_off=`(tput sgr0)`
}

clear_old_rsync() {
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
    elif [[ ! -z rsyncTM ]] && [ $((rsyncTM)) -lt $((checkTM)) ]; then
      rm_hidden_rsync=true
    else
      rm_hidden_rsync=false
    fi
    if $rm_hidden_rsync && [ $(ps aux|grep $hidden_rsync|grep -v -e --color -e grep -e watch|wc -l) -lt 1 ]; then
      rm $hidden_rsync 2>/dev/null
    fi
  done
}

random_sleep() {
  n=$(($RANDOM % 40)) # randomize the sleep timer 0-5 seconds
  sleep_time=`printf '%s.%s\n' $((n / 10)) $((n % 10))`
  sleep ${sleep_time} # sleep timers to help prevent duplicate plot moves
}

check_dup() {
  ps aux|grep $plot_name|grep -v -e --color|wc -l
}

check_space() {
  skip_drive=true
  while true; do
    AVAIL=$(df $drive --output=avail|awk -F "[[:space:]]+" '{print $1}'|tail -n 1)
    if [ $((AVAIL)) -gt $((size_needed)) ]; then
      skip_drive=false
      break
    elif $replot; then # make_space
      p=0
      while true; do
        p=$(($p+1))
        if [[ $plot_type == "c0" ]]; then
          plot_search="plot-k32-20"
        elif [[ ! -z ${plot_type} ]]; then
          plot_search="plot-k32-$plot_type-20"
        fi
        deplot_name=`find $drive/$plot_search* -printf "%f\n"|sed -n ${p}p`
        if [[ -z $deplot_name ]]; then
          break
        elif [[ ${deplot_name:9:11} = $plot_type ]] || ([[ ! ${deplot_name:9:11} =~ c^[0-9]+$ ]] && [ $plot_type == "c0" ]); then
          if $checked; then checked=false; echo; fi
          echo "$(tput setaf 3)Removing: $(tput sgr0)$drive/$deplot_name"
          rm $drive/$deplot_name
          break
        fi
      done
    else
      break
    fi
  done
}

get_new_plot_count(){
  len_space=""
  finLOC=$drive
  used=`du $SRC|awk '{print $1}'|tail -1`
  size=`ls $SRC/drive-size-* 2>/dev/null|awk -F "drive-size-" '{print $2}'`
  full=`printf "%.0f" $(awk "BEGIN {print $used/$size*100}")`
  DT=`date +"%m-%d"`; TM=`date +"%T"`
  num_plots=`ls $SRC/*.plot 2>/dev/null|wc -l`
  if [ $((num_plots)) -eq 1 ]; then mult=""; else mult="s"; fi
  if [ ! -z $plot_name ]; then
    random_sleep; if [ $(ps aux|grep $plot_name|grep -v -e --color|wc -l) -gt 1 ]; then return 1; fi
  fi
  num_xfers=$(ls -la $drive/.plot-* 2>/dev/null|wc -l)
  if ! $manual && [[ $num_xfers -gt $overlap_check ]]; then second_look=false; continue; fi
  if $second_look; then overlap_report="${tput_hi}:$(($num_xfers+1))${tput_lo}"; else overlap_report=""; fi
  if [ ! -z $plot_name ]; then
    random_sleep; if [ $(ps aux|grep $plot_name|grep -v -e --color|wc -l) -gt 1 ]; then return 1; fi
    random_sleep; if [ $(ps aux|grep $plot_name|grep -v -e --color|wc -l) -gt 1 ]; then return 1; fi
  fi
  # move the plot from SRC to DST drive
  printf "${tput_lo}\n$DT $TM ${tput_hi}$full"%%" - $num_plots plot$mult in cache drive${tput_off}\n"
}

testing() {
  echo "testing"
#   echo $plot_name
#   echo ${#plot_name}
#   echo ${plot_name:9:11}
#   echo $replace
#   echo $plot_type
#   exit 1
}

#k32 C0=108836000
#k33 C0=230000000
#k34 C0=462000000
#set -e
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
#set -x
printf "SRC=$SRC  DST=$DST  $overlap_str\n\n"
get_new_plot_count
#if $replace; then exit 1; fi
while true; do
  if $no_plots; then
    no_plots=false
    look_for_plots=false
  else
    look_for_plots=true
    waiting
  fi
  # Look for drives not in use first, even if allowing overlapping drive writes.
  if $look_reset; then look_reset=false; second_look=false; transferred=false; fi
  while read plot 2>/dev/null; do
    no_drive_space=false
    # ----------------------------------------
    # Look to see if plots exist in SRC drive. Don't proceed until they do.
    if [[ -f $plot ]]; then
      plot_name=`echo ${plot##*/}`
      source_size=`echo $plot_name|awk -F- '{print $3}'`
      # if $replot; then
      #   if [ ${plot_name:9:11} = $plot_type ]; then
      #   elif [[ ${plot_type:1:2} = "0" ]] && ([ ! ${plot_name:9:10} = "c" ] || [ ${plot_name:9:11} = "c0" ]); then
      #     delete_plot=true          
      #   fi
      # if $replot && (([ $plot_type = "c0" ] && [[ ! ${source_size} =~ c^[0-9]{1,2}$ ]]) || [ ${source_size} = "$plot_type" ] || [ ${source_size} = "$plot_type-" ] ); then
      if $replot && ( [ ${source_size} = ${plot_type} ] || [ ${source_size} = "$plot_type-" ] ); then
        echo "Source plots are same as type being replaced. Exiting."
        exit 1
      elif $replot; then
        rand_replot=$(($RANDOM % $replot_maxcnt))
      fi
if $test; then echo $plot_name; echo $(check_dup); continue; fi
if $test; then testing; continue; fi
      if [ $(ps aux|grep $plot_name|grep -v -e --color -e "grep"|wc -l) -eq 0 ]; then
        random_sleep
        if [ $(ps aux|grep $plot_name|grep -v -e --color -e "grep"|wc -l) -eq 0 ]; then
if $test; then echo $plot_name; fi
          if ! $manual; then NFT=$(basename $(find $SRC -type f -name nft_* 2>/dev/null)|sed 's/_/-/g'); fi
          if ! $manual && [[ -z $NFT ]]; then
            echo "No nft_file specified in $SRC. Use nft_file or manual mode. -h for help." 1>&2
            exit 1
          fi
          plot_size=`du -k $plot 2>/dev/null|cut -f1` # determine the plot size
          # ----------------------------------------
          # Look to see if the destination drive currently has any other plots actively being copied to it. If so, skip that drive.
          for drive in $DST/* ; do
            drive_cnt=$(($drive_cnt+1))
            if [ $((drive_cnt)) -gt 40 ]; then drive_cnt=0; plot_found=true; slp=false; waiting; slp=true; plot_found=false; fi
            if [ $(mount|grep "$drive "|wc -l) -eq 0 ] && ! $force; then continue; fi # skip location if not mounted and not forced.
            if $manual || $one_drive; then drive=$DST; fi
            if [ $(ls -la $drive/.plot-* 2>/dev/null|wc -l) -ge 1 ]; then clear_old_rsync; fi
            if $second_look; then overlap_check=$num_overlap; else overlap_check=0; fi
            if $manual || [ "$(ls -la $drive/.plot-* 2>/dev/null|wc -l)" -le $overlap_check ]; then
              number_of_moves=$(ls -la $drive/.plot-* 2>/dev/null|wc -l)
              size_needed=$(($(($number_of_moves+1))*$plot_size))
              if $manual || [ -f $drive/$NFT ]; then
                if $replot; then
                  replot_cnt=$(($replot_cnt+1))
                  if [ $((replot_cnt)) -eq $((rand_replot)) ]; then
                    check_space
                  elif [ $((replot_cnt)) -gt $((replot_maxcnt)) ]; then
                    replot_cnt=0
                  else
                    continue
                  fi
                fi
                check_space
                if $skip_drive; then continue; fi
                #AVAIL=$(df $drive --output=avail|awk -F "[[:space:]]+" '{print $1}'|tail -n 1)
                if [ $((AVAIL)) -gt $((size_needed)) ]; then
                 # if ! $second_look; then 
                  if $manual || [ $(ls -la $drive/.plot-* 2>/dev/null|wc -l) -le $overlap_check ]; then
                    random_sleep; if [ $(ps aux|grep $plot_name|grep -v -e --color|wc -l) -gt 1 ]; then break; fi
                    if $waited; then waited=false; fi
                    move_string=" $NFT -> $drive$overlap_num"
                    move_len=${#move_string}
                    if [ $((wait_len)) -gt $((move_len)) ]; then
                      len_diff=$(($wait_len-$move_len))
                      for ((s=1; s<=$len_diff; s++)) do
                        len_space="$len_space "
                      done
                    fi
                    printf "\r${tput_lo} $SRC/$NFT -> $drive${tput_hi}$overlap_num${tput_off}$len_space"
                    get_new_plot_count || break
                    ls $plot 2>/dev/null| xargs -P1 -I% rsync -hW --chown=$USER:$USER --chmod=0744 --progress --remove-source-files % $finLOC/
                    finLOC=""; transferred=true; echo; break # exit the loop after moving a plot
                  fi
                fi
              fi
            fi
          done
          if [[ -z $finLOC ]]; then # If empty drive space not found
            if $transferred; then
              look_reset=true
            elif $overlap && ! $second_look; then
              second_look=true # Look again with overlap, if used
              look_reset=false
            else
              look_reset=true
              no_drive_space=true
              for i in 1 to 120; do
                waiting
              done
            fi
          fi
        fi
      fi
    else
      for i in 1 to 20; do
        waiting
      done
    fi
  done <<<$(ls $SRC/*.plot 2>/dev/null)
  if $transferred; then
    look_reset=true
    no_plots=false
    look_for_plots=true
    no_drive_space=false
    transferred=false
    for i in 1 to 4; do
      waiting
    done
  else
    no_plots=true
    for i in 1 to 20; do
      waiting
    done
    waited=true
  fi
done
