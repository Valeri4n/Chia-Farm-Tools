#!/bin/bash
#
# Copyright 2023 by Valerian

# Script will count plots and space used for mounted drives and connected network shares.
#
# The script relies on a drive size file on each drive. This is necessary to calculate total space.
#   Run drive_size_write.sh on each system to put this file in place.
#   Once the drive-size files are on each system, one system can then monitor all of the others.
#   This script will place the drive-size file for directly mounted drives.
#
# It is best to run this script in a tmux session for a persistent shell for monitoring.
#
# Currently configured to go from c0 to c7 chia plots

drive_size_writer(){
  one=1
}

plot_calc(){
  svr_size_comp=$(bc <<< "scale=8 ; ${svr_comp} * 0.08375")
  comp_plots=$(printf "%'d" "$svr_comp")
  tb_size_comp=$(printf "%'.3f" "$svr_size_comp")
  svr_size_nc=$(bc <<< "scale=8 ; ${svr_nc} * 0.10880384")
  nc_plots=$(printf "%'d" "$svr_nc")
  tb_size_nc=$(printf "%'.3f" "$svr_size_nc")
  if [ $(bc -l <<< "${server_space} > 0") -eq 1 ]; then
    svr_replot_percent=$(bc <<< "scale=3 ; ${svr_size_comp} / ${server_space} * 100")
  else
    svr_replot_percent=0
  fi
  if [[ ! -z $drive_space ]]; then
    svr_space=$(bc <<< "scale=8 ; ${server_space} / 1000")
    used=$(bc <<< "scale=1 ; (${svr_size_comp} + ${svr_size_nc}) / ${svr_space} / 10")
  fi
  space_bool=true
  if $space_bool; then
    svr_spc=$(printf "%'.3f" "$svr_space")
    used=$(printf "%'.1f" "$used")
    svr_replot_percent=$(printf "%'.1f" "$svr_replot_percent")
    space1="Space:"
    space2="PB"
  else
    svr_spc="    "
    space1="    "
    space2="    "
  fi
  printf "\r$(tput setaf ${color}) %-8s | ${new}:%7s : %9s TB | ${old}:%7s : %9s TB | $(tput setaf 7)${space1} %6s ${space2}  %4s%% $(tput setaf ${color})|$(tput setaf 5) %5s%%" ${server:0:8} $comp_plots $tb_size_comp $nc_plots $tb_size_nc $svr_spc $used $svr_replot_percent
}

new=c07
old=nc
comp_str=plot-k32-${new}*.plot
nc_str=plot-k32-20*.plot

while true; do
  total_comp=0
  total_size_comp=0
  svr_size_comp=0
  svr_comp=0
  total_nc=0
  total_size_nc=0
  svr_size_nc=0
  svr_nc=0
  total_space=0
  clear
  DT=`date +"%m-%d"`; TM=`date +"%T"`
  host=$(hostname)
  printf "$(tput setaf 3)$DT $TM - $host - number of plots - compressed vs non-compressed (nc):\n\n"
  printf " Location | $new Plots # :     Size     | $old Plots # :     Size     |   Drive Space    %% Used | $(tput setaf 5)replot$(tput setaf 6)\n"
  echo " ---------|----------------------------|---------------------------|-------------------------|$(tput setaf 5)-------"
  for server in /{mnt,svr/*,srv/*}; do
    space_bool=false
    if [[ $(ls $server 2>/dev/null|wc -l) -eq 0 ]]; then continue; fi
    svr_comp=0
    svr_nc=0
    server_space=0
    svr_space=0
    svr_spc=0
    comp_size=0
    nc_size=0
    for drive in $server/*; do
      comp=$(ls ${drive}/${comp_str} 2>/dev/null|wc -l)
      nc=$(ls ${drive}/${nc_str} 2>/dev/null|wc -l)

      drive_space=$(ls $drive/drive-size-* 2>/dev/null|awk -F- '{print $3}')
      if [[ ! -z $drive_space ]]; then
        drive_space=$(bc <<< "scale=8 ; ${drive_space} * 1.024 / 1000000000") # convert KiB to KB to PB
        server_space=$(bc <<< "scale=8 ; ${server_space} + ${drive_space}")
      fi

      svr_comp=$(( ${svr_comp} + ${comp} ))
      svr_nc=$(( ${svr_nc} + ${nc} ))
      color=5
      plot_calc
    done

        color=6
    plot_calc
    total_comp=$(( ${total_comp} + ${svr_comp} ))
    total_nc=$(( ${total_nc} + ${svr_nc} ))
    total_size_comp=$(bc <<< "scale=8 ; ${total_size_comp} + ${svr_size_comp}")
    total_size_nc=$(bc <<< "scale=8 ; ${total_size_nc} + ${svr_size_nc}")
    if [[ ! -z $svr_space ]]; then
      total_space=$(bc <<< "scale=8 ; ${total_space} + ${svr_space}")
    fi
    echo
  done
  total_size_comp=$(bc <<< "scale=8 ; ${total_size_comp} / 1000")
  total_size_nc=$(bc <<< "scale=8 ;${total_size_nc} / 1000")
  total_used=$(bc <<< "scale=8 ; ${total_size_comp} + ${total_size_nc}")
  effective_comp=$(bc <<< "scale=8 ; ${total_comp} * 0.10880384/1000")
  effective_total=$(bc <<< "scale=8 ; ${effective_comp} + ${total_size_nc}")
  increase=$(bc <<< "scale=8 ; (${effective_comp} - ${total_size_comp}) / (${total_size_comp} + ${total_size_nc}) * 100")
  percent_used=$(bc <<< "scale=3 ; ${total_used} / ${total_space} * 100")
  effective_comp=$(printf "%'0.3f" "$effective_comp")
  effective_total=$(printf "%'0.3f" "$effective_total")
  increase=$(printf "%'0.2f" "$increase")
  total_c=$(printf "%'0.3f" "$total_size_comp")
  total_comp=$(printf "%'d" "$total_comp")
  total_n=$(printf "%'0.3f" "$total_size_nc")
  total_nc=$(printf "%'d" "$total_nc")
  total_used=$(printf "%'0.3f" "$total_used")
  total_space=$(printf "%'0.3f" "$total_space")
  percent_used=$(printf "%'0.1f" "$percent_used")
  replot_percent=$(bc <<< "scale=3 ;${total_c} / ${total_space} * 100")
  replot_percent=$(printf "%'0.1f" "$replot_percent")
  echo "$(tput setaf 6) ---------|----------------------------|---------------------------|-------------------------|$(tput setaf 5)-------"
  printf "$(tput setaf 3) Total    | ${new}:%7s : %9s PB | ${old}:%7s : %9s PB |  Used: %6s PB        |\n" $total_comp $total_c $total_nc $total_n $total_used
  echo " ---------|----------------------------|---------------------------|-------------------------|$(tput setaf 5)-------$(tput setaf 3)"
  printf " Effective|       Eff. Size: %6s PB |     Eff. Total: %6s PB | $(tput setaf 7)Space: %6s PB  %4s%% $(tput setaf 3)|$(tput setaf 5) %5s%%\n\n%s%% effective increase$(tput sgr0)\n\n\n" \
    $effective_comp $effective_total $total_space $percent_used $replot_percent $increase
  sleep 900
done
