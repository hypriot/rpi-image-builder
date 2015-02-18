# vim:ft=sh
#!/bin/bash

# get the most recent package information
# if the last update is more than 24h ago
if [ "$[$(date +%s) - $(stat -c %Z /var/lib/apt/periodic/update-success-stamp)]" -ge 86400 ]; then
  sudo apt-get update
fi

# needed by compile-kernel
for package in awscli build-essential libncurses5-dev tree binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools apt-cacher-ng; do
  sudo apt-get install -y $package
done
