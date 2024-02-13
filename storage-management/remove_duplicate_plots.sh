#! /bin/bash
#
# Copyright 2024 by Valerian

# This script will find and remove duplicate plots on a system.
# Change loc to match your mount point.

loc=/mnt

echo "Starting checks for duplicate plots"
DT=$(date +"%m-%d"); TM=$(date +"%T")

for drive in $loc/*; do
  if [[ $(mount|grep "$drive "|wc -l) -eq 0 ]]; then continue; fi
  ls $drive/plot*.plot 2>/dev/null >> $DT-$TM-plots.csv
done
sed -i -e 's/\//,/g' $DT-$TM-plots.csv

arr_drive=()
arr_plot=()
remove=()

while IFS="," read -r col0 col1 col2 col3; do
  arr_drive+=($col2)
  arr_plot+=($col3)
done < <(cat $DT-$TM-plots.csv)
printf "\nCreated plot array. Checking for duplicates.\n\n"

i=0
for plot in "${arr_plot[@]}"; do
  drive=${arr_drive[$i]}
  printf "\rChecking $loc/$drive/$plot         "
  if [[ $(grep $plot $DT-$TM-plots.csv|wc -l) > 1 ]]; then
    count=0
    for file in $(grep $plot $DT-$TM-plots.csv); do
      remove_plot=true
      this_file=$(echo $file|sed -e 's/,/\//g')
      for removed_plot in "${removed[@]}"; do
        if [[ $this_file == $removed_plot ]]; then
          remove_plot=false
        fi
      done
      if [[ $count > 0 ]] && $remove_plot; then
        tput bel
        printf "\n$(tput setaf 3)Removing $this_file$(tput sgr0)\n ctrl-c to cancel\n\n"
        sleep 5
        rm $this_file
        removed+=($this_file)
      fi
      count=$(($count+1))
    done
  fi
  i=$(($i + 1))
done

rm $DT-$TM-plots.csv
printf "\n\n$(tput setaf 6)COMPLETED, removed the following plots:\n"
printf '   %s\n' "${removed[@]}"
tput sgr0
echo
