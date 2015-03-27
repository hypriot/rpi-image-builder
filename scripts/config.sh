#!/bin/bash

# configuration for all build scripts
KERNEL_DATETIME=${KERNEL_DATETIME:="20150321-232854"}
KERNEL_VERSION=${KERNEL_VERSION:="3.18.9"}
DOCKER_DEB=${DOCKER_DEB:="docker-hypriot_1.5.0-7_armhf.deb"}

SETTINGS_PROFILE="hypriot"

SD_CARD_SIZE="1024"        # "1280" = 1.3 GB
BOOT_PARTITION_SIZE="64"   # "64" = 64 MB

DEB_RELEASE="wheezy"       # jessie | wheezy | squeeze

APT_PACKAGES="ntpdate
              fake-hwclock
              occi
              avahi-daemon
              usbutils
              bash-completion
              locales
              console-common
              openssh-server
              ntp
              less
              lua5.1
              triggerhappy
              dmsetup
              rng-tools
              sudo
              htop
              parted
              vim"
