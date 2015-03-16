#!/bin/bash
set -e

function usage {
  echo "Usage: $0 name-of-rpi.img"
  exit 1
}

if [ "$1" == "" ]; then
  usage
fi
if [ "$1" == "--help" ]; then
  usage
fi

if [ ! -f $1 ]; then
  echo "Usage: $0 raspberry-sd-image"
  exit 1
fi

echo "Mounting $0 ..."
sudo kpartx -v -a $1
sudo mkdir -p /mnt/pi-root
sudo mkdir -p /mnt/pi-boot
sudo mount -o rw -t ext4 /dev/mapper/loop0p2 /mnt/pi-root/
sudo mount -o rw -t vfat /dev/mapper/loop0p1 /mnt/pi-boot/
echo "You can find the Rasperry partitions at"
echo "    /mnt/pi-boot"
echo "    /mnt/pi-root"
