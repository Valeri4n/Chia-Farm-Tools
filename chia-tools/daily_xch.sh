#!/bin/bash

# Copyright 2025 by Valerian
#
# This will extract daily xch from chia app

  xch_per_block=1

  etw_full=$(chia farm summary|grep "Expected time to win:"|awk -F": " '{print $2}')
  if [[ $(echo $etw_full|grep year|wc -l) -gt 0 ]]; then
    etw_yr=$(echo $etw_full|awk -F" year" '{print $1}'|sed 's/ //g')
    if [[ ${etw_yr} -eq 1 ]]; then plural=""; else plural="s"; fi
    yr_hrs=$(($etw_yr * 365 * 24))
    etw_yr="${etw_yr} yr${plural} "
  else
    yr_hrs=0
    etw_yr=""
  fi
  if [[ $(echo $etw_full|grep month|wc -l) -gt 0 ]]; then
    etw_mon=$(echo $etw_full|awk -F" month" '{print $1}'|sed 's/ //g')
    if [[ ${etw_mon} -eq 1 ]]; then plural=""; else plural="s"; fi
    mon_hrs=$((etw_mon * 30 * 24))
    etw_mon="${etw_mon} mon${plural} "
  else
    mon_hrs=0
    etw_mon=""
  fi
  if [[ $(echo $etw_full|grep week|wc -l) -gt 0 ]]; then
    etw_wk=$(echo $etw_full|awk -F" week" '{print $1}'|sed 's/ //g')
    if [[ ${etw_wk} -eq 1 ]]; then plural=""; else plural="s"; fi
    wk_hrs=$(($etw_wk * 7 * 24))
    etw_wk="${etw_wk} wk${plural} "
  else
    wk_hrs=0
    etw_wk=""
  fi
  if [[ $(echo $etw_full|grep day|wc -l) -gt 0 ]]; then
    etw_day=$(echo $etw_full|awk -F" day" '{print $1}'|sed 's/ //g')
    if [[ ${etw_day} -eq 1 ]]; then plural=""; else plural="s"; fi
    day_hrs=$(($etw_day * 24))
    etw_day="${etw_day} day${plural} "
  else
    day_hrs=0
    etw_day=""
  fi
  if [[ $(echo $etw_full|grep hour|wc -l) -gt 0 ]]; then
    etw_hrs=$(echo $etw_full|awk -F" hour" '{print $1}'|awk '{print $NF}'|sed 's/ //g')
    if [[ ${etw_hrs} -eq 1 ]]; then plural=""; else plural="s"; fi
    hr_hrs=$etw_hrs
    etw_hrs="${etw_hrs} hr${plural} "
  else
    hr_hrs=0
    etw_hrs=""
  fi
  if [[ $(echo $etw_full|grep min|wc -l) -gt 0 ]]; then
    etw_min=$(echo $etw_full|awk -F" min" '{print $1}'|awk '{print $NF}'|sed 's/ //g')
    if [[ ${etw_min} -eq 1 ]]; then plural=""; else plural="s"; fi
    min_hrs=$(echo "scale=2; ${etw_min} / 60"|bc)
    etw_min="${etw_min} min${plural} "
  else
    min_hrs=0
    etw_min=""
  fi
  if [[ $min_hrs > 0 ]]; then
    etw_scale=6
  else
    etw_scale=0
  fi
  etw_hrs_calc=$(echo "scale=${etw_scale}; $yr_hrs + $mon_hrs + $wk_hrs + $hr_hrs + $day_hrs + $min_hrs"|bc)
  daily_xch=$(echo "scale=4; 24 / $etw_hrs_calc * $xch_per_block"|bc)

  printf "\n$(tput setaf 5)Estimated daily XCH = $daily_xch\n\n$(tput sgr0)"
