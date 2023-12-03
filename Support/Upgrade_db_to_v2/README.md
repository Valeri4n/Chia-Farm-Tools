# Upgrade db to v2  
If when starting hte GUI the app constinues to spin and doesn't proceed, the problem is likely caused by using v1 of the db with a newer chia client version. The db must be upgraded to v2. There are several ways to do this:  
### Copy db from another chia client  
```
1. Stop the chia app on both the up to date client and the one to receive the db copy. Not performing this step will cause a corrupted db for both source and destination chia apps.
2. Copy the db from the source host to the destination host.
3. When completed, start the chia app on all hosts as needed.
```  
### Backup the db from another chia client  
The db may be produced by creating a backup from a chia client. Run the following command in CLI:  
```
chia db backup --backup_file <PATH>
```  
### Upgrade Using CLI  
One should have ~250GB of space to upgrade the db.  
```
1. Stop the chia client (this can be done while chia is running but stopping the client saves from any potential issues)
2. Run the command `chia db upgrade` (you do not need the input or output paths if these are still default)
- This process will take some time and requires additional space as the v1 db is compacted into the v2 db which leaves the v1 db intact
3. Verify the config file (~\.chia\mainnet\config\config.yaml) has the correct value under the full_node section for `database_path: db/blockchain_v2_CHALLENGE.sqlite` (should only need to change the v1 to v2)
4. After the above completes start the chia client
5. If all loads up properly (might take ~5-10 minutes to load) then you can safely delete the v1 db found here (~\.chia\mainnet\db\blockchain_v1_mainnet.sqlite)
```  
### Download Using the Torrent  
If using the torrent make sure to update the config file from v1 to v2:  
```
1. Download the torrent file from https://www.chia.net/downloads/#database-checkpoint
2. Use a torrent client to download the full db (qbittorrent, bittorrent, and others will work)
3. Unpack/reassemble the torrent file that was downloaded (Windows: 7zip, Mac and Linux: tar)
4. Move the db to the correct folder (~\.chia\mainnet\db\, \ for Windows, / for Linux) and update the name to "blockchain_v2_mainnet.sqlite" (remove the date information in the name)
5. Verify the config file (~\.chia\mainnet\config\config.yaml) has the correct value under the full_node section for `database_path: db/blockchain_v2_CHALLENGE.sqlite` (should only need to change the v1 to v2)
6. Launch chia and wait for the height to hash and peers files to be built, which can take upwards of 30 minutes.
```
