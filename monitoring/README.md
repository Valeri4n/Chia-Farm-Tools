###Log monitoring  
The `tail` command can be used to monitor logs. When done in a tmux session, it is easy to combine multiple systems into a single window to monitor logs. I've found that the tail process occasionally hangs and I have to restart it. Instead of manually doing this, I've added a cronjob to restart it every fours hours as follows:
```
0 */4 * * * kill -9 $(ps aux|grep "tail -f .chia/mainnet/log/debug.log"|grep -v grep|awk '{print $2}'); tmux send-keys -t logs.0 "tail -f .chia/mainnet/log/debug.log" Enter
```
Happy farming!
