# Chia-Farm-Tools
This page has various scripts and commands for managing a chia farm.

## Get Launcher ID
### GUI
To get the pool launcher id, from the gui, go to Pooling -> press three dots on top right of nft card -> select "View Pool Login ID".  

### CLI
- First get the launcher id with `chia plotnft show`  
- Then get the login link with `chia plotnft get_login_link -l [launcher id]`  
- Or use this, ``LAUNCHER=`chia plotnft show | grep Launcher | awk '{print $3}' | sed -n '1p'` && chia plotnft get_login_link -l $LAUNCHER``  
- If you have multiple wallets, wait a second after pressing enter and press enter again. It'll pull the wallet that's currently synced. Modify '1p' to the number of the nft you want.  
