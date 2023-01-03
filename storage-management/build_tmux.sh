#!/bin/bash
#
# Copyright 2023 by Valerian

tmux new-session -d -s plot 'exec bash'
tmux split-window -t plot -v -p 43
tmux split-window -h
tmux split-window -h -p 67
tmux split-window -h
tmux select-pane -t 1
tmux split-window -h -p 67
tmux split-window -h
tmux select-pane -t 0
tmux split-window -h
tmux select-pane -t 0
tmux split-window -v -p 22
tmux select-pane -t 0
tmux split-window -h
tmux select-pane -t 0
tmux split-window -v -p 33
tmux select-pane -t 2
tmux split-window -v
tmux select-pane -t 5
tmux split-window -v -p 40
tmux split-window -h
tmux split-window -v
tmux select-pane -t 6
tmux split-window -v
tmux select-pane -t 5
tmux split-window -v
tmux select-pane -t 5
tmux split-window -h
tmux select-pane -t 12
tmux split-window -v
tmux split-window -v
tmux select-pane -t 15
tmux split-window -v
tmux split-window -v
tmux select-pane -t 15
tmux split-window -v
tmux select-pane -t 19
tmux split-window -v -p 75
tmux split-window -v -p 68
tmux split-window -v
tmux select-pane -t 23
tmux split-window -v -p 75
tmux split-window -v -p 67
tmux split-window -v
tmux select-pane -t 27
tmux split-window -v -p 75
tmux split-window -v -p 68
tmux split-window -v
tmux select-pane -t 31
tmux split-window -v -p 25
tmux select-pane -t 31
tmux split-window -v
tmux send-keys -t 0 "plot" Enter
tmux send-keys -t 1 "cache" Enter
tmux send-keys -t 2 "check -p -n nftName" Enter
tmux send-keys -t 4 "temps" Enter
tmux send-keys -t 13 "r321" Enter
tmux send-keys -t 14 "r322" Enter
tmux send-keys -t 17 "r33" Enter
tmux send-keys -t 18 "desk" Enter
tmux send-keys -t 21 "r341" Enter
tmux send-keys -t 22 "r342" Enter
tmux send-keys -t 25 "r351" Enter
tmux send-keys -t 26 "r352" Enter
tmux send-keys -t 29 "r361" Enter
tmux send-keys -t 30 "r362" Enter
tmux send-keys -t 32 "watch -n 60 ./wallet_check.sh" Enter
tmux send-keys -t 33 "clock" Enter
