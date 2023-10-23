#!/bin/bash
#
# Copyright 2023 by Valerian

# This script will auto check plots created the previous day and auto delete bad plots.
# To run daily 30 minutes after midnight in a tmux session, add a cronjob with:    crontab -e    then:
#   30 0 * * *  tmux new-session -d -s plotcheck; tmux send-keys -t plotcheck "/home/$(whoami)/plot_check.sh" Enter
# This will run the script within a tmux window called plotcheck and allow seeing script status. Connect with:
#   tmux a -t plotcheck  

get_date(){
  year=`date +%Y -d "yesterday"`
  month=`date +%m -d "yesterday"`
  day=`date +%d -d "yesterday"`
}

remove_bad_plots(){
  for line in $(grep invalid -A $(($(grep invalid < ${output}|awk '{print $6}') + 1)) < ${output}|grep -v " plots"|awk '{print $6}'|sed -e "s/\x1B[^m]*m//g"); do
    echo " Deleting bad plot: $line"
    rm $line
  done
}

SCRIPTPATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"
get_date
output=${SCRIPTPATH}/plotcheck_${year}${month}${day}

printf "\n\n$(tput setaf 3) checking plots dated ${year}-${month}-${day}$(tput sgr0)\n\n"
chia stop harvester
chia plots check -n 10 -l -g -${year}-${month}-${day}- 2>&1|tee ${output}
sed -e "s/\x1B[^m]*m//g" ${output} > ${output}.txt # remove ansi color encoding
chia start harvester
remove_bad_plots
