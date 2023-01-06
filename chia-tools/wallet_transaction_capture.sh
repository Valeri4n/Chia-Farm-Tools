#!/bin/bash
#
# Copyright 2023 by Valerian
#
# no flags gets all transactions
# -pm gets prior month
# -cm gets current month
# -py gets prior year
# -cy gets current year
# -y gets year in yyyy format
# -m gets month in mm format, must be used with -y

month_year(){
  echo "Must enter -m month and -y year"
  exit 1
}

get_dates(){
  #xday is transaction day, etc
  xday=`echo $xdate|awk -F- '{print $3}'`
  int_xday=$((10#$xday))
  int_xmonth=$((10#$xmonth))
  
  # Get end date
  add_month=0
  add_year=0
    if [ $((int_xmonth)) -eq 12 ]; then
      add_month=-12
      add_year=1
    fi
  # fi
  int_end_month=$((int_xmonth + add_month + 1))
  if [ $((int_end_month)) -lt 10 ]; then
    end_month="0$int_end_month"
  else
    end_month=$int_end_month
  fi
  end_year=$((xyear + add_year))
  if [ $((captured_month)) -ne $((int_end_month)) ]; then # capture the next month and hold this one
    if [ $((captured_month)) -ne 0 ]; then
      preserve_data=true
    fi
    end=`date -d "$end_year-$end_month-01 00:00:00" "+%s"`

    #get start of transaction month or the 28th day of month prior if on the 1st
    if [ $((int_xday)) -eq 1 ]; then
      start_day=28
      if [ $((int_xmonth)) -eq 1 ]; then
        start_month=12
        start_year=$((xyear - 1))
      else
        start_month=$((int_xmonth - 1))
        if [ $((start_month)) -lt 10 ]; then start_month="0$start_month"; fi
        start_year=$xyear
      fi
    else
      start_day="01"
      if [ $((int_xmonth)) -eq 12 ]; then
        start_month="01"
        start_year=$((xyear - 1))
      else
        int_start_month=$((int_xmonth - 1))
        if [ $((int_start_month)) -lt 10 ]; then
          start_month="0$int_start_month"
        fi
        start_year=$xyear
      fi
    fi
    start=`date -d "$start_year-$start_month-$start_day 00:00:00" "+%s"`
    captured_month=$int_end_month
    get_data
  fi
}

get_data(){
  if $preserve_data; then
    prev_utime=("${utime[@]}")
    prev_price=("${price[@]}")
  fi
  sleep 1
  array=()
  price=()
  utime=()
  output=""
  output_error=0
  site="https://api.coingecko.com/api/v3/coins/chia/market_chart/range?vs_currency=usd&from=${start}&to=${end}"
  if [ -z $site ]; then echo "ERROR: no output from web call for xch price"; exit 1; fi
  output=`curl -s $site|awk -F"market_cap" '{print $1}'`
  output_error=`echo $output|grep -i error|wc -l`
  if [ $((output_error)) -ge 1 ]; then
    echo "ERROR: on getting xch price"
    echo $output
    exit 1
  fi
  IFS='],[' read -ra array <<< "$output"
  for i in ${array[@]}; do
    short=${i%.*}
    if [[ $short =~ ^-?[0-9]+$ ]]; then
      if [ $((short)) -gt 10000000 ]; then
        utime+=(${i::-3})
      else
        price+=(${i})
      fi
    fi
  done
}

get_xch_price(){
  xutime=`date -d "$xdate $xtime" "+%s"`
  xprice=0
  time_i=${#utime[@]}-1
  for (( $time_i; time_i>=0; time_i-- )); do
    xch_utime=${utime[$time_i]}
    if [ $((xch_utime)) -le $((xutime)) ]; then
      xprice=${price[$time_i]}
      break
    elif [ $((time_i)) -eq 0 ] && [ $((xch_time)) -gt $((xutime)) ]; then
      prev_data=${#prev_utime[@]}
      if [ $((prev_data)) -eq 0 ]; then
        echo "ERROR: utime is less than last time pulled. Check code"
        echo "$xdate $xtime $xid $xch_utime"
        exit 1
      fi
      time_j=${#prev_utime[@]}-1
      for (( $time_j; time_j>=0; time_j-- )); do
        xch_utime=${prev_utime[$time_j]}
        if [ $((xch_utime)) -le $((xutime)) ]; then
          xprice=${prev_price[$time_i]}
          break
        elif [ $((time_j)) -eq 0 ] && [ $((xch_time)) -gt $((xutime)) ]; then
          echo "ERROR: utime is less than last time pulled on prev_data. Check code"
          echo "$xdate $xtime $xid $xch_utime"
          exit 1
        fi
      done
    fi
  done
}

if [ ! -z $1 ]; then
  flag=true
  match_month=false
  match_year=false
fi

while true; do
  case $1 in
    -y|--year) # get year
      match_xyear=$2
      if $match_month; then
        file_id="$match_xyear-$match_xmonth"
      else
        file_id="$match_xyear"
        match_year=true
      fi
      if [ -z $month ]; then missing=false; fi
      shift 2;;
    -m|--month) # get month
      month=$2
      month_len=${#month}
      if [ $((month)) -lt 10 ] && [ $((month_len)) -eq 1 ]; then
        match_xmonth="0$month"
      else
        match_xmonth=$month
      fi
      file_id="$match_xyear-$match_xmonth"
      match_month=true
      match_year=false
      if [ -z $match_xyear ]; then missing=false; else missing=true; fi
      shift 2;;
    -cm|--current-month)
      match_xmonth=`date +%m`
      match_xyear=`date +%Y`
      match_month=true
      file_id="$match_xyear-$match_xmonth"
      shift 1;;
    -cy|--current-year)
      match_xyear=`date +%Y`
      match_year=true
      file_id="$match_xyear"
      shift 1;;
    -pm|--previous-month)
      match_xmonth=`date +%m`
      match_xyear=`date +%Y`
      if [ $((match_xmonth)) -eq 1 ]; then
        match_xmonth=12
        match_xyear=$((match_xyear - 1))
      fi
      match_month=true
      file_id="$match_xyear-$match_xmonth"
      shift 1;;
    -py|--previous-year)
      match_xyear=`date +%Y`
      match_xyear=$((match_xyear - 1))
      match_year=true
      file_id="$match_xyear"
      shift 1;;
    --)
      break;;
    *)
      break;;
  esac
done

header=true
xch=0
xtotal=0
income_total=0
captured_month=0
found_range=false
DT=`date +"%y-%m-%d"`; TM=`date +"%T"`; TM=`echo $TM|tr -d ':'`
cyear=`date +"%Y"`
pyear=$((cyear-1))
cmonth=`date +"%m"`
if [ $((cmonth)) -eq 1 ]; then
  pmonth=12
  pmyear=$((cyear-1))
else
  pmonth=$((cmonth-1))
  pmyear=$((cyear-1))
fi

while read -r line; do
  if $header; then
    wallet=$(echo $line|grep "wallet key"|wc -l)
    if [ $((wallet)) -ge 1 ]; then
      wid=$(echo $line|awk '{print $13}'|rev|cut -c3-|rev)
      file="$file_id-txn-wallet_id_$wid-$DT-$TM.csv"
      printf "\n$file_id Transactions for wallet id $wid in file $file\n\n"
      printf "%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n" "Date" "Time" "xch" "xchTotal" "Price" "Income" "TotalIncome" "Status" "Transaction" "Address"|tee $file
      header=false
    fi
  fi
  valid=$(echo $line|grep "Transaction\|Confirmed\|Amount\|address\|Created"|wc -l)
  if [ $((valid)) -ge 1 ]; then
    yid=$(echo $line|grep Transaction|wc -l)
    ystatus=$(echo $line|grep Confirmed|wc -l)
    yamount=$(echo $line|grep Amount|wc -l)
    yaddress=$(echo $line|grep address|wc -l)
    ytime=$(echo $line|grep Created|wc -l)
    if [ $((yid)) -gt 0 ]; then
      xid=$(echo $line|awk '{print $2}')
      if [[ $xid = "a" ]]; then
        xid=$(echo $line|awk '{print $15}')
      fi
      yid=0
    elif [ $((ystatus)) -gt 0 ]; then
      xstatus=$(echo $line|awk '{print $2}')
      ystatus=0
    elif [ $((yamount)) -gt 0 ]; then
      receive=$(echo $line|grep "received\|rewarded"|wc -l)
      reward=$(echo $line|grep "rewarded"|wc -l)
      send=$(echo $line|grep sent|wc -l)
      if [ $((receive)) -gt 0 ]; then
        neg=""
      elif [ $((send)) -gt 0 ]; then
        neg="-"
      else
        echo "error on $xid $line"
        exit 1
      fi
      xamount=$neg$(echo $line|awk '{print $3}')
      xamount=`printf "%.12f\n" $xamount`
      yamount=0
      receive=0
      send=0
    elif [ $((yaddress)) -gt 0 ]; then
      xaddress=$(echo $line|awk '{print $3}')
      yaddress=0
    elif [ $((ytime)) -gt 0 ]; then
      xdate=$(echo $line|awk '{print $3}')
      xtime=$(echo $line|awk '{print $4}')
      xyear=`echo $xdate|awk -F- '{print $1}'`
      xmonth=`echo $xdate|awk -F- '{print $2}'`
      if ! $flag || ($match_year && [[ $match_xyear = $xyear ]]) || ($match_month && [[ $match_xmonth = $xmonth ]] && [[ $match_xyear = $xyear ]]); then
        if [ $((reward)) -gt 0 ]; then
          blocks=$((blocks+1))
        fi
        get_dates
        get_xch_price
        xch=`echo "$xch + $xamount"|bc`
        xincome=`echo "$xprice * $xamount"|bc -l`
        usd_income=`echo $xincome|xargs printf "$%'.2f"`
        income_total=`echo "$income_total + $xincome"|bc -l`
        usd_total=`echo $income_total|xargs printf "$%'.2f"`
        printf "%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n" $xdate $xtime $xamount $xch $xprice $usd_income $usd_total $xstatus $xid $xaddress|tee -a $file
        found_range=true
      elif $found_range; then
        break
      fi
      ytime=0
      reward=0
    fi
  fi
done < <(echo|chia wallet get_transactions --no-paginate --reverse)
if [ -z $blocks ]; then blocks="No"; fi
echo
echo "$blocks blocks won during this period"
echo "$xch xch earned during this period with income of $usd_total"
mod_xch=`echo $xch|tr -d '.'`
if [[ $((mod_xch)) -eq 0 ]] || [ -z $mod_xch ]; then
  echo "No XCH was seen during this period. If this is in error, please run program again."
fi
echo
