###Get pool stats  
`echo|chia plotnft show|sed -n -e '12p;15,19p'|sed -n 'h;n;G;p;n;p;n;p;n;p;n;p'`  

###wallet_check.sh  
This script will get current chia price and wallet for current value. To run continuously, use watch:  
`watch -n 60 ./wallet_check.sh`  

