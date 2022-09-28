Get duplicates  
`chia rpc farmer get_harvesters | jq -r '.harvesters[].duplicates[]' | sed 's/plot-/: plot-/g' | cut -d ':' -f2 | sort | uniq -c`  
  
Get failed to open  
`chia rpc farmer get_harvesters | jq -r '.harvesters[].failed_to_open_filenames[]'`  
  
Get no keys    
`chia rpc farmer get_harvesters | jq -r '.harvesters[].no_key_filenames[]'`  
