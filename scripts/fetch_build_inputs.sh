#!/bin/bash
RPI_IMAGE_BUILDER_ROOT=${RPI_IMAGE_BUILDER_ROOT:="/vagrant"}
BUILD_INPUTS=$RPI_IMAGE_BUILDER_ROOT/build_inputs

# provide the name of the packages that should be fetched here
KERNEL_PACKAGES="kernel/libraspberrypi-bin_20150221-190136_armhf.deb kernel/libraspberrypi-dev_20150221-190136_armhf.deb kernel/libraspberrypi-doc_20150221-190136_armhf.deb kernel/libraspberrypi0_20150221-190136_armhf.deb kernel/raspberrypi-bootloader_20150221-190136_armhf.deb"
DOCKER_PACKAGES="docker/deb/docker-hypriot_1.5.0-7_armhf.deb"
PACKAGES="$KERNEL_PACKAGES $DOCKER_PACKAGES"

# ensure that the target directories exist
mkdir -p $BUILD_INPUTS/kernel
mkdir -p $BUILD_INPUTS/docker

# fetch packages and drop them into our target directory
for pkg in $PACKAGES; do
  if [ ! -f $BUILD_INPUTS/$pkg ]; then
    aws s3 --region eu-central-1 cp s3://buildserver-production/$pkg $BUILD_INPUTS/$pkg
  fi
done
