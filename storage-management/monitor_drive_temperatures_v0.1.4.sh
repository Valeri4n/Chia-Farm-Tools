#!/bin/sudo bash
# Written by Valerian - Copyright 2022
# This script looks at all mounted drives in one mount location and counts plots
# If mount location is other than mnt or home, add location as  -  ./script.sh mnt
#
# Updates hi and lo drive list every 10+ minutes as dev/sd[]:[mount point]
# If drive partition has a label, output will be [label]:[mount point]
# 
# chmod +x [script.sh]  -  will make script executable
# ./[script.sh]  -  will run script
echo
SMART=`which smartctl | wc -l`
DTEMP=`which hddtemp | wc -l`
ONCE=0
FIRST_PUB=0
degrees=$'\xc2\xb0'C
HIB=``
HIF=``
LOB=``
LOF=``
bold=`(tput bold)`
reset=`(tput sgr0)`
if [ ! -z $1 ]; then
  mount_point=$1
fi
while true; do
  HITEMP=
  LOTEMP=
  HICNT=0
  LOCNT=0
  tempsum=0
  DRIVE_COUNT=0
  num_plots=0
  INVALIDS=""
  drv=($(mount | grep /dev/sd | awk '{print $1}'))
  path=($(mount | grep /dev/sd | awk '{print $3}'))
  arr_len=${#drv[@]}
  imax=$(($arr_len - 1))
  for (( i=0; i<=$imax; i++ )); do
    mnt_prefix=`cut -d/ -f2 <<< ${path[$i]}`
    if [ ! -z $mnt_prefix ] && (([ -z $mount_point ] && ([ "$mnt_prefix" = mnt ] || [ "$mnt_prefix" = home ])) || [ "$mnt_prefix" = "$mount_point" ]); then
      mnt=`awk -F '/' '{print $NF}' <<< ${path[$i]}`
      hdd_plot_num=0
      hdd_plot_num=`ls ${path[$i]}/*.plot 2>/dev/null | wc -l`
      if [ $((hdd_plot_num)) -ge 1 ]; then
        num_plots=$(($num_plots + $hdd_plot_num))
      fi
      DRIVE_COUNT=$(($DRIVE_COUNT + 1))
      if [ $((SMART)) -eq 1 ]; then
        temp=`smartctl -A ${drv[$i]} 2>/dev/null | grep "Current Drive Temperature:" | awk '{print $4}'`
        if [ -z $temp ]; then
          temp=`smartctl -A ${drv[$i]} 2>/dev/null | grep "Temperature_Celsius" | awk '{print $10}' | sed 's/^0//'`
        fi
      fi
      if [ $((DTEMP)) -eq 1 ] && [ -z $temp ]; then
        TEMP=`hddtemp ${drv[$i]} 2>/dev/null | awk '{print $4}'`
        if [ ! -z $TEMP ]; then
          temp=${TEMP::-2}
        else
          temp=-1
#          printf "\ni=$i :: Drive=${drv[$i]} :: Path=${path[$i]} :: Mount=$mnt"
          INVALIDS="${INVALIDS} ${drv[$i]}:$mnt"
#          printf "\nIssue with drives: $INVALIDS\n"
        fi
      fi
      if [ -z $temp ]; then
        echo "No HDD temperature tools found for $i. Install smartmontools or hddtemp and run again."
        exit 1
      fi
      if [ $((temp)) -gt 0 ] && ([ $((temp)) -ge $((HITEMP)) ] || [ -z $HITEMP ]); then
        part_label=`lsblk -o label ${drv[$i]} | sed -n '2p'`
        if [ -z $part_label ]; then
          drMNT=" ${drv[$i]//[[:digit:]]/}:$mnt"
        else
          drMNT=" $part_label:$mnt"
        fi
        if [ $((temp)) -gt $((HITEMP)) ]; then
          HITEMP=$temp
          HITEMP_DRIVES=""
          HICNT=0
        fi
        HICNT=$(($HICNT + 1))
        HICNTS=$HICNT
        HITEMP_DRIVES="${HITEMP_DRIVES} $drMNT"
        if [ -z $LOTEMP ]; then LOTEMP=$temp; fi
      elif [ $((temp)) -gt 0 ] && ([ $((temp)) -le $((LOTEMP)) ] || [ -z $LOTEMP ]); then
        part_label=`lsblk -o label ${drv[$i]} | sed -n '2p'`
        if [ -z $part_label ]; then
          drMNT=" ${drv[$i]//[[:digit:]]/}:$mnt"
        else
          drMNT=" $part_label:$mnt"
        fi
        if [ $((temp)) -lt $((LOTEMP)) ]; then
          LOTEMP=$temp
          LOTEMP_DRIVES=""
          LOCNT=0
        fi
        LOCNT=$(($LOCNT + 1))
        LOCNTS=$LOCNT
        LOTEMP_DRIVES="${LOTEMP_DRIVES} $drMNT"
      fi
      tempsum=$(($tempsum + $temp))
      cnt=$((cnt + 1 ))
      sp="-\|/"
      tp="-/|\\"
  #  if [ $((ONCE)) -eq 0 ] || [ $((DRIVE_COUNT)) -eq 1 ]; then
      if [ $((HITEMP)) -ge 50 ]; then
        hitemp_color=1 # red
        hib=`(tput setab 1)`
        hif=`(tput setaf 0)`
        hibo=$bold
      elif [ $((HITEMP)) -ge 42 ]; then
        hitemp_color=3 # yellow
        hib=``
        hif=`(tput setaf 5)`
        hibo=``
      elif [ $((HITEMP)) -ge 30 ]; then
        hitemp_color=2 # green
        hib=``
        hif=`(tput setaf 5)`
        hibo=``
      else
        hitemp_color=4 # blue
        hib=`(tput setab 4)`
        hif=`(tput setaf 0)`
        hibo=$bold
      fi
      if [ $((LOTEMP)) -le 15 ]; then
        lotemp_color=1 # red
        lob=`(tput setab 1)`
        lof=`(tput setaf 0)`
        lobo=$bold
      elif [ $((LOTEMP)) -le 25 ]; then
        lotemp_color=4 # blue
        lob=`(tput setab 4)`
        lof=`(tput setaf 0)`
        lobo=$bold
      elif [ $((LOTEMP)) -le 40 ]; then
        lotemp_color=2 # green
        lob=``
        lof=`(tput setaf 6)`
        lobo=``
      else
        lotemp_color=2 # yellow
        lob=``
        lof=`(tput setaf 6)`
        lobo=``
      fi
      if [ $((ONCE)) -eq 0 ]; then
        printf "\r High $(tput setaf $hitemp_color)$HITEMP$degrees$(tput setaf 7)  \b${sp:cnt%${#sp}:1} "
        printf "Low $(tput setaf $lotemp_color)$LOTEMP$degrees$(tput setaf 7)  \b${tp:cnt%${#tp}:1} $DRIVE_COUNT drives scanned."
      fi
      if [ $((ONCE)) -eq 1 ] || [ $((i)) -eq $((imax)) ]; then
        if [ $((i)) -eq $((imax)) ]; then 
          sp="-"
          for s in /svrmnt/*/; do
            for t in $s*/; do
              svr_plot_num=`ls $t*.plot 2>/dev/null | wc -l`
              num_plots=$(($num_plots + $svr_plot_num))
            done
          done
          if [ $((num_plots)) -gt 1000000 ]; then
            hiplots=${num_plots::-6}
            midplots=${num_plots: -6: -3}
            loplots=${num_plots: -3}
            numps=$hiplots,$midplots,$loplots
          elif [ $((num_plots)) -gt 1000 ]; then
            hiplots=${num_plots::-3}
            loplots=${num_plots: -3}
            numps=$hiplots,$loplots
          fi
          NUM=$DRIVE_COUNT
          HIC=$HICNT
          HIT=$HITEMP
          if [ $((HIC)) -gt 1 ]; then HID="s"; hi=""; else HID=""; hi=" "; fi
          hicolor=$hitemp_color
          LOC=$LOCNT
          LOT=$LOTEMP
          if [ $((LOC)) -gt 1 ]; then LOD="s"; lo=""; else LOD=""; lo=" "; fi
          locolor=$lotemp_color
          if [ $((hitemp_color)) -eq 1 ] || [ $((lotemp_color)) -eq 1 ]; then
            text_color=3 # yellow
          else
            text_color=2 # green
          fi
          AVG=`bc <<< "scale=1 ; $tempsum / $DRIVE_COUNT"`
          if (( $(echo "$AVG > 40" | bc -l) )) || (( $(echo "$AVG < 30" | bc -l) )); then
            avgcolor=1 # red
          else
            avgcolor=2 # green
          fi
        fi
        if [ $((FIRST_PUB)) -eq 0 ] || [ $((i)) -eq $((imax)) ]; then HIT=$HITEMP; HIC=$HICNTS; LOT=$LOTEMP; LOC=$LOCNTS; fi
        DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
        printf "\r$(tput setaf 7)$DT $TM - $numps plots on $NUM HDDs  \b${sp:cnt%${#sp}:1} $(tput setaf $text_color)Avg $(tput setaf $avgcolor)$AVG$degrees$(tput setaf $text_color), "
        printf "High $(tput setaf $hicolor)$HIT$degrees$(tput setaf $text_color) on $HIC drive$HID, "
        printf "Low $(tput setaf $locolor)$LOT$degrees$(tput setaf $text_color) on $LOC drive$LOD.$hi$lo"
        if ([ $((i)) -eq $((imax)) ] && [ $((SECONDS)) -ge 600 ]) || [ $((FIRST_PUB)) -eq 0 ]; then
          FIRST_PUB=1
          if [ ! -z $INVALIDS ]; then
            printf "\n$(tput setaf 7) Possible invalid mount on $INVALIDS."
          fi
          printf "\n${hibo}${hib}${hif}:: hi $HIT$degrees ::${reset}$(tput setaf 2)$HITEMP_DRIVES"
          printf "\n${lobo}${lob}${lof}:: lo $LOT$degrees ::${reset}$(tput setaf 2)$LOTEMP_DRIVES\n\n"
          SECONDS=0
        fi
      fi
    fi
  done
  ONCE=1
  if [ $((SECONDS)) -lt 60 ]; then
    sleep 60
  fi
# Colors
# 0 black
# 1 red
# 2 green
# 3 yellow
# 4 blue
# 5 cyan
# 6 blue
# 7 white
done
