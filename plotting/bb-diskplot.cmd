:: Copyright 2022 by Valerian
:: This works for bladebit-v2.0.0-alpha2-windows-x86-64\

@echo off
mode con:cols=100 lines=2500
color 03

set THREADS=16
set RAM=110
set BUCKETS=256

title %date% %time% night-mode BB-diskplot %THREADS% threads %RAM%gb ram

  set hr=%time:~0,2%
  if "%hr:~0,1%" equ " " set hr=0%hr:~1,1%
  set DATETIME=Log_%date:~10,4%%date:~4,2%%date:~7,2%_%hr%%time:~3,2%%time:~6,2%
  set LOG_FILE=logs/%DATETIME%.log
  if not exist logs mkdir logs

  powershell "bladebit.exe -t %THREADS% -c %NFT% -f %FARMER% diskplot -b %BUCKETS% --cache %RAM%G -t1 Y:\ Y:\ | tee '%LOG_FILE%'"
