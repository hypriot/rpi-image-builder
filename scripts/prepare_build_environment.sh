# vim:ft=sh
#!/bin/bash

# get the most recent package information
# if the last update is more than 24h ago
last_access=$(stat -c %Z /var/lib/apt/periodic/update-success-stamp)
last_access=${last_access:-0}

if [ "$[$(date +%s) - $last_access]" -ge 86400 ]; then
  sudo apt-get update
fi

# install packages needed for building the sd card image
for package in python-pip build-essential libncurses5-dev tree binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools apt-cacher-ng; do
  sudo apt-get install -y $package
done

# needed to fetch packages from s3
pip install awscli

# remove cached packages in /var/cache/apt/archives
apt-get clean
rm -rf /var/lib/apt/lists/*

