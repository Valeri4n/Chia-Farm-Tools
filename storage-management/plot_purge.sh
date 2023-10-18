#!/bin/bash
#
# Copyright 2023 by Valerian

# Why delete a whole drive at a time and lose farming reward as you wait to replot?
# Instead, delete old plots only as space is needed.
#
# This script will delete old plots as space is needed to make room for the new
#   compressed plots while maximizing farming rewards as you replot. The script
#   will loop completely through all drives and then refresh. It will do this
#   for both random and in order.
#
# Must specify destination path with -p [path]
# Random drive selection is used to help reduce bottlenecks for certain architectures.
# Default time between checks is 5 minutes. Extend longer to be above plot move time if
#   needed. Color is normally blue but changes to red if no new plots are found between
#   cycles. This helps identify if plotter might have a problem that should be checked.
# Adjust max and min drives with open space to maximize plots at any given time
#   and ensure space is available to plotter cache drive always has space for plots.
#   For example, if 2 plots mover scripts are running, maintain num_min=2 drives.
#   Depending on speed of transfer, use num_max=3 (1 more than min). If running 5 plot
#   mover scripts, use num_min=5 and num_max=7. Adjust as needed to maintain free space
#   on cache drive and maximize farming.
# This prints the first 2 characters of the system name. This is helpful if monitoring
#   this script running on multiple systems. A single tmux sessions can be used to 
#   monitor them all. If using a numbering system in the first 2 characters, they can
#   easily be differentiated. I use 2 digit IP address numbers in the name. A farmer
#   with IP address 10.10.10.45 could be named 45-farmer. 45 would show up in the 
#   script output to keep track of each system. Adjust the script as needed.
# Change values in config as needed

config(){
  # enter matching strings for all old plots to delete and new plots to replace old
  old_plots="plot-k32-20*"
  new_plots="plot-k32-c07*"
  # enter size of plots 
  old_size=108840000  # chia c0 k32 plot size
  new_size=83800000   # chia c7 k32 plot size
  # get hostname
  host_chars=2        # use first # characters in hostname output
  host=`hostname`
  # plot defaults, change with flags
  num_each=1          # number of plots to delete from each drive
  num_max=5           # max number of drives to delete a plot from
  num_min=3           # minimum number of drives with open space
  random=true
  check_time=5
}

test_config(){
  if [[ -z $path ]]; then
    echo "Must specify path with plot_purge.sh -p <path> -n <nft marker>"
    exit 0
  elif [[ -z $nft ]]; then
    echo "Must specify nft marker with plot_purge.sh -p <path> -n <nft marker>"
    exit 0
  fi
  if [ ${num_each} -gt 1 ]; then plural="s"; else plural=""; fi
}

flags() {
  while true; do
    case "$1" in
      -e|--each) # number of plots to delete from each drive on each pass
        num_each=$2
        shift 2;;
      -h|--help)
        help; exit 1
        shift 1;;
      -m|--min) # minimum number of open drives
        num_min=$2
        shift 2;;
      -n|--nft) # plot nft drive marker to look for
        nft=$2
        shift 2;;
      -o|--order) # shift from random drives to in order of mount
        random=false
        shift 1;;
      -p|--path)
        path=$2
        last_char=`echo $path|tail -c 3`
        if [ ${last_char} == "[]" ]; then
          path=`echo $path|rev|cut -c 3-|rev`
        else
          path=$path/
        fi
        shift 2;;
      -t|--time) # time between checks in minutes
        check_time=$2
        shift 2;;
      -x|--max) # max number of open drives
        num_max=$2
        shift 2;;
      --)
        break;;
      *)
        break;;
    esac
  done
}

help(){
  echo "There is no help for you"
}

get_open_drives(){
  if $reload; then drive_set=""; fi
  num_space=0
  old_count=0
  new_count=0
  space=""
  for drive in `mount|grep $path|awk '{print $3}'`; do
    if [[ ${drive} == "${path}"* ]]; then
      avail=`df $drive 2>/dev/null|sed -n 2p|awk '{print $4}'`
      nft_count=`ls $drive/nft-$nft 2>/dev/null| wc -l`
      if [[ ${nft_count} -ge 1 ]]; then nft_true=true; else nft_true=false; fi
      if $nft_true; then 
        old_count=$(($old_count + `ls $drive/$old_plots 2>/dev/null|wc -l`))
        new_count=$(($new_count + `ls $drive/$new_plots 2>/dev/null|wc -l`))
        if [[ ${avail} -gt 83800000 ]]; then
          num_space=$(($num_space + 1))
        fi
        if $reload && [[ `ls $drive/$old_plots 2>/dev/null|wc -l` -ge 1 ]]; then
          drive_set="$drive_set$space$drive"
          space=" "
          drive_cnt=$((${drive_cnt} + 1))
        fi
      fi
    fi
  done
  reload=false
}

remove_plots(){
  drive=`echo $drive_set|awk -v x=$mount_num '{print $x}'`
  avail=`df $drive  2>/dev/null|sed -n 2p|awk '{print $4}'`
  if [[ ${drive} == "${path}"* ]] && [[ `ls $drive/nft-$nft 2>/dev/null| wc -l` -ge 1 ]] && [[ ${avail} -lt $new_size ]]; then
    for ((s=1; s<=${num_each}; s++)); do 
      plot=`ls $drive/$old_plots 2>/dev/null|sed -n 1p`
      if [[ ! -z $plot ]]; then
        echo "removing: ${plot:0:40}..."
        rm $plot
        num_space=$(($num_space + 1))
      fi
    done
  fi
}

get_color(){
  if [[ ${new_cnt} -eq ${new_count} ]]; then
    set_color=5
  else
    set_color=6
  fi
  new_cnt=$new_count
}

cycle_drives(){
  while true; do
    get_open_drives
    if [[ ${num_space} -lt ${num_min} ]] || $del_plots; then
      del_plots=true
      if [[ ${num_space} -lt ${num_max} ]]; then
        remove_plots
        break
      else
        del_plots=false
      fi
    fi
    conversion="$(echo "scale=4;($new_count*$new_size)/($old_count*$old_size+$new_count*$new_size)*100"|bc -l|awk '{printf "%.2f", $0}')%%"
    old_count_str=$(printf "%'d" "$old_count")
    new_count_str=$(printf "%'d" "$new_count")
    DT=`date +"%m-%d"`; TM=`date +"%T"`
    get_color
    if [[ ${num_space} -eq 1 ]]; then plural=""; else plural=s; fi
    printf "$(tput setaf ${set_color})${host:0:${host_chars}} $DT ${TM:0:5}-$nft $new_count_str new  $old_count_str old  $conversion  $num_space drive${plural} open$(tput sgr0)\n"
    sleep ${wait_time}
  done
}

config
flags "${@}"
wait_time=$(($check_time * 60))
test_config

while true; do
  printf "\nPath=$path nft-$nft min=$num_min max=$num_max\n deleting $num_each old plot$plural per drive on each pass\n"
  printf "\n$(tput setaf 3)  refreshing drives : checking space every $check_time minutes$(tput sgr0)\n"
  reload=true
  get_open_drives
  if $random; then
    for mount_num in `shuf -i 1-${drive_cnt}`; do
      cycle_drives
    done
  else
    for ((mount_num=1; mount_num<=${drive_cnt}; mount_num++)); do
      cycle_drives
    done
  fi
done
