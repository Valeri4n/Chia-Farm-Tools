# Install commands for ubuntu  
Install items as needed
## Resize ubuntu root drive to max space  
```
name=$(df -h /home|sed -n 2p|awk '{print $1}')
sudo lvextend -l +100%FREE $name
sudo resize $name
echo
tput setaf 3
df -h /home
echo
tput sgr0
```  

## Install chia-blockchain-cli  
If installing gui, remove `-cli` from the end  
Replace `<<<your timezone>>>` with your timezone. Get list with `timedatectl list-timezones`  
Replace `<<<samba username>>>` with your own  
```
sudo timedatectl set-timezone <<<your timezone>>>
sudo apt update
sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg samba cifs-utils smartmontools linux-image-generic-hwe-22.04
sudo smbpasswd -a <<<samba username>>>
curl -sL https://repo.chia.net/FD39E6D3.pubkey.asc | sudo gpg --dearmor -o /usr/share/keyrings/chia.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/chia.gpg] https://repo.chia.net/debian/ stable main" | \
  sudo tee /etc/apt/sources.list.d/chia.list > /dev/null
sudo apt update
sudo apt install -y chia-blockchain-cli
```  

## Uninstall cuda and nvidia  
Sometimes this step is needed if nvidia-smi or plotting isn't performing properly. Best to wipe it and start with fresh cusa install.  
```
sudo apt remove --purge nvidia* cuda-{c,d,g,l,n,o,p,s,t,v}* -y
```  

## Install cuda and nvidia  
Change distribution (distro) and architecture (arch) as needed  
```
sudo apt install linux-headers-$(uname -r)
distro=ubuntu2204
arch=x86_64
wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-archive-keyring.gpg
sudo mv cuda-archive-keyring.gpg /usr/share/keyrings/cuda-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/ /" | \
  sudo tee /etc/apt/sources.list.d/cuda-$distro-$arch.list
wget https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-$distro.pin
sudo mv cuda-$distro.pin /etc/apt/preferences.d/cuda-repository-pin-600
sudo apt update
sudo apt install -y cuda
sudo apt install -y nvidia-gds
sudo apt autoremove -y
sudo reboot
```  
