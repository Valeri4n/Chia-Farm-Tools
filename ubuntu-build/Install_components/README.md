To Install, run these files in order.  

&nbsp;&nbsp;&nbsp;&nbsp; <sup>1-maximize_drivespace.sh</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>2-install_apps.sh</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>3-install_headers.sh</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>4-install_cuda.sh</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>5-install_chia.sh</sup>  
  
Use the following command to download the files:  
```
wget https://raw.githubusercontent.com/Valeri4n/Chia-Farm-Tools/refs/heads/main/ubuntu-build/Install_components/1-maximize_drivespace.sh
wget https://raw.githubusercontent.com/Valeri4n/Chia-Farm-Tools/refs/heads/main/ubuntu-build/Install_components/2-install_apps.sh
wget https://raw.githubusercontent.com/Valeri4n/Chia-Farm-Tools/refs/heads/main/ubuntu-build/Install_components/3-install_headers.sh
wget https://raw.githubusercontent.com/Valeri4n/Chia-Farm-Tools/refs/heads/main/ubuntu-build/Install_components/4-install_cuda.sh
wget https://raw.githubusercontent.com/Valeri4n/Chia-Farm-Tools/refs/heads/main/ubuntu-build/Install_components/5-install_chia.sh
chmod +x 1-maximize_drivespace.sh
chmod +x 2-install_apps.sh
chmod +x 3-install_headers.sh
chmod +x 4-install_cuda.sh
chmod +x 5-install_chia.sh
sudo ./1-maximize_drivespace.sh
```

The last line will execute the first script. Run the others in order in the same way with sudo in front of it.
