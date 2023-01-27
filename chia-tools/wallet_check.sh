#! /bin/bash
# Copyright 2023 by Valerian
#
# This script will get current chia price and wallet for current value

print_header(){
  clear
  color=header; set_color
  DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
  initdate="$TM - "
  host=`hostname`
  printf "${tput_color}$host  -  $DT $TM\n"
}

set_color(){
  # header=green/normal
  if [ $color = header ]; then tput_color=`(tput sgr0)`; fi
  # normal=cyan
  if [ $color = normal ]; then tput_color=`(tput setaf 6)`; fi
  # syncing=yellow
  if [ $color = sync ]; then tput_color=`(tput setaf 3)`; fi
  # outdated=magenta
  if [ $color = outdated ]; then tput_color=`(tput setaf 5)`; fi
}

initial=true
while true; do
  syncing=`echo|chia wallet show|grep -i Syncing|wc -l`
  print_header
  if [ $((syncing)) -ge 1 ]; then
    color=sync; set_color
    olddata="${tput_color}Wallet is syncing. Standby. *Using previous data.\n"
    oldwval="*"
    oldvval="*"
  else
    xch=$(curl https://www.coingecko.com/en/coins/chia -s | grep -i "Current price of Chia" | awk -F '\\$' '{print $2}' | awk '{print $1}' | sed -n 1p)
    wallet=$(echo | chia wallet show | grep Total | sed -n "1p" | head -c 44 | awk '{print $3}')
    if [ -z $xch ]; then
      xch=$oldxch
      oldxval="*"
      color=outdated; set_color
    else
      oldxch=$xch
      oldxval=""
      color=normal; set_color
    fi 
    if [ -z $wallet ]; then
      wallet=$oldwallet
      oldwval="*"
      color=outdated; set_color
    else
      oldwallet=$wallet
      oldwval=""
      color=normal; set_color
    fi
    if [ -z "$oldwval" ] && [ -z "$oldxval" ]; then
      olddata="\n"
      olddate=""
      dDT=`date +"%y-%m-%d"`; dTM=`date +"%T"`
      initial=false
    else
      color=outdated; set_color
      olddata="${tput_color}* problem updating, using previous data\n"
      if $initialized; then 
        olddate=$initdate
      else
        olddate="$dTM - "
        initial=false
      fi
    fi
    if [ ! -z $xch ] && [ ! -z $wallet ]; then
      total=`echo "$xch * $wallet" | bc | xargs printf "%.2f"`
      value=`printf "$%'.2f\n" $total`
    fi
  fi
  printf "$olddata\n"
  printf "${tput_color}${olddate}XCH=$oldxval\$$xch  Wallet=$oldwval$wallet\n"
  printf "\n${tput_color} Current Value = $value$oldvalues\n\n"
  sleep 55
done
