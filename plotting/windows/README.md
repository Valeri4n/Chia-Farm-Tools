Use both scripts together. Launch with the bladebit-diskplot_run.cmd script. When you kick off this with the run script, it'll continue plotting forever. You will want to also have a robocopy instance running to move plots where you want them. To make changes to plotting parameters, simply change them on the diskplot script and save it. That way, the next time it starts a new plot, it'll get the updated settings automatically and you can just let it keep running without having to stop it to make adjustments.  

FARMER is the puble farmer key.  
NFT is the contract key.  
TEMP_DIR is the temporary plot folder.  
BB_DIR is where the bladebit.exe file is. These two scripts should be in the saem folder.  
FINAL_DIR is the plot final directory if you want it in a location other than the TEMP_DIR. I use robocopy to move them from here so BB can continue without having to move it.  

Can change the parameters in the script with RAM, THREADS, and BUCKETS to tweak it to test times. Just let the whole thing continue running, make the changes you want and save the file, and the next plot will pick up the new settings without stopping it.  
  
### File Transfer with Robocopy  
The following commands work in command prompt to run robocopy. These can be pasted into a batch file and run that way or directly in command prompt.  
```
set SRC="Y:"  
set DEST="D:"  
robocopy %SRC% %DEST% *.plot /j /mov /mon:1 /is /eta /nooffload
```  
