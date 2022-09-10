## Scripts  
### fix_drives.sh  
This script will unmount, run fsck, and mount drives with errors shown in dmesg.
### get_drive_storage_config.sh  
Captures the current storage array for each drive label, size, name, mountpoint, and serial number for future comparison for automatic failure detection. If label includes physical location, it will make locating failed drives easier. Once the drive fails in the system, this information may no longer be available. This script will preserve that information.  
## Commands  
### Auto Add fstab Entries  
Run as sudo  
`for i in {"",{a..z}}; do for j in {a..z}; do echo "/dev/sd$i$j /mnt/sd$i$j auto defaults,nofail 0 0" >> /etc/fstab; done; done`  
I have found the `nofail` option to be an important addition in ubuntu if there is potential for a drive to not be present when booting. Sometimes ubuntu will boot into emergency mode until the offending fstab entry is removed if a drive isn't present. Adding `nofail` prevents this and allows normal booting, in my experience.  
### Auto Add Chia Plot Directories  
Change ${server} to your specific location or type in `server=[location]` prior to running the command below, specifying the [location]. This can be local drive mounts or mounted network shares.  
`for i in {"",{a..z}}; do for j in {a..z}; do echo "${server}/sd$i$j added to chia plots config.yaml file"; chia plots add -d ${server}/sd$i$j; done; done`  
