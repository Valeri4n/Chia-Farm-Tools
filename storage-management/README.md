#### get_drive_serials.sh  
captures the current storage array for each drive label, size, name, mountpoint, and serial number for future comparison for automatic failure detection. If label includes physical location, it will make locating failed drives easier. Once the drive fails in the system, this information may no longer be available. This script will preserve that information.  
#### Auto Add fstab Entries  
`for i in {"",{a..z}}; do for j in {a..z}; do echo "/dev/sd$i$j /mnt/sd$i$j auto defaults,nofail 0 0" >> /etc/fstab; done; done`
