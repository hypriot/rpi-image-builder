!/bin/bash
set -ex

# set up error handling for cleaning up
# after having an error
handle_error() {
  echo "FAILED: line $1, exit code $2"
  echo "Killing remaining QEMU"
  killall qemu-system-arm
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

IMAGE_PATH="$(ls -1t ${BUILD_ENV}/images/${SETTINGS_PROFILE}-rpi-*.img | head -1)"

echo "###############"
echo "### Testing SD card image $IMAGE_PATH"

sudo apt-get install -y ruby

if [ -f $IMAGE_PATH ]; then
  # start HypriotOS in QEMU for five minutes
  QEMU_AUDIO_DRV=none timeout 5m qemu-system-arm -curses -kernel $BUILD_INPUTS/kernel/${KERNEL_DATETIME}/kernel-qemu \
    -cpu arm1176 -m 256 -M versatilepb -append \
    "root=/dev/sda2 rw vga=normal console=ttyAMA0,115200" -nographic \
    -hda ${IMAGE_PATH} -redir tcp:2222::22 &

  # wait until we can SSH into the HypriotOS in QEMU
  # TODO

  # run serverspec tests
  cd test
  bundle install
  PORT=2222 PI=localhost bin/rspec spec/hypriotos-image
fi
