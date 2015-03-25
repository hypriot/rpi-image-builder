#!/bin/bash
# Flash Raspberry Pi SD card images on your Mac
# Stefan Scherer - scherer_stefan@icloud.com
# MIT License


usage()
{
cat << EOF
usage: $0 [options] name-of-rpi.img

Flash a local or remote Raspberry Pi SD card image.

OPTIONS:
   --help|-h      Show this message
   --config|-c    Copy this config file to /boot/occidentalis.txt
   --hostname|-n  Set hostname for this SD image
   --ssid|-s      Set WiFi SSID for this SD image
   --password|-p  Set WiFI password for this SD image

The config file occidentalis.txt should look like

# hostname for your Hypriot Raspberry Pi:
hostname = hypriot-pi

# basic wireless networking options:
wifi_ssid = SSID
wifi_password = 12345
EOF
exit 1
}

# translate long options to short
for arg
do
    delim=""
    case "$arg" in
       --help) args="${args}-h ";;
       --verbose) args="${args}-v ";;
       --config) args="${args}-c ";;
       --hostname) args="${args}-n ";;
       --ssid) args="${args}-s ";;
       --password) args="${args}-p ";;
       # pass through anything else
       *) [[ "${arg:0:1}" == "-" ]] || delim="\""
           args="${args}${delim}${arg}${delim} ";;
    esac
done
# reset the translated args
eval set -- $args
# now we can process with getopt
while getopts ":hc:n:s:p:" opt; do
    case $opt in
        h)  usage ;;
        c)  OCCI_CONFIG=$OPTARG ;;
        n)  SD_HOSTNAME=$OPTARG ;;
        s)  WIFI_SSID=$OPTARG ;;
        p)  WIFI_PASSWORD=$OPTARG ;;
        \?) usage ;;
        :)
        echo "option -$OPTARG requires an argument"
        usage
        ;;
    esac
done
shift $((OPTIND -1))

#echo "remaining args"
#echo $*

#echo "CONFIG = $CONFIG"
#echo "SD_HOSTNAME = $SD_HOSTNAME"
#echo "WIFI_SSID = $WIFI_SSID"
#echo "WIFI_PASSWORD = $WIFI_PASSWORD"

beginswith() { case $2 in $1*) true;; *) false;; esac; }
endswith() { case $2 in *$1) true;; *) false;; esac; }

image=$1

occi=$2

if [ "$1" == "--help" ]; then
  usage
fi

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
  # this sudo here is used for a login without pv's progress bar
  # hiding the password prompt
  size=`sudo stat -f %z $image`
  cat $image | pv -s $size | sudo dd bs=1m of=/dev/r${disk}
else
  echo "No `pv` command found, so no progress available."
  echo "Press CTRL+T if you want to see the current info of dd command."
  sudo dd bs=1m if=$image of=/dev/r${disk}
fi

boot=$(df | grep /dev/${disk}s1 | sed 's,.*/Volumes,/Volumes,')
if [ "$boot" == "" ]; then
  while [ "$boot" == "" ]; do
    sleep 1
    boot=$(df | grep /dev/${disk}s1 | sed 's,.*/Volumes,/Volumes,')
  done
fi

if [ -f "$OCCI_CONFIG" ]; then
  echo "Copying $OCCI_CONFIG to ${boot}/occidentalis.txt ..."
  cp "$OCCI_CONFIG"  "${boot}/occidentalis.txt"
fi

if [ ! -z $SD_HOSTNAME ]; then
  echo "Set hostname = $SD_HOSTNAME"
  sed -i -e "s/.*hostname.*=.*\$/hostname = $SD_HOSTNAME/" "${boot}/occidentalis.txt"
fi
if [ ! -z $WIFI_SSID ]; then
  echo "Set wifi_ssid = $WIFI_SSID"
  sed -i -e "s/.*wifi_ssid.*=.*\$/wifi_ssid = $WIFI_SSID/" "${boot}/occidentalis.txt"
fi
if [ ! -z $WIFI_PASSWORD ]; then
  echo "Set wifi_password = $WIFI_PASSWORD"
  sed -i -e "s/.*wifi_password.*=.*\$/wifi_password = $WIFI_PASSWORD/" "${boot}/occidentalis.txt"
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
