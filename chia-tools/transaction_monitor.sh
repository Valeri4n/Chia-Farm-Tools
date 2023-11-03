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

# Future updates will include block number and feature to send an email

get_version()
{
  version=0.4
}

variables(){
  min_time=10
  hr_time1=6
  hr_time2=24
  claim_check=false
  wallet_string=$(echo |chia wallet get_transactions)
  wallet_key1=$(echo "$wallet_string"|grep "${wallet})"|awk '{print $2}'|sed -n 1p)
  wallet_key2=$(echo "$wallet_string"|grep "${wallet})"|awk '{print $3}'|sed -n 1p)
  if [[ $wallet_key1 == "*" ]]; then
    wallet_key=$wallet_key2
  else
    wallet_key=$wallet_key1
  fi
  line_sub=8
  max_txns=1000
  # email=
  new_block=false
  sound_block_alert=false

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
  for i in 1 to 3; do
    tput bel
    sleep 1.2
  done
  # send email
}

block_sleep(){
  sleep 1.2
}

print_header(){
  DT=`date +"%y-%m-%d"`; TM=`date +"%T"`
  initdate="$TM - "
  host=`hostname`
  block_print=" hrs since block"
  host_spot=$host
  legend="  `(tput setaf ${alert_color})`${min_time}m `(tput setaf ${hr6})`6h `(tput setaf ${hr24})`24h"
  walletID=$wallet_key

  if [[ -z $last_blk_time ]]; then
    blk_elapsed="init"
  else
    blk_elapsed=$(echo "scale=2;(($gnu_time - $last_blk_time)/3600)"|bc -l|awk '{printf "%.2f", $0}')
  fi
  block_since=" $blk_elapsed"

  claim_balance=0
  while read claimers; do
    claim_balance=$(echo "scale=2; $claim_balance + $claimers"|bc)
  done < <(echo ${wallet}|chia plotnft show|grep "Claimable"|awk '{print $3}')
  xch_price
  get_etw
  blocks_counted=$(echo "scale=0; $claim_balance / 1.75"|bc)
  block_claim=" - $blocks_counted blocks, $claim_balance xch to claim -\n"
  wallet_str="Wallet:"
  host_spot=$host
  change_str="last 24 hrs"
  etw_space=""
  etw_str="ETW: "
  xch_str=" price"
  xch_space=""
  blk_space=""
  if $narrow; then
    DT=" $(echo $DT|tail -c 6)"
    TM=" $(echo $TM|head -c 5)"
    block_print=" hrs since block"
    change_str="24h"
    min_width=24
    etw_space=" "
  elif $narrower; then
    DT=""
    TM=" $(echo $TM|head -c 5)"
    host_spot="xch txn"
    legend=" `(tput setaf ${hr6})`${hr_time1}h `(tput setaf ${hr24})`${hr_time2}h"
    block_print=" hr since blk"
    walletID=""
    block_since="$blk_elapsed"
    block_claim=" ${blocks_counted} blk, ${claim_balance} xch\n"
    change_str=""
    xch_str=""
    etw_str=""
    wallet_total=$(printf "%.3f\n" $wallet_total)
  else
    DT=" - $DT"
    TM=" $TM"
    etw_space="  "
    xch_space="  "
    blk_space=" "
    min_width=32
  fi
  if ! $narrower; then
    name_width=$(($max_width - $min_width))
    if [ ${#host} -gt $name_width ]; then
      name_width=$(($name_width - 2))
      host_spot="$(echo $host|head -c $name_width).."
    fi
  fi
  clear
  sleep 0.1
  printf "$(tput setaf ${header_color})$host_spot$DT$TM$legend\n"
  printf "$xch_space$(tput setaf 6)XCH$xch_str: $(tput setaf ${xch_color})$xch_value $(tput setaf ${xch_color1})$code$(tput setaf 6) $change_str\n"
  printf "$(tput setaf ${claim_color})$wallet_str $walletID $(tput setaf ${total_color})${wallet_total} xch\n"
  printf "$(tput setaf 3)            value: $(tput setaf ${total_color})$wallet_value\n"
  printf "$(tput setaf 7)$etw_str$etw$block_since$block_print\n"
  printf "$(tput setaf ${claim_color})$blk_space$block_claim\n"
}

price_change(){
  change=$(curl -H "User-Agent: Mozilla/5.0 Chrome/44.0.2403.89" "https://www.coingecko.com/en/coins/chia" -s -k| \
    grep '<div class=\"tw-flex-1 py-2 border px-0\"><span class=\"tw-text-danger-500 tw-break-words\|<div class=\"tw-flex-1 py-2 border px-0\"><span class=\"tw-text-success-500 dark:tw-text-success-400 tw-break-words'| \
    awk -F'data-formatted=\"false\">' '{print $2}'|awk -F'</span>' '{print $1}'|sed -n 1p)
  if [[ -z $change ]]; then
    change=0.0
    change_value=0.0
  else
    change_value=$(echo $change|sed 's/%//')
  fi
  if [[ $(echo $change|head -c 1) == "-" ]]; then
    code="\u2193"
    xch_color1=5
  elif [[ $(bc -l <<< "${change_value} > 0") -eq 1 ]]; then
    code="\u2191"
    xch_color1=2
  else
    code=""
    xch_color1=3
  fi
  code="$code $change_value%%"
  if [[ "$blk_elapsed" != "init" ]]; then
    if [[ $(bc -l <<< "${xch_value} < ${last_value}") -eq 1 ]]; then
      xch_color=5
    elif [[ $(bc -l <<< "${xch_value} > ${last_value}") -eq 1 ]]; then
      xch_color=2
    fi
  else
    xch_color=6
  fi
  last_value=$xch_value
}

get_etw(){
  etw_full=$(chia farm summary|grep "Expected time to win:"|awk -F": " '{print $2}')
  if [[ $(echo $etw_full|grep day|wc -l) -gt 0 ]]; then
    etw_day=$(echo $etw_full|awk -F" day" '{print $1}'|sed 's/ //')
    if [[ ${#etw_day} -lt 2 ]]; then
      etw_day="0$etw_day"
    fi
  else
    etw_day="00"
  fi
  if [[ $(echo $etw_full|grep hour|wc -l) -gt 0 ]]; then
    etw_hrs=$(echo $etw_full|awk -F" hour" '{print $1}'|awk '{print $NF}'|sed 's/ //')
    if [[ ${#etw_hrs} -lt 2 ]]; then
      etw_hrs="0$etw_hrs"
    fi
  else
    etw_hrs="00"
  fi
  if [[ $(echo $etw_full|grep min|wc -l) -gt 0 ]]; then
    etw_min=$(echo $etw_full|awk -F" min" '{print $1}'|awk '{print $NF}'|sed 's/ //')
    if [[ ${#etw_min} -lt 2 ]]; then
      etw_min="0$etw_min"
    fi
  else
    etw_min="00"
  fi
  etw="${etw_day}d ${etw_hrs}h ${etw_min}m "
}

xch_price(){
  xch_return=$(curl "https://api.coingecko.com/api/v3/simple/price?ids=chia&vs_currencies=usd&include_market_cap=false&include_24hr_vol=false&include_24hr_change=flase&include_last_updated_at=true&precision=full" -s)
  xch_value=$(echo $xch_return|awk -F "," '{print $1}'|awk -F ":" '{print $3}')
  if [[ -z $xch_value ]] || [[ $(echo $xch_return|grep "error_code"|wc -l) -gt 0 ]]; then
    xch_value=`curl "https://www.coingecko.com/en/coins/chia" -s|grep "data-coin-symbol=.*xch.*data-target="|sed -n 3p|awk -F "price.price" '{print $2}'|cut -c 4-|head -c 5`
  fi
  price_change
  wallet_balance
}

txn_output(){
  if [ $((i)) -eq 1 ]; then i=2; else i=1; fi
  echo ${wallet}|chia wallet get_transactions --no-paginate -l $max_txns|sed -n -e '1,60p'|grep -i 'amount\|created'| \
    sed '0~1 a\\'|sed '/^[[:space:]]*$/d'
}

wallet_balance(){
  wallet_total=$(echo|chia wallet show|grep "\-Total Balance:"|sed -n 1p|awk '{print $3}')
  if [[ -z $previous_total ]]; then
    previous_total=$wallet_total
    total_color=6
  elif [[ $(bc -l <<< "${wallet_total} < ${previous_total}") -eq 1 ]]; then
    total_color=5
  fi
  wallet_value=$(bc <<< "${xch_value} * ${wallet_total}")
  wallet_value=$(printf "$%'.2f\n" $wallet_value)
  xch_value=$(printf '$%.2f\n' "$xch_value")
}

get_time(){
  gnu_time=$(date --date="$(date)" '+%s')
}

trxn_time(){
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
      if [[ ! -z $block ]] && [ $block_num -eq 1 ]; then
        txn_gnu_time=$(date --date="$txn_date $txn_time" '+%s')
        sound_alert=true
        last_blk_time=$txn_gnu_time
        update_last_block_time=false
        block_num=2
      else
        sound_alert=false
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
  trxn_time
  if [[ ! -z $block ]] && $new_block && [[ $last_date != $txn_date ]] && [[ $last_time != $txn_time ]] ; then
    for (( i=1; i<=$(tput cols); i++ )); do
      if [ $((i)) -gt 48 ]; then break; fi
      alert="$alert*"
    done
    if [[ $new_cnt -eq 1 ]]; then
      alert1="`(tput setaf ${alert_color})`$alert\n"
      if [[ -z $last_sounded ]] || [[ $last_sounded != $txn_gnu_time ]]; then
        not_sounded=true
      fi
    else
      alert1=""
    fi

    if $not_sounded && [[ $last_sounded != $txn_gnu_time ]]; then
      sound_block_alert=true
      last_sounded=$txn_gnu_time
      not_sounded=false
    else
      sound_block_alert=false
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
    if $sound_block_alert; then
      block_alert
      sound_block_alert=false
    fi
    if $not_sounded && [[ ! -z $block ]] && $new_block && ([[ -z $last_sounded ]] || [[ $last_sounded != $txn_gnu_time ]]); then
      sound_block_alert=true
      not_sounded=false
      last_sounded=$txn_gnu_time
    else
      sound_block_alert=false
    fi
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
printf "\nChia transaction monitor version $version\n   by Valerian\n\nGetting transactions for wallet $wallet"
variables
while true; do
  not_sounded=true
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
  sleep 30
  not_sounded=false
done
