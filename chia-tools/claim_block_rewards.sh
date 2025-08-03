#!/bin/bash
#
# Copyright 2025 by Valerian
#
# This script will run continuously and wait 5 minutes between and claim all balances for a given wallet fingerprint.
# The initial 5 minute wait is to ensure blocks have a chance to process to ensure complete before claiming. 
# This script can run continuously or be called separately from a block monitor script as blocks are won.
#
# To run, launch with the fingerprint in the command line
#       ./claim_block_rewards.sh 23875468764
#   Where 23875468764 is an example ficticious fingerprint. Replace with your fingerprint.

fingerprint=$1
sleep 300
for walletID in $(chia plotnft show -f $fingerprint|grep -v "Claimable balance: 0.0 xch"|grep -B 10 Claimable|grep "Wallet ID:"|awk '{print $3}'); do
  chia plotnft claim -f $fingerprint -i $walletID
done
