#!/bin/bash
set -x
set -e
KERNEL_DATETIME=${KERNEL_DATETIME:="20150318-231448"}
RPI_IMAGE_BUILDER_ROOT=${RPI_IMAGE_BUILDER_ROOT:="/vagrant"}
BUILD_INPUTS=${BUILD_INPUTS:="/$RPI_IMAGE_BUILDER_ROOT/build_inputs"}

# provide the name of the packages that should be fetched here
KERNEL_PACKAGES="kernel/${KERNEL_DATETIME}/libraspberrypi-bin_${KERNEL_DATETIME}_armhf.deb \
                 kernel/${KERNEL_DATETIME}/libraspberrypi-dev_${KERNEL_DATETIME}_armhf.deb \
                 kernel/${KERNEL_DATETIME}/libraspberrypi-doc_${KERNEL_DATETIME}_armhf.deb \
                 kernel/${KERNEL_DATETIME}/libraspberrypi0_${KERNEL_DATETIME}_armhf.deb \
                 kernel/${KERNEL_DATETIME}/raspberrypi-bootloader_${KERNEL_DATETIME}_armhf.deb \
                 kernel/${KERNEL_DATETIME}/linux-headers-3.18.9-hypriotos+_3.18.9-hypriotos+-1_armhf.deb \
                 kernel/${KERNEL_DATETIME}/linux-headers-3.18.9-hypriotos-v7+_3.18.9-hypriotos-v7+-2_armhf.deb \
                 kernel/${KERNEL_DATETIME}/kernel-commit.txt"
DOCKER_PACKAGES="docker/deb/docker-hypriot_1.5.0-7_armhf.deb"
PACKAGES="$KERNEL_PACKAGES $DOCKER_PACKAGES"

# ensure that the target directories exist
mkdir -p $BUILD_INPUTS/kernel/${KERNEL_DATETIME}
mkdir -p $BUILD_INPUTS/docker/deb

# fetch packages and drop them into our target directory
for pkg in $PACKAGES; do
  if [ ! -f $BUILD_INPUTS/$pkg ]; then
    aws s3 --region eu-central-1 cp s3://buildserver-production/$pkg $BUILD_INPUTS/$pkg
  fi
done
