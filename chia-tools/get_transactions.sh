#!/bin/bash
#
# Copyright 2023 by Valerian

variables() {
  version=1.0
  number=" -l 60"
  block=false
}

help() {
  echo 
  echo "  get_transaction.sh v$version by Valerian"
  echo
  echo "This script provides an output of the Chia transactions in an easy to read format."
  echo "Default will get the last 60 transactions."
  echo
  echo "Usage:"
  echo " ./get_transactions.sh [options]"
  echo 
  echo "Options:"
  echo "  -a, --all      Output all transactions."
  echo "  -b, --block    Provide block count in output."
  echo "  -h, --help     Print help, usage and options to run the script."
  echo "  -n, --number   -n [number], Change the number of transactions in the output."
  echo "  -r, --reverse  List transactions in revers order."
  echo 
}

flags() {
  while true; do
    case $1 in
      -a|--all)
        number=""
        shift 1;;
      -b|--block)
        block=true
        shift 1;;
      -h|--help)
        help; exit 1
        shift 1;;
      -n|--number)
        number=" -l $2"
        shift 2;;
      -r|--reverse)
        reverse=" --reverse"
        shift 1;;
      --)
        break;;
      *)
        break;;
    esac
  done
}

variables
flags "${@}"
txns=$(echo 1|chia wallet get_transactions --no-paginate$number$reverse|grep -i -A 2 "reward\|received")
blk=0
while read line; do
  if [[ ! -z $(echo $line|grep -i "reward\|received") ]]; then
    amount=$(echo $line|grep -i "reward\|received"|cut -c 7-|rev|cut -c4-|rev|sed 's/\n//g')
    if $block && [[ ! -z $(echo $amount|grep -i reward) ]]; then
      blk=$(($blk + 1))
      blocks=" blocks: $blk"
    else
      blocks=""
    fi
  fi
  create=$(echo $line| grep -i created|tail -c 20|sed 's/\n//g')
  if [[ ! -z $create ]]; then
    printf "%s %-26s%s\n" "$create" "$amount" "$blocks"
    amount=""
    create=""
  fi
done <<< "$txns"
