#!/bin/bash
RPI_IMAGE_BUILDER_ROOT=${RPI_IMAGE_BUILDER_ROOT:="/vagrant"}
BUILD_INPUTS=$RPI_IMAGE_BUILDER_ROOT/build_inputs

# provide the name of the packages that should be fetched here
KERNEL_PACKAGES="kernel/libraspberrypi-bin_20150218-231723_armhf.deb kernel/libraspberrypi-dev_20150218-231723_armhf.deb kernel/libraspberrypi-doc_20150218-231723_armhf.deb kernel/libraspberrypi0_20150218-231723_armhf.deb kernel/raspberrypi-bootloader_20150218-231723_armhf.deb"
DOCERK_PACKAGES="docker/deb/docker_1.5.0hypriot-1_armhf.deb"
PACKAGES="$KERNEL_PACKAGES $DOCERK_PACKAGES"

# ensure that the target directories exist
mkdir -p $BUILD_INPUTS/kernel
mkdir -p $BUILD_INPUTS/docker

# fetch packages and drop them into our target directory
for pkg in $PACKAGES; do
  if [ ! -f $BUILD_INPUTS/$pkg ]; then
    AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY aws s3 --region eu-central-1 cp s3://buildserver-production/$pkg $BUILD_INPUTS/$(basename "$pkg")
  fi
done
