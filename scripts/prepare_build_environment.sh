# vim:ft=sh
#!/bin/bash

# get the most recent package information
# if the last update is more than 24h ago
last_access=$(stat -c %Z /var/lib/apt/periodic/update-success-stamp)
last_access=${last_access:-0}

if [ "$[$(date +%s) - $last_access]" -ge 86400 ]; then
  sudo apt-get update
fi

# setup apt-fast for parallel downloads
sudo apt-get install software-properties-common python-software-properties
sudo add-apt-repository ppa:saiarcot895/myppa
sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt-get -y install apt-fast
alias apt-get='apt-fast'

# install packages needed for building the sd card image
for package in python-pip build-essential libncurses5-dev tree binfmt-support infmt_misc qemu qemu-user-static debootstrap kpartx lvm2 dosfstools apt-cacher-ng; do
  sudo apt-get install -y $package
done

# needed to fetch packages from s3
pip install awscli

# remove cached packages in /var/cache/apt/archives
apt-get clean
rm -rf /var/lib/apt/lists/*

