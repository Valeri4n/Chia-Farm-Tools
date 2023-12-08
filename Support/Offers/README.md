### Create Offers by CLI  
Question: How can I add 300 offers of 0.05 Chia each to each NFT separately with code or for the entire collection at once?  
```
You can write a script or simple loop command using cli. Help output below. You could use a csv file for input if you have something already, or generate it. Should be fairly straight forward.

There might be ways to then upload those offers. Easy if they have an API or commands that can be run. If they only have a web interface, you'll need to see how you might be able to auto populate those fields. Sometimes can be done through the URL, but often not. Have to test and see what works.

:~$ chia wallet make_offer -h
Usage: chia wallet make_offer [OPTIONS]

  Create an offer of XCH/CATs/NFTs for XCH/CATs/NFTs

Options:
  -wp, --wallet-rpc-port INTEGER  Set the port where the Wallet is hosting the
                                  RPC interface. See the rpc_port under wallet
                                  in config.yaml
  -f, --fingerprint INTEGER       Fingerprint of the wallet to use
  -o, --offer TEXT                A wallet id to offer and the amount to offer
                                  (formatted like wallet_id:amount)
                                  [required]
  -r, --request TEXT              A wallet id of an asset to receive and the
                                  amount you wish to receive (formatted like
                                  wallet_id:amount)  [required]
  -p, --filepath TEXT             The path to write the generated offer file
                                  to  [required]
  -m, --fee TEXT                  A fee to add to the offer when it gets
                                  taken, in XCH  [default: 0]
  --reuse                         Reuse existing address for the offer.
  -h, --help                      Show this message and exit.
```  
