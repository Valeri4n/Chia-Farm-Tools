#!/bin/bash
#
# Copyright 2023 by Valerian

# This script will ID which plot blocked for your farm.
# Specify number of blocks to look backwards to ID which plot blocked.
# If no number specified, last block will be checked.
# ID all plots using "all".
# ID single prior block number with -o.
#
# usage:
#   ./get_block.sh        Gets last block information
# or
#   ./get_block.sh 3      Gets information on last 3 blocks
# or
#   ./get_block.sh all    Gets information on all blocks
# or
#   ./get_block.sh -o 3   Gets information on 3rd prior block only
#
# This will check the last wallet synced. Check different wallet by syncing other wallet.


block_sub=20 # default number to search backwards for proper block
stradd=" for the last block"
first_check=1
if [[ -z $1 ]]; then
  last_check=1
elif [[ $1 = -o ]]; then # only this block
  last_check=$2
  first_check=$2
  stradd=" for previous block # $last_check"
elif [[ $1 = all ]]; then 
  last_check=$(grep -B 3 rewarded wallet_data|grep Transaction|awk -F"Transaction " '{print $2}'|wc -l)
else
  last_check=$1
  if [[ $last_check == 1 ]]; then
    plural=""
  else
    plural="s"
  fi
  stradd=" for the last $last_check block$plural"
fi
printf "\nCommencing block lookup$stradd\n\n"
echo|chia wallet get_transactions > wallet_data
chia rpc farmer get_harvesters > plot_data
block_txns=$(grep -B 2 -A 2 rewarded wallet_data|grep "Transaction"|awk -F"Transaction " '{print $2}')
txn_times=$(grep -B 2 -A 2 rewarded wallet_data|grep "Created"|awk -F"Created at: " '{print $2}'|sed 's/ /,/')

i=1
while read -r line; do
  host_line[$i]=$line
  i=$(($i+1))
done <<<$(sed -n '/\<host\>/=' plot_data)
i=1
for line_number in "${host_line[@]}"; do
  host_ip[$i]=$(sed "${line_number}q;d" plot_data|awk -F'\"' '{print $4}')
  host[$i]=$(echo "${host_ip[$i]}"|awk -F. '{print $4}')
  i=$(($i+1))
done

for (( check=${first_check}; check<=${last_check}; check++)); do
  wait_str=""
  last_block=$check
  txn=$(echo "${block_txns}"|sed -n ${check}p)
  txn_time=$(echo "${txn_times}"|sed -n ${check}p|sed 's/,/ /')
  printf "\nPrevious block # ${last_block} at $txn_time\ntxn=${txn}\n"
  block=$(curl -s https://alltheblocks.net/chia/coin/0x${txn}|grep "Confirmed At Height"|awk -F"height=" '{print $2}'|awk -F\" '{print $2}')
  plot=""
  plot_found=false
  nft=""
  block_less=$block_sub
  while [[ -z $plot ]] && [[ ${block_less} -ge 0 ]]; do
    wait_str="${wait_str}."
    block_str="Checking block $block"
    printf "\r$block_str$wait_str"
    pkey=$(curl -s "https://alltheblocks.net/chia/height/${block}"|grep "Plot Public Key" -A 1|grep -v "Plot Public Key"|sed 's/ //g')
    if [[ $(cat plot_data|grep $pkey|wc -l) -gt 0 ]]; then
      pkey_line=$(grep -n ${pkey} plot_data |awk -F: '{print $1}')
      i=1
      for line_number in "${host_line[@]}"; do
        if [[ ${pkey_line} -lt ${line_number} ]] || [[ ${i} -eq ${#host_line[@]} ]]; then
          j=$(($i-1))
          plot_host_ip="${host_ip[$j]}"
          plot_host="${host[$j]}"
          plot=$(sed "$(($(grep -n ${pkey} plot_data |awk -F: '{print $1}') - 2))q;d" plot_data|awk -F'\"' '{print $4}')
          plot_block=$block
          plot_found=true
          echo
          break
        fi
        i=$(($i+1))
      done
    fi
    block_less=$((${block_less}-1))
    block=$(($block-1))
  done

  if ! $plot_found; then
    printf "\r  $(tput setaf 3)Plot not found$(tput sgr0)                               \n\n"
  else
    color="$(tput setaf 6)"
    if [[ ! -z $nft ]]; then nft=${nft}-; fi
    printf "${color}\n$txn_time - block=${plot_block}\npkey=${pkey}\n//$plot_host_ip$plot$(tput sgr0)\n\n"
  fi
done
rm wallet_data
rm plot_data
