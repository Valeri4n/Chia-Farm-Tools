#!/bin/bash
#
# Copyright 2023 by Valerian

# This script displays recent wallet transactions that fit within terminal window and loops every minute
# Blocks within the last 6 hours are magenta, within last 10 minutes shows alert
# All transactions in the last 24 hours are yellow
# Transactions then alternate cyan and white each day after last 24 hours
# Claimed rewards are aggregated into a single line with the number of block rewards claimed in that group
#
# Alert sounds don't play inside tmux window. Use 'ctrl-b : set-option bell-action any' for tmux bar flash

# email requires installing mailutils and ssmtp - maybe ssmtp only? Not currently installed

get_version()
{
  version=0.3
}

variables(){
  min_time=10
  hr_time1=6
  hr_time2=24
  claim_check=false
  wallet_key1=$(echo "q"|chia wallet get_transactions|grep "${wallet})"|awk '{print $2}'|sed -n 1p)
  wallet_key2=$(echo "q"|chia wallet get_transactions|grep "${wallet})"|awk '{print $3}'|sed -n 1p)
  if [[ $wallet_key1 == "*" ]]; then
    wallet_key=$wallet_key2
  else
    wallet_key=$wallet_key1
  fi
  line_sub=5
  max_txns=1000
  # email=
  new_block=false

  # Colors
  header_color=7
  hr6=5
  hr24=3
  alt1=6
  alt2=7
  alert_color=1
  last_blk_color=7
  claim_color=3
  # 0 black
  # 1 red
  # 2 green
  # 3 yellow
  # 4 blue
  # 5 magenta
  # 6 cyan
  # 7 white
}

block_alert(){
  tput bel
}

block_sleep(){
  sleep 1.2
}

print_header(){
  clear
  DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
  initdate="$TM - "
  host=`hostname`
  block_print=" hrs since last block"
  host_spot=$host
  legend="  `(tput setaf ${alert_color})`${min_time}m `(tput setaf ${hr6})`6h `(tput setaf ${hr24})`24h"
  walletID=$wallet_key

  if [[ -z $last_blk_time ]]; then
    blk_elapsed="init"
  else
    blk_elapsed=$(echo "scale=2;(($gnu_time - $last_blk_time)/3600)"|bc -l|awk '{printf "%.2f", $0}')
  fi
  block_since="  $blk_elapsed"
  
  claim_balance=0
  while read claimers; do
    claim_balance=$(echo "scale=2; $claim_balance + $claimers"|bc)
  done < <(echo ${wallet}|chia plotnft show|grep "Claimable"|awk '{print $3}')
  blocks_counted=$(echo "scale=0; $claim_balance / 1.75"|bc)
  block_claim=" - $blocks_counted blocks waiting to claim -\n"
  host_spot=$host
  if $narrow; then
    DT=" $(echo $DT|tail -c 6)"
    TM=" $(echo $TM|head -c 5)"
    block_print=" hrs since block"
    min_width=24
  elif $narrower; then
    DT=""
    TM=" $(echo $TM|head -c 5)"
    host_spot="xch txn"
    legend=" `(tput setaf ${hr6})`${hr_time1}h `(tput setaf ${hr24})`${hr_time2}h"
    block_print=" hr since blk"
    walletID=""
    block_since="$blk_elapsed"
    block_claim=" $blocks_counted blocks to claim\n"
  else
    DT=" - $DT"
    TM=" $TM"
    min_width=32
  fi
  if ! $narrower; then
    name_width=$(($max_width - $min_width))
    if [ ${#host} -gt $name_width ]; then
      name_width=$(($name_width - 2))
      host_spot="$(echo $host|head -c $name_width).."
    fi
  fi

  printf "`(tput setaf ${header_color})`$host_spot$DT$TM$legend\n"
  printf "`(tput setaf ${last_blk_color})` $walletID$block_since$block_print\n"
  printf "`(tput setaf ${claim_color})`$block_claim\n"
}

txn_output(){
  if [ $((i)) -eq 1 ]; then i=2; else i=1; fi
  echo ${wallet}|chia wallet get_transactions --no-paginate -l $max_txns|sed -n -e '1,60p'|grep -i 'amount\|created'| \
    sed '0~1 a\\'|sed '/^[[:space:]]*$/d' #|awk '{print;} NR % 2 == 0 { print ""; }' # this last part adds the space in between
}

get_time(){
  gnu_time=$(date --date="$(date)" '+%s')
}

txn_time(){
  txn_gnu_time=$(date --date="$txn_date $txn_time" '+%s')
  txn_day=$(echo $txn_date|awk '{print $1}'|awk -F"-" '{print $3}')
  if [ $(($txn_gnu_time + ($hr_time1 * 3600))) -gt $gnu_time ] && [ ! -z $block ]; then
    if [ $(($txn_gnu_time + ($min_time * 60))) -gt $gnu_time ]; then
      new_block=true
      new_cnt=$(($new_cnt+1))
    else
      new_block=false
      new_cnt=0
    fi
    txn_color=`(tput setaf ${hr6})`
  elif [ $(($txn_gnu_time + (hr_time2 * 3600))) -gt $gnu_time ]; then
    txn_color=`(tput setaf ${hr24})`
  elif [ -z $day_track ] || [ $txn_day -ne $day_track ]; then
    day_track=$txn_day  
    if [ $((color_num)) -eq $alt1 ]; then
      color_num=$alt2
    else
      color_num=$alt1
    fi
    txn_color=`(tput setaf ${color_num})`
  fi
}

get_txn(){
  while read txn; do
    if [[ $(echo $txn|grep Amount|wc -l) -eq 1 ]]; then
      xch=$(echo $txn|grep Amount|awk '{print $3}')
      if [ $xch = "1.75" ]; then
        claim_check=true
      elif $claim_check; then
        xch_hold=$xch
        xch="1.75"
        claim_num="claim x $claim_cnt"
        get_line
        xch=$xch_hold
        claim_check=false
      fi
      if [[ $(echo $txn|grep rewarded|wc -l) -eq 1 ]]; then
        block="block"
        block_num=$(($block_num + 1))
      else
        block=""
      fi
    elif [[ $(echo $txn|grep Created|wc -l) -eq 1 ]]; then
      line_cnt=$(($line_cnt+1))
      txn_date=$(echo $txn|grep Created|awk '{print $3}')
      txn_time=$(echo $txn|grep Created|awk '{print $4}')
      if [[ $block == "block" ]] && [ $block_num -eq 1 ]; then
        txn_gnu_time=$(date --date="$txn_date $txn_time" '+%s')
        last_blk_time=$txn_gnu_time
        update_last_block_time=false
      fi
      if $claim_check && [ -z $claim_time ]; then
        claim_date=$txn_date
        claim_time=$txn_time
        claim_cnt=1
      elif $claim_check && [[ $txn_time == $claim_time ]] && [[ $txn_date == $claim_date ]]; then
        claim_cnt=$(($claim_cnt+1))
        line_cnt=$(($line_cnt-1))
      elif [ $line_cnt -le $num_txn ]; then
        claim_check=false
        get_line
      elif [[ -z $last_blk_time ]]; then
        continue
      else
        break
      fi
    fi
  done <<< "$txns"
}

add_space(){
  if [[ ! -z $block ]]; then
    block="$spaces$block"
  elif [[ ! -z $claim_num ]]; then
    claim_num="$spaces$claim_num"
  fi
}

get_line(){
  txn_time
  if [[ ! -z $block ]] && $new_block && [[ $last_date != $txn_date ]] && [[ $last_time != $txn_time ]] ; then
    for (( i=1; i<=$(tput cols); i++ )); do
      if [ $((i)) -gt 48 ]; then break; fi
      alert="$alert*"
    done
    # Alert sound every other alert for that block
    if [[ -z $alert_sound_flag ]] || [[ $alert_sound_flag -eq 0 ]]; then
      alert_sound_flag=1
      block_alert
      block_sleep
      block_alert
    else
      alert_sound_flag=0
    fi
    if [[ $new_cnt -eq 1 ]]; then
      alert1="`(tput setaf ${alert_color})`$alert\n"
    else
      alert1=""
    fi
    alert2="`(tput setaf ${alert_color})`$alert\n"
    line_cnt=$(($line_cnt+2))
    new_block=false
  else
    alert1=""
    alert2=""
    last_date=$txn_date
    last_time=$txn_time
  fi
  if $narrow; then
    txn_date=$(echo $txn_date|tail -c 6)
    xch=$(echo $xch|head -c 6)
    xch_space=6
    spaces="  "
    add_space
  elif $narrower; then
    txn_date=$(echo $txn_date|tail -c 6|sed 's/-//g')
    txn_time=$(echo $txn_time|head -c 5|sed 's/://g')
    xch=$(echo $xch|head -c 4)
    xch_space=4
    spaces=" "
    add_space
  else
    xch_space=14
    spaces="  "
    add_space
  fi
  if [ $line_cnt -le $num_txn ]; then
    printf "$last_blk${txn_color}${alert1}%s %s$spaces%-${xch_space}s%s\n${alert2}" $txn_date $txn_time $xch "$block$claim_num"
  fi
  xch=""
  txn_date=""
  txn_time=""
  claim_time=""
  claim_cnt=""
  claim_num=""
}

if [[ -z $1 ]]; then
  wallet=1
else
  wallet=$1
fi

get_version
printf "\nVersion $version. Getting transactions for wallet $wallet."
variables
while true; do
  alert=""
  alert1=""
  alert2=""
  new_cnt=0
  txns=$(echo ${wallet}|chia wallet get_transactions --no-paginate -l $max_txns|grep -i 'amount\|created')
  block_num=0
  line_cnt=0
  num_txn=$(($(tput lines) - line_sub))
  max_width=$(tput cols)
  if [ $max_width -lt 20 ]; then
    narrow=false
    narrower=true
    num_txn=$((($num_txn - ${#blk_elapsed} + 1)/2))
  elif [ $max_width -lt 37 ]; then
    narrow=false
    narrower=true
  elif [ $max_width -lt 49 ]; then
    narrow=true
    narrower=false
  else
    narrow=false
    narrower=false
  fi
  print_header
  get_time
  get_txn
  day_track=""
  color_num=7
  sleep 60
done
