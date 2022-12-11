## TMUX  
I've found tmux to be a great way to display multiple panes in one window for showing status. This will create a persistent session that can be connected to from any ssh connection or terminal within the host and will maintain the session if the terminal is disconnected.
  
To install tmux: `sudo apt install tmux`  
Add a new session: `tmux new -s name`  
Attach to that session: `tmux a -t chia`  
Create multiple panes inside that window with `ctrl-b %` or `ctrl-b "`  
## Get pool stats
Use whichever of these displays properly. Should display as follows:  
  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>Number of plots:</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>Current pool URL:</sup>   
&nbsp;&nbsp;&nbsp;&nbsp; <sup>Current difficulty:</sup>   
&nbsp;&nbsp;&nbsp;&nbsp; <sup>Points balance:</sup>   
&nbsp;&nbsp;&nbsp;&nbsp; <sup>Points found (24h):</sup>   
&nbsp;&nbsp;&nbsp;&nbsp; <sup>Percent Successful Points (sh4):</sup>   
  
`watch -n 20 "echo|chia plotnft show|sed -n -e '12p;15,19p'|sed -n 'h;n;G;p;n;p;n;p;n;p;n;p'"`  
`watch -n 20 "echo|chia plotnft show|sed -n -e '8p;11,15p'|sed -n 'h;n;G;p;n;p;n;p;n;p;n;p'"`  
<br/>
### wallet_check.sh  
This script will get current chia price and wallet for current value. To run continuously, use watch:  
`watch -n 60 ./wallet_check.sh`  

