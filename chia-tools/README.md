### Get pool stats
Use whichever of these displays properly. Should display as follows:  
  Number of plots:  
  Current pool URL:  
  Current difficulty:  
  Points balance:  
  Points found (24h):  
  Percent Successful Points (sh4):  
`watch -n 20 "echo|chia plotnft show|sed -n -e '12p;15,19p'|sed -n 'h;n;G;p;n;p;n;p;n;p;n;p'"`  
`watch -n 20 "echo|chia plotnft show|sed -n -e '8p;11,15p'|sed -n 'h;n;G;p;n;p;n;p;n;p;n;p'"`  

### wallet_check.sh  
This script will get current chia price and wallet for current value. To run continuously, use watch:  
`watch -n 60 ./wallet_check.sh`  

