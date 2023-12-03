# Chia Help Output  
### Claim Rewards (for self-pooling)  
```
:~$ chia plotnft claim -h
Usage: chia plotnft claim [OPTIONS]

  Claim rewards from a plot NFT

Options:
  -i, --id INTEGER                ID of the wallet to use  [required]
  -f, --fingerprint INTEGER       Fingerprint of the wallet to use
  -m, --fee TEXT                  Set the fees per transaction, in XCH.
                                  [default: 0; required]
  -wp, --wallet-rpc-port INTEGER  Set the port where the Wallet is hosting the
                                  RPC interface. See the rpc_port under wallet
                                  in config.yaml
  -h, --help                      Show this message and exit.
```  
## Plotting  
### Bladebit Cudaplot (stand alone version 3.1.0)  
```
:~$ ./bladebit_cuda help cudaplot
bladebit_cuda ... cudaplot <out_dir>

GPU-based (CUDA) plotter

[OPTIONS]:
 -h, --help           : Shows this help message and exits.
 -d, --device         : Select the CUDA device index. (default=0)

 --disk-128           : Enable hybrid disk plotting for 128G system RAM. 
                         Requires a --temp1 and --temp2 to be set.

 --disk-16            : (experimental) Enable hybrid disk plotting for 16G system RAM. 
                         Requires a --temp1 and --temp2 to be set.

 -t1, --temp1         : Temporary directory 1. Used for longer-lived, sequential writes.

 -t2, --temp2         : Temporary directory 2. Used for temporary, shorted-lived read and writes.
                         NOTE: If only one of -t1 or -t2 is specified, both will be
                               set to the same directory.

 --check <n>          : Perform a plot check for <n> proofs on the newly created plot.

 --check-threshold <f>: Proof threshold rate below which the plots that don't pass
                         the check will be deleted.
                         That is, the number of proofs fetched / proof check count
                         must be above or equal to this threshold to pass.
                         (default=0.6).
```
### Check Plots  
```
:~$ chia plots check -h
Usage: chia plots check [OPTIONS]

  Checks plots

Options:
  -n, --num INTEGER          Number of plots or challenges
  -g, --grep_string TEXT     Shows only plots that contain the string in the
                             filename or directory name
  -l, --list_duplicates      List plots with duplicate IDs
  --debug-show-memo          Shows memo to recreate the same exact plot
  --challenge-start INTEGER  Begins at a different [start] for -n [challenges]
  -h, --help                 Show this message and exit.
```
