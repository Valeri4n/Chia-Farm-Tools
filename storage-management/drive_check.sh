#!/bin/bash
#
# Copyright 2023 by Valerian

# Change type to yours

set_variables(){
  version=0.1

  type=ext4

  SCRIPT=$(readlink -f "$0")
  DIR=$(dirname "$SCRIPT")
  i=0
  clean=0
  skipped=0
  skipped_drives=""
  fixed=0
  fixed_drives=""
  recheck=false
  skip_loop=0
  bad_device=0
  bad_add=""
}

check_drive(){
  dev=/dev/$drive
  if $recheck; then
    rnum=$(($rnum + 1))
    dnum=$rnum
    tnum=$skipped_num
  else
    dnum=$i
    tnum=$num
  fi
  DT=`date +"%m-%d"`; TM=`date +"%T"`
  printf "$(tput setaf 2)$DT $TM checking drive # $dnum of $tnum $drive"
  unmount=$(sudo umount $dev 2>&1)
  if [[ $(echo $unmount|grep "target is busy"|wc -l) -gt 0 ]]; then
    echo "$(tput setaf 3)$(echo $unmount|awk -Fumount: '{print $2}')$(tput setaf 2)"
    skipped=$(($skipped + 1))
    if [ ${skipped} -lt 100 ]; then
      if [ ${skipped} -lt 10 ]; then
        skip_add="  ${skipped} "
      else
        skip_add=" ${skipped} "
      fi
    else
      skip_add="${skipped} "
    fi
    skipped_drives="${skipped_drives}${drive} "
  else
    ${DIR}/kill_proc.sh $dev &
    output=$(sudo fsck -CTn $dev 2>1 &)
    if [[ $(echo $output|grep "clean,"|wc -l) -ge 1 ]]; then
      clean=$(($clean + 1))
      echo "$(tput setaf 6) $(echo $output|awk -F, '{print $1}')$(tput sgr0)"
    elif [[ $(echo $output|grep "No such device"|wc -l) -ge 1 ]]; then
      bad_add=$(($bad_add + 1))
      bad_devices="${bad_devices}   ${bad_add} ${drive}\n"
    else
      echo "$(tput setaf 5) $dev"
      sudo fsck -CTy $dev
      tput sgr0
      #echo "$(tput setaf 3)$output$(tput setaf 2)"
      fixed=$(($fixed + 1))
      if [ ${fixed} -lt 100 ]; then
        if [ ${fixed} -lt 10 ]; then
          fix_add="  ${fixed}"
        else
          fix_add=" ${fixed}"
        fi
      else
        fix_add="${fixed}"
      fi
      fixed_drives="${fixed_drives}   ${fix_add} ${drive}\n"
      echo
    fi
    sudo mount $dev
  fi
}

set_variables
echo
sudo hostname 1>2
printf "\n$(tput setaf 7)drive_check v$version - checking drives and fixing errors:\n\n"
num=$(lsblk -o type,name,size,fstype|grep " sd.*${type}"|wc -l)
for drive in $(lsblk -o type,name,size,fstype|grep " sd.*ext4"|awk '{print $2}'); do
  i=$(($i+1))
  check_drive
done
skipped_num=$skipped
recheck=true
while [[ ${skipped} -gt 0 ]] && [[ ${skip_loop} -lt 20 ]]; do
  skipped=0
  rnum=0
  drives_to_check=$skipped_drives
  skipped_drives=""
  skip_loop=$((skip_loop + 1))
  if [ ${skipped_num} -eq 1 ]; then plural=""; else plural="s"; fi
  printf "\n$(tput setaf 3)  Skipped ${skipped_num} drive${plural} while in use: ${drives_to_check}\n"
  period=""
  for k in {1..30}; do
    period="${period}."
    printf "\r$(tput setaf 3)${skip_loop} - Rechecking skipped drives${period}$(tput sgr0)"
    sleep 1
  done
  echo
  for (( j=1; j<=$skipped_num; j++ )); do
    drive=$(echo $drives_to_check|awk -v var="$j" '{print $var}')
    if [[ ! -z $drive ]]; then
      check_drive
    fi
  done
  skipped_num=$skipped
done

if [ ${fixed} -gt 0 ]; then
  color="$(tput setaf 5)"
else
  color=""
fi
if [[ ${skipped} -eq 0 ]]; then
  skip_str=""
elif [[ ${skipped} -eq 1 ]]; then
  skip_str="\n\n ${skipped_num} drive was skipped while in use:\n   $skipped_drives"
else
  skip_str="\n\n ${skipped_num} drives were skipped while in use:\n   $skipped_drives"
fi
clean_str=""
if [[ ${fixed} -eq 0 ]]; then
  fix_st=""
  fix_str=""
  clean_str="All drives are clean."
else
  fix_st="Drives fixed: ${fixed}."
  fix_str="\n\n Drives fixed:\n${fixed_drives}"
  clean_str="Drives clean: ${clean}."
fi
if [[ ${bad_add} -eq 0 ]]; then
  bad_str=""
else
  bad_str="\n\n Bad drives ${bad_add}:\n${bad_drives}"
fi
printf "\n$(tput setaf 3)**** Drive check completed ****\n$(tput setaf 6) Drives checked: $i. ${clean_str} ${color}${fix_st}$(tput setaf 3) ${skip_str}${fix_str}$(tput setaf 5)${bad_str}$(tput sgr0)\n\n"
