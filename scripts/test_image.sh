#!/bin/bash
set -ex

# set up error handling for cleaning up
# after having an error
handle_error() {
  echo "### FAILED: line $1, exit code $2"
  echo "### Killing remaining QEMU"
  killall qemu-system-arm
  echo "### Removing SD image"
  rm -f *.img
  exit 1
}

trap 'handle_error $LINENO $?' ERR

# set up some variables for the script
export LC_ALL="C"
RPI_IMAGE_BUILDER_ROOT=${RPI_IMAGE_BUILDER_ROOT:="/vagrant"}
BUILD_ENV=${BUILD_ENV:="/build_env"}
BUILD_RESULTS=${BUILD_RESULTS:="$RPI_IMAGE_BUILDER_ROOT/build_results"}
BUILD_INPUTS=${BUILD_INPUTS:="$RPI_IMAGE_BUILDER_ROOT/build_inputs"}

# read configuration
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. ${DIR}/config.sh

ZIP_IMAGE_PATH="$(ls -1t ${BUILD_ENV}/images/${SETTINGS_PROFILE}-rpi-*.img.zip | head -1)"
IMAGE="$(basename -s .zip $ZIP_IMAGE_PATH)"

echo "###############"
echo "### Testing SD card image $IMAGE_PATH"
echo "### pwd ..."
pwd

if [ -f $ZIP_IMAGE_PATH ]; then
  # run serverspec tests
  echo "### installing serverspec"
  cd ${RPI_IMAGE_BUILDER_ROOT}/test
  bundle install

  echo "### Extracting $ZIP_IMAGE_PATH"
  unzip -o $ZIP_IMAGE_PATH

  # start HypriotOS in QEMU for five minutes
  QEMU_AUDIO_DRV=none timeout 5m qemu-system-arm -curses -kernel $BUILD_INPUTS/kernel/${KERNEL_DATETIME}/kernel-qemu \
    -cpu arm1176 -m 256 -M versatilepb -append \
    "root=/dev/sda2 rw vga=normal console=ttyAMA0,115200" -nographic \
    -hda ${IMAGE} -redir tcp:2222::22 &

  # wait until we can SSH into the HypriotOS in QEMU
  echo "### Waiting for QEMU RPi to boot"
  if [ ! -e /dev/pts ]; then
    sleep 150
  else
    COUNTER=1
    while [ "$COUNTER" -le "150" ] ; do
      sshpass -p hypriot ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 root@localhost exit 0 && break
      sleep 1
      COUNTER=$[$COUNTER +1]
    done
  fi
  sleep 30

  # run serverspec tests
  echo "### Running serverspec tests"
  PORT=2222 PI=localhost ${RPI_IMAGE_BUILDER_ROOT}/test/bin/rspec ${RPI_IMAGE_BUILDER_ROOT}/test/spec/hypriotos-image

  echo "### Stopping QEMU RPi"
  killall qemu-system-arm

  echo "### Removing Image"
  rm -f *.img
fi
