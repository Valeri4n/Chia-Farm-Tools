#!/bin/bash
#
# Copyright 2023 by Valerian
#
# If the chia log entries shows bad plots with
#   Exception fetching qualities for [plot]. badbit or failbit...
# this script will delete them automatically

cnt=0
for plot in $(cat .chia/mainnet/log/debug.log|grep badbit|awk -F"qualities for " '{print $2}'|awk -F". " '{print $1}'); do
  if [[ $(ls $plot 2>/dev/null) > 0 ]]; then
    cnt=$(($cnt + 1))
    echo "Removing $cnt - $plot"
    rm $plot
  fi
done
echo "Deleted $cnt bad plots!"
