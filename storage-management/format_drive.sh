#! /bin/sudo bash
#
# Copyright 2022 by Valerian
#
# This script will format and mount a drive and also add index files for plot management

help()
{
  echo ""
  echo "This script will format and mount drives. Mountpoint paths are within the /mnt directory and"
  echo "  use drive names for directory mount points. For example, /dev/sda is mounted at /mnt/sda, etc."
  echo "  ensure directories exist for mountpoints prior to running script."
  echo ""
  echo "Usage:"
  echo " format_drive.sh -u <user> -d <drive> [options]"
  echo ""
  echo "Required:"
  echo "  -d, --drive		REQUIRED: drive must be specified in format sdxy"
  echo "			  If there are multiple drives of the pattern sdxy, where y is continous letters,"
  echo "			  can specify sdx as drive and then use -s and -e options for starting and ending"
  echo "			  For example, sdma through sdmf may all be formatted using:"
  echo "			    ./format_drive.sh -u <user> -d sdm -s a -e f"
  echo "			  otherwise, without using start and end letters, use the following example:"
  echo "			    ./format_drive.sh -u <user> -d sdme"
  echo "  -e, --end		ending drive letter for y in sdxy when -d sdx is specified"
  echo "			  -e not used when -s is used will end at -s value and end at z"
  echo "  -h, --help		shows usage and options to run the script"
  echo "  -n, --nft		specify the name assigned for the nft associated with the contract address"
  echo "			  This is useful when using nft names to manage plots and drives available"
  echo "			  for specifc nft plots"
  echo "  -s, --start		starting drive letter for y in sdxy when -d sdx is specified"
  echo "			  -s not used when -e is used will start at a and end at -e value"
  echo "  -t, --type		DEFAULT: ext4 if not specified"
  echo "			  specify the filesystem type to format the drive"
  echo "			  Currently only ntfs and ext4 may be used"
  echo "  -u, --username	REQUIRED: specify username for changing ownership of mount directories to"
  echo "  -w, --wipe		WARNING: wipes the drive and any preexisting partitions that may be present"
  echo "			  This option will ask for confirmation prior to wiping the drive"
  echo ""
}

flags()
{
  while true; do #test $1 -gt 0; do
    case $1 in
      -d|--drive)
        drv=$2
        shift 2;;
      -h|--help)
        help=1
        shift 1;;
      -n|--nft)
        NFT=$2
        shift 2;;
      -s|--start)
        START=$2
        stBOOL=1
        if [ $((enBOOL)) -ne 1 ]; then END=z; enBOOL=1; fi
        shift 2;;
      -e|--end)
        END=$2
        enBOOL=1
        if [ $((stBOOL)) -ne 1 ]; then START=a; stBOOL=1; fi
        shift 2;;
      -t|--type)
        type=$2
        shift 2;;
      -u|--user)
        username=$2
        shift 2;;
      -w|--wipe)
        WIPE=1
        shift 1;;
      --)
        break;;
      *)
        break;;
#        printf "Unknown option %s\n" "$1"
#        exit 1;;
    esac
  done
}

flags "${@}"

if [ $((help)) -eq 1 ]; then help; exit 1; fi
if [[ ! $drv == sd* ]]; then echo "You must specify which drive(s) with -d."; exit 1; fi
if [[ $type == ntfs ]] || [[ $type == ext4 ]] || [[ $type == f2fs ]]; then type=$type; else type=ext4; echo " Using ext4 filesystem type. CTRL-C to cancel."; sleep 5; fi
if [ -z $NFT ]; then echo "Must enter NFT"; exit 1; fi
if [ -z $username ]; then echo "must enter username"; exit 1; fi
if [ -z $type ]; then echo "must enter filesystem type"; exit 1; fi
i=0
if [ $((stBOOL)) -eq 1 ] && [ $((enBOOL)) -eq 1 ]; then
  for a in {a..z}; do #(( a=$START; c<=$END; c++ )); do
    if [ $a == $START ] || [ $((GOING)) -eq 1 ]; then
      GOING=1
      x[${#x[@]}]=/dev/$drv$a
      y[${#y[@]}]=/mnt/$drv$a
      z[${#z[@]}]=/dev/$drv$a'1'
    fi
    if [ $a == $END ]; then
      GOING=0
      break
    fi
  done
else
  for n in /dev/$drv; do
    x[${#x[@]}]=$n
    y[${#y[@]}]=/mnt/${n:5}
    z[${#y[@]}]=$n'1'
  done
fi
j=0
for i in "${x[@]}"; do
  printf "\nFormatting $i and mounting for $NFT\n"
  d="${x[$j]}"
  m="${y[$j]}"
  j=$((j + 1))
  if [ $type = ntfs ]; then
    p="${z[$j]}"
    has_part=`sfdisk -d $d 2>/dev/null | wc -l`
    if [ $((has_part)) -gt 0 ]; then
      if [ $((WIPE)) -eq 1 ]; then
        echo " ********************************************************************************************"
        echo " ***** WARNING: Proceeding may result in data loss. Ensure you know what you are doing! *****"
        echo " ********************************************************************************************"
        read -p " $d contains a preexisting partition. Are you sure you want to wipe the drive?! (yes/no): " -n1 r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          echo " erasing $d"
          mounted=`mount | grep $m | wc -l`
          if [ $((mounted)) -gt 0 ]; then
            umount $m
            sleep 2
          fi
          wipefs -f -a $d
          has_part=0
        else
          echo " Exiting"
          exit 1
        fi
      else
        echo " $d already has a partition. Verify and manually remove existing partitions prior to formatting for ntfs. Use -w to wipe."
        exit 1
      fi
    fi
    if [ $((has_part)) -eq 0 ]; then
      (
        echo g  # create empty gpt partition table
        echo n  # add a new partition
        echo    # default partition number 1
        echo    # default first sector
        echo    # default last sector
        echo t  # change partition type
        echo 11 # Microsoft basic data
        echo w  # write the partition table
      ) | fdisk $d
      p=$d'1'
      echo " Partitioned $p"
    fi
    size=`smartctl -i $d | grep TB] | awk '{print $5}' | cut -c 2- | awk -F"." '{print $1}'TB`
    serial=`smartctl -i $d | grep Serial | awk '{print $3}'`
    label=$size'TB-sn:'$serial
    mkntfs -f -L $label $p
  elif [ $type = ext4 ]; then
    mkfs.$type -F -b 4096 -m 0 -O ^has_journal -T largefile4 $d
  else
    mkfs.$type $d
  fi
  mount $p $m
  sleep 2
  mounted=`mount | grep $m | wc -l`
  if [ $((mounted)) -gt 0 ]; then
    printf "$m/drive-size-$SIZE, nft-$NFT, format complete.\n\n"
    touch $m/nft-$NFT
    SIZE=$(df $m --output=size | awk -F "[[:space:]]+" '{print $1}' | tail -n 1)
    touch $m/drive-size-$SIZE
    echo $m/drive-size-$SIZE
    chown -R $username $m
    chgrp -R $username $m
    echo " $p was mounted and initialized for plotting with nft-$NFT"
  else
    echo " ERROR: $d not mounted"
  fi
done
