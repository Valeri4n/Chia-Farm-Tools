#!/bin/bash
#
# Copywrite 2025 by Valerian

dev=$1
sleep 5
PID=$(ps aux|grep "fsck -CTn ${dev}"|grep -v -e grep|sed -n 1p|awk '{print $2}')
psaux=$(ps aux|grep "fsck -CTn ${dev}"|grep -v -e grep)
if [[ ! -z $PID ]]; then
  kill -9 ${PID}
fi
