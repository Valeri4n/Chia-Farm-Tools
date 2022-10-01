#! /bin/bash
#
# Copyright 2022 by Valerian
#
# This will format and mount a drive and inclued pointer files for plot management

if [ -z $1 ] || [[ $1 != *"sd"* ]]; then echo "You must specify which drive(*s) first."; exit; fi

flags()
{
  while true; do #test $1 -gt 0; do
    case "$1" in
      -n|--nft)
        NFT=$2
        shift 2;;
      -s|--start)
        START=$2
        stBOOL=1
        shift 2;;
      -e|--end)
        END=$2
        enBOOL=1
        shift 2;;
      --)
        break;;
      *)
        break;;
#        printf "Unknown option %s\n" "$1"
#        exit 1;;
    esac
  done
}

flags "${@:2}"

if [ -z $NFT ]; then NFT=DEFAULT; fi

if [ $((stBOOL)) -eq 1 ] && [ $((enBOOL)) -eq 1 ]; then
  for a in {a..z}; do #(( a=$START; c<=$END; c++ )); do
    if [ $a == $START ] || [ $((GOING)) -eq 1 ]; then
      GOING=1
      d=/dev/$1$a
      m=/mnt/$1$a
      printf "\nFormatting $i and mounting for $NFT\n"
      mkfs.ext4 -F -b 4096 -m 0 -O ^has_journal -T largefile4 $d
      mount $m
      touch $m/nft-$NFT
      SIZE=$(df $m --output=size | awk -F "[[:space:]]+" '{print $1}' | tail -n 1)
      touch $m/drive-size-$SIZE
      echo $m/drive-size-$SIZE
      chown -R $USER $m
      chgrp -R $USER $m
    fi
    if [ $a == $END ]; then
      GOING=0
    fi
  done
else
  for i in /dev/$1; do
    j=/mnt/${i:5}
    printf "\nFormatting $i and mounting for $NFT\n"
    mkfs.ext4 -F -b 4096 -m 0 -O ^has_journal -T largefile4 $i
    mount $j
    touch $j/nft-$NFT
    SIZE=$(df $j --output=size | awk -F "[[:space:]]+" '{print $1}' | tail -n 1)
    touch $j/drive-size-$SIZE
    chown -R $USER $j
    chgrp -R $USER $j
    printf "$j/drive-size-$SIZE, nft-$NFT, format complete.\n\n"
  done 
fi
