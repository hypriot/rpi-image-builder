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

echo "Unounting $0 ..."
sync

sudo umount /mnt/pi-root/
sudo umount /mnt/pi-boot/

sudo kpartx -vds $1

