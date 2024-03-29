#!/bin/bash

function usage {
  echo "Usage: $0 name-of-rpi.img"
  exit 1
}

beginswith() { case $2 in $1*) true;; *) false;; esac; }
endswith() { case $2 in *$1) true;; *) false;; esac; }

if [ "$1" == "" ]; then
  usage
fi
if [ "$1" == "--help" ]; then
  usage
fi

image=$1

if beginswith http:// "$image"; then
  echo "Downloading $image ..."
  curl -L -o /tmp/image.img.zip "$image"
  image=/tmp/image.img.zip
fi

if beginswith s3:// "$image"; then
  echo "Downloading $image ..."
  aws s3 cp "$image" /tmp/image.img.zip
  image=/tmp/image.img.zip
fi

if [ ! -f "$image" ]; then
  echo "File not found."
  exit 10
fi

if endswith .zip "$image"; then
  echo "Uncompressing $image ..."
  unzip -o "$image" -d /tmp
  image=$(unzip -l "$image" | grep -v Archive: | grep img | cut -c 30-)
  image="/tmp/$image"
  echo "Use $image"
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
echo "Flashing $image to ${disk} ..."
pv=`which pv 2>/dev/null`
if [ $? -eq 0 ]; then
  size=`stat -f %z $image`
  cat $image | pv -s $size | sudo dd bs=1m of=/dev/r${disk}
else
  echo "No `pv` command found, so no progress available."
  echo "Press CTRL+T if you want to see the current info of dd command."
  sudo dd bs=1m if=$image of=/dev/r${disk}
fi
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
