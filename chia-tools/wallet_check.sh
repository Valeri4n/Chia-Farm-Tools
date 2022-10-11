#! /bin/bash
# Copyright 2022 by Valerian
#
# This script will get current chia price and wallet for current value

xch=$(curl https://www.coingecko.com/en/coins/chia -s | grep -i "today is" | awk -F">" '{print $5}' | awk -F"<" '{print $1}' | cut -c2-)
wallet=$(echo | chia wallet show | grep Total | sed -n "1p" | head -c 44 | awk '{print $3}')
total=`echo "$xch * $wallet" | bc | xargs printf "%.2f"`
value=`printf "$%'.2f\n" $total`
printf "XCH=\$$xch  Wallet=$wallet\n"
printf "\n Current Value = $value\n\n"
