### TMUX  
I've found tmux to be a great way to display multiple panes in one window for monitoring multiple processes. This will create a persistent session that can be connected to from any ssh connection or terminal within the host and will maintain the session if the terminal is disconnected. Various scripts and status commands can tehn be run within each pane.
  
To install tmux: `sudo apt install tmux`  
Add a new session: `tmux new -s name`  
Attach to that session: `tmux a -t name`  
Create multiple panes inside that window with `ctrl-b` `%` or `ctrl-b` `"`  
<br/>
Mouse control allows for selecting the active pane and resizing panes by dragging pane lines with the mouse.  
To turn on mouse control: `ctrl-b` followed by `:set mouse on`  
The .tmux.conf file can also be updated to include a line with `set -g mouse on` to enable this in all sessions.  
A config file is highly recommended because it does other things like setting the default shell.
### Log Monitoring  
The `tail` command can be used to monitor logs. When done in a tmux session, it is easy to combine multiple systems into a single window to monitor logs.  
`tail -F .chia/mainnet/log/debug.log`  
Happy farming!
