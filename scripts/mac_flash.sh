#!/bin/bash

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

if [ ! -f "$1" ]; then
  echo "File not found."
  exit 10
fi

if [[ "$OSTYPE" != "darwin"*  ]]; then
  echo "Only Mac OSX supported"
  exit 11
fi

# try to find the correct disk of the inserted SD card
disk=`df | grep -e "disk[0-9]s1" | grep Volumes | cut -c 6-10`
if [ "$disk" == "" ]; then
  echo "No SD card found. Please insert SD card, I'll wait for it..."
  while [ "$disk" == "" ]; do
    sleep 1
    disk=`df | grep -e "disk[0-9]s1" | grep Volumes | cut -c 6-10`
  done
fi

df
while true; do
  echo ""
  read -p "Is /dev/${disk}s1 correct? " yn
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

echo "Unmounting ${disk} ..."
diskutil unmountDisk /dev/${disk}s1
diskutil unmountDisk /dev/${disk}
echo "Flashing $1 to ${disk} ..."
echo "Press CTRL+T if you want to see the current info of dd command."
sudo dd bs=1m if=$1 of=/dev/r${disk}
echo "Unmounting and ejecting ${disk} ..."
sleep 1
diskutil unmountDisk /dev/${disk}s1
diskutil unmountDisk /dev/${disk}s2
diskutil eject /dev/${disk}
if [ $? -eq 0 ]; then
  afplay /System/Library/Sounds/Bottle.aiff
  echo "🍺  Finished."
else
  afplay /System/Library/Sounds/Basso.aiff
  echo "👎  Someting went wrong."
fi
