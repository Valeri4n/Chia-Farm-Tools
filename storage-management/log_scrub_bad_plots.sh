#!/bin/bash
#
# Copyright 2023 by Valerian
#
# If the chia log entries shows bad plots with
#   Exception fetching qualities for [plot]. badbit or failbit...
# this script will delete them automatically

remove_bad_plots(){
  for plot in $(cat .chia/mainnet/log/debug.log|grep "${bad_str}"|awk -F"${sep_str1}" '{print $2}'|awk -F"${sep_str2}" '{print $1}'); do
    echo $plot
    if [[ $(ls $plot 2>/dev/null) > 0 ]]; then
      cnt=$(($cnt + 1))
      echo "Removing $cnt - $plot"
      rm $plot
    fi
  done
}

cnt=0
lookup=("badbit or failbit") # "Invalid file ")
separator1=("qualities for ") # "Invalid file ")
separator2=(". ") # " ")
for i in "${!lookup[@]}"; do
  bad_str="${lookup[$i]}"
  sep_str1="${separator1[$i]}"
  sep_str2="${separator2[$i]}"
  remove_bad_plots
done
echo "Deleted $cnt bad plots!"
