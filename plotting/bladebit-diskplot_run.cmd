:: Copyright 2022 by Valerian
@echo off
setlocal enableextensions disabledelayedexpansion


set FARMER=ENTER PUBLIC FARMER KEY HERE
set NFT=ENTER PUBLIC POOL CONTRACT KEY HERE
set TEMP_DIR=ENTER PLOT TEMP DIRECTORY HERE
set BB_DIR=ENTER BB FOLDER HERE

set FINAL_DIR=%TEMP_DIR%

cd /d %BB_DIR%

IF EXIST %TEMP_DIR%"*.tmp" DEL %TEMP_DIR%\"*.tmp"

:LOOP
  call :getTime now
  set "task=day"
  if "%now%" lss "04:00:00,00" ( set "task=day" ) 
  if "%now%" geq "22:00:00,00" ( set "task=day" )

  echo %now%
  call :task_%task%

goto :LOOP
pause

:task_day
  cmd /c bb-diskplot.cmd
  timeout 30
  goto :LOOP

:task_night
  cmd /c diskplot-night.cmd
  timeout 30
  goto :LOOP

:: getTime
::    This routine returns the current (or passed as argument) time
::    in the form hh:mm:ss,cc in 24h format, with two digits in each
::    of the segments, 0 prefixed where needed.
:getTime returnVar [time]
    setlocal enableextensions disabledelayedexpansion

    :: Retrieve parameters if present. Else take current time
    if "%~2"=="" ( set "t=%time%" ) else ( set "t=%~2" )

    :: Test if time contains "correct" (usual) data. Else try something else
    echo(%t%|findstr /i /r /x /c:"[0-9:,.apm -]*" >nul || ( 
        set "t="
        for /f "tokens=2" %%a in ('2^>nul robocopy "|" . /njh') do (
            if not defined t set "t=%%a,00"
        )
        rem If we do not have a valid time string, leave
        if not defined t exit /b
    )

    :: Check if 24h time adjust is needed
    if not "%t:pm=%"=="%t%" (set "p=12" ) else (set "p=0")

    :: Separate the elements of the time string
    for /f "tokens=1-5 delims=:.,-PpAaMm " %%a in ("%t%") do (
        set "h=%%a" & set "m=00%%b" & set "s=00%%c" & set "c=00%%d" 
    )

    :: Adjust the hour part of the time string
    set /a "h=100%h%+%p%"

    :: Clean up and return the new time string
    endlocal & if not "%~1"=="" set "%~1=%h:~-2%:%m:~-2%:%s:~-2%,%c:~-2%" & exit /b
