#!/bin/sudo bash
# Written by Valerian - Copyright 2022
# This script looks at drive temperatures every minute
# for all drive names entered after calling the script
# ./drive_temp_check.sh sda sdrw sddt    , etc.

set_color()
{
  if [ $((temp)) -ge $((hi_alarm)) ]; then
    temp_color=`(tput setaf 1)` # red
  elif [ $((temp)) -gt $((hi_alert)) ]; then
    temp_color=`(tput setaf 3)` # yellow
  elif [ $((temp)) -ge $((lo_alert)) ]; then
    temp_color=`(tput setaf 2)` # green
  elif [ $((temp)) -ge $((lo_alarm)) ]; then
    temp_color=`(tput setaf 6)` # cyan
  else
    temp_color=`(tput setaf 5)` # magenta
  fi
}

get_temp()
{
  temp=`smartctl -a /dev/${drv[$i]//[[:digit:]]/} 2>/dev/null | grep 'Current Drive Temperature:' | awk '{print $4}'`
  if [ -z $temp ]; then
    temp=`smartctl -A /dev/${drv[$i]//[[:digit:]]/} 2>/dev/null | grep 'Temperature_Celsius' | awk '{print $10}' | sed 's/^0//'`
  fi
  if [ -z $temp ]; then
    temp=`hddtemp -n /dev/${drv[$i]//[[:digit:]]/}`
#    TEMP=`hddtemp /dev/${drv[$i]//[[:digit:]]/} 2>/dev/null | awk '{print $4}'`
    if [ -z $TEMP ]; then
#      temp=${TEMP::-2}
#    else
      echo "Unable to get temperature on ${drive[$i]}. Check if hddtemp is installed. Exiting"
      exit 1
    fi
  fi
}

if [ ! "`whoami`" = "root" ]; then
    printf "\nPlease run script as root. Exiting\n\n"
    exit 1
fi

tput setaf 7
normal=`(tput setaf 7)`

hi_alarm=50 # >=
hi_alert=45 # >
lo_alert=30 # <
lo_alarm=25 # <=

if [ $# -eq 0 ]; then echo "$0: Missing arguments"; exit 1; fi
drive=( "$@" )
cnt=10
arr_len=${#drive[@]}
imax=$(($arr_len - 1))

for (( i=0; i<=$imax; i++ )); do
  header="$header ${drive[$i]}"
done
echo
while true; do
  temps=""
  if [ $((cnt)) -eq 10 ]; then
    cnt=0
    echo "                                  $header"
  fi
  for (( i=0; i<=$imax; i++ )); do
    get_temp
    set_color
    temps="$temps   $temp_color$temp$normal"
  done
  today=`date`
  cnt=$(($cnt + 1))
  echo " $today $temps"
  sleep 60
done
