# XCH Transfer Issues  
### XCH Not Showing in Wallet  
Verify wallet is synced. Try recyncing through the gui or deleting the db at .chia/mainnet/wallet/bd/  
If still not showing: from Discord - Chia Network - Support on 12/5/2023:  
```
clydewallace22
 — 
Use the xch address to which the funds were sent and verify the keyset being used has access to it. To do this, follow the steps here:
https://docs.chia.net/faq/#how-can-i-sign-and-verify-a-message-with-an-nft

Those instructions show signing with an NFT. To test, use the Wallet Address tab and the xch address to which the funds were sent. 

If the verify message part of the process yields Valid then investigate why those funds are not showing but if the process does not yield a valid signature then need to determine where that xch address originated.
```  
