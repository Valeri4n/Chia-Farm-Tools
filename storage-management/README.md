## Scripts  
### fix_drives.sh  
This script will unmount, run fsck, and mount drives with errors shown in dmesg.  
### format_drive.sh  
If you have a lot of drives with names spread out, a quick and easy way to format them is with the command below.  
  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>16.4T is a common lsblk size for 18TB drives. In this example, 16.4T is the size of all the drives being formatted.</sup>  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <sup>If your drives vary in size, another option could be to use `" sd"` instead of `"16.4T "`.</sup>  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <sup>The space inside the quotes is important in how lsblk outputs data in columns when using grep.</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>/mnt is the root directory where your drives are mounted.</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>ext4 is the filesystem type. don't format if this exists.</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>$USER will pull username from system. Replace with other username if needed.</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>$drive is autopopulated and should not be changed.</sup>  
&nbsp;&nbsp;&nbsp;&nbsp; <sup>SomeName is used as a pointer file for the farmer/contract used for plot management.</sup>  
`lsblk -o name,size,type,mountpoint|grep "disk.*16.4T "|grep -v -e /mnt -e ext4 -e xfs -e ntfs -e btrfs|awk '{print $1}'|while read drive; do ./format_drive.sh -u $USER -d $drive -n SomeName -t ext4; done`  
### get_drive_storage_config.sh  
Captures the current storage array for each drive label, size, name, mountpoint, and serial number for future comparison for automatic failure detection. If label includes physical location, it will make locating failed drives easier. Once the drive fails in the system, this information may no longer be available. This script will preserve that information.  
### plot_mover.sh  
This script will handle the faster cuda plots going to a cache drive and you can run as many instances of the script as you need to move the plots to the farm faster. You'll want to architect your system/network in a manner to take advantage of the distributed transfer speeds needed. A 10 gbps network link would do, or multiple 1 or 2.5 gbps links, etc., depending on the speed of your plotter. This script is optimized for automatic plotting to fill multiple HDDs at the same time, so you'll want to have at least one HDD with space for each instance of the script you run.  
### plot_purge.sh  
Use this script when replacing plots with new compressed plots. This will delete old plots as new ones are plotted. This allows for maintaining the farm at full capacity and deleting only plots needed to make room as new ones are created, optimizing rewards. This script uses the nft-marking system to only replace plots with the same farmer and contract keys as the new plots. This is useful in a mixed farm with different keys. Happy plotting!  
## Commands  
### Create Directories 
Change ownership of /mnt so can add directories as user  
`chown -R $USER /mnt; chgrp -R $USER /mnt`  
  
Make directories  
`for i in {"",{a..z}}; do for j in {a..z}; do sudo mkdir /mnt/sd$i$j; done; done; sudo chown -R $USER: /mnt`
### Auto Add fstab Entries  
`type=ext4; for i in {"",{a..z}}; do for j in {a..z}; do echo "/dev/sd$i$j /mnt/sd$i$j $type defaults,nofail 0 0"|sudo tee -a /etc/fstab; done; done`  
  
I have found the `nofail` option to be an important addition in ubuntu if there is potential for a drive to not be present when booting. Sometimes ubuntu will boot into recovery mode until the offending fstab entry is removed if a drive isn't present. Adding `nofail` prevents this and allows normal booting, in my experience.  
### Auto Add Chia Plot Directories  
`server=/mnt; for i in {"",{a..z}}; do for j in {a..z}; do echo "${server}/sd$i$j added to chia plots config.yaml file"; chia plots add -d ${server}/sd$i$j; done; done`  
  
Change ${server} to your specific location or type in `server=[location]` prior to running the command above, specifying [location]. This can be local drive mounts or mounted network shares.  
  
If needing a third layer of drive names, below shows modification of the i loop with an "a" layer added, example: sd<ins>a</ins>fg  
  
`for i in {"",{a..z},a{a..z}}; ...`  
