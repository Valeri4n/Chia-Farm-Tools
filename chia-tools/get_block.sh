#!/bin/bash
#
# Copyright 2023 by Valerian

# This script will ID which plot blocked for your farm.
# Specify number of blocks to look backwards to ID which plot blocked.
# If no number specified, last block will be checked.
# ID all plots using "all".
#
# usage:
#   ./get_block.sh
# or
#   ./get_block.sh 3
# or
#   ./get_block.sh all
#
# This will check the last wallet synced. Check different wallet by syncing other wallet.

if [[ -z $1 ]]; then
  last_check=1
elif [[ $1 = all ]]; then 
  last_check=$(echo|chia wallet get_transactions|grep -B 3 rewarded|grep Transaction|awk -F"Transaction" '{print $2}'|sed 's/ //g'|wc -l)
else
  last_check=$1
fi

for (( check=1; check<=${last_check}; check++)); do
  last_block=$check
  txn=$(echo|chia wallet get_transactions|grep -B 3 rewarded|grep Transaction|sed -n ${last_block}p|awk -F"Transaction" '{print $2}'|sed 's/ //g')
  printf "\nPrevious block # ${last_block}\ntxn=${txn}\n"
  block=$(curl -s https://alltheblocks.net/chia/coin/0x${txn}|grep "Confirmed At Height"|awk -F"height=" '{print $2}'|awk -F\" '{print $2}')
  block=$((block-9))
  plot=""
  i=1
  plot_found=true
  nft=""
  while [[ -z $plot ]]; do
    printf "."
    i=$(($i+1))
    block=$(($block+1))
    pkey=$(curl -s "https://alltheblocks.net/chia/height/${block}"|grep "Plot Public Key" -A 1|grep -v "Plot Public Key"|sed 's/ //g')
    plot=$(curl --insecure --no-progress-meter \
      --cert ~/.chia/mainnet/config/ssl/harvester/private_harvester.crt \
      --key ~/.chia/mainnet/config/ssl/harvester/private_harvester.key \
      -d '{}' \
      -H "Content-Type: application/json" \
      -X POST https://localhost:8560/get_plots \
        | python3 -m json.tool \
        | grep -B5 ${pkey} \
        | grep -o '/.*\.plot')
    if [[ ${i} -gt 10 ]]; then
      printf "\r             \n\n$(tput setaf 3)Plot not found$(tput sgr0)\n\n"
      plot_found=false; break
    fi
  done

  if $plot_found; then
    printf "\rplot=$plot\n"
    svr=""
    server=""
    for i in {1..10}; do
      if [[ ${i} -eq 1 ]] && [[ $(echo $plot|awk -F/ -v x=$i '{print $x}') == "" ]]; then
        root=true
      elif [[ ${i} -eq 1 ]]; then
        root=false
      fi
      if [[ $(echo $plot|awk -F/ -v x=$i '{print $x}'|tail -c 6) == ".plot" ]]; then
        plot=$(echo $plot|awk -F/ -v x=$i '{print $x}')
        break
      elif ([[ ${i} -eq 1 ]] && ! $root ) || ([[ ${i} -eq 2 ]] && $root ); then
        mount_path=$(echo $plot|awk -F/ -v x=$i '{print $x}')
        if [[ ${mount_path} == "svr" ]] || [[ ${mount_path} == "srv" ]]; then
          svr=$(echo $plot|awk -F/ -v x=$((${i}+1)) '{print $x}')
          if [[ ! -z $svr ]]; then
            server=${svr}/
          fi
          drive=$(echo $plot|awk -F/ -v x=$((${i}+2)) '{print $x}')
          nft=$(ls /${mount_path}/${server}${drive}/nft-* 2>/dev/null|awk -F/ -v x=$((${i}+3)) '{print $x}')
        else
          svr=$(hostname|awk -F- '{print $1}')
          drive=$(echo $plot|awk -F/ -v x=$((${i}+1)) '{print $x}')
          nft=$(ls /${mount_path}/${server}${drive}/nft-* 2>/dev/null|awk -F/ -v x=$((${i}+2)) '{print $x}')
        fi
      fi
    done
    color="$(tput setaf 5)"
    if [[ ! -z $nft ]]; then nft=${nft}-; fi
    printf "${color}\nblock=${block}\npkey=${pkey}\n${nft}${svr}-${plot}$(tput sgr0)\n\n"
  fi
done
