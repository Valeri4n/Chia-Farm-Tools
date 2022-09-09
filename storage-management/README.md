## Scripts  
### fix_drives.sh  
This script will unmount, run fsck, and mount drives with errors shown in dmesg.
### get_drive_storage_config.sh  
Captures the current storage array for each drive label, size, name, mountpoint, and serial number for future comparison for automatic failure detection. If label includes physical location, it will make locating failed drives easier. Once the drive fails in the system, this information may no longer be available. This script will preserve that information.  
## Commands  
### Auto Add fstab Entries  
Run as sudo  
`for i in {"",{a..z}}; do for j in {a..z}; do echo "/dev/sd$i$j /mnt/sd$i$j auto defaults,nofail 0 0" >> /etc/fstab; done; done`
### Auto Add Chia Plot Directories  
`for i in {0,{a..z}}; do skip=0; if [ $i = "0" ]; then skip=1; fi; for j in {a..z}; do if [ $((skip)) -eq 1 ]; then i=$j; j=""; fi; echo "/svr/34-630/sd$i$j added to chia plots config.yaml file"; chia plots add -d /svr/34-630/sd$i$j; done; done`
