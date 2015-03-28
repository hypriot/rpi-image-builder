[![Build Status](https://builder.hypriot.com/api/badge/github.com/hypriot/rpi-image-builder/status.svg?branch=master)](https://builder.hypriot.com/github.com/hypriot/rpi-image-builder)

# rpi-image-builder

Build a SD card image for the Raspberry Pi 1 and 2.

## Build inputs


### Kernel deb packages

The five kernel deb packages are downloaded from S3 bucket `s3://buildserver-production/kernel/<datetime>` to local `build_inputs/kernel/<datetime>` directory.

* `libraspberrypi-bin_<date-time>_armhf.deb`
* `libraspberrypi-dev_<date-time>_armhf.deb`
* `libraspberrypi-doc_<date-time>_armhf.deb`
* `libraspberrypi0_<date-time>_armhf.deb`
* `raspberrypi-bootloader_<date-time>_armhf.deb`
* `linux-headers-3.18.7-hypriotos+_3.18.7-hypriotos+-1_armhf.deb`
* `linux-headers-3.18.7-hypriotos-v7+_3.18.7-hypriotos-v7+-2_armhf.deb`

### Docker deb package

The docker deb package is downloaded from S3 bucket `s3://buildserver-production/docker/deb/` to local `build_inputs/docker/deb/` directory.

* `docker-hypriot_1.5.0-<buildnumber>_armhf.deb`

### config.sh

The file `scripts/config.sh` contains the major configuration of the SD image.

```bash
#!/bin/bash

# configuration for all build scripts
KERNEL_DATETIME=${KERNEL_DATETIME:="20150321-232854"}
KERNEL_VERSION=${KERNEL_VERSION:="3.18.9"}
DOCKER_DEB=${DOCKER_DEB:="docker-hypriot_1.5.0-7_armhf.deb"}

SETTINGS_PROFILE="hypriot"

SD_CARD_SIZE="1280"        # "1280" = 1.3 GB
BOOT_PARTITION_SIZE="64"   # "64" = 64 MB

DEB_RELEASE="wheezy"       # jessie | wheezy | squeeze

APT_PACKAGES="ntpdate
              fake-hwclock
              occi
              avahi-daemon
              ...
              vim"
```

## Build outputs

The final SD card image will be uploaded to S3 to `s3://buildserver-production/images/hypriot-date-time.img`.

## Build with Vagrant

To build the SD card image locally with Vagrant, enter

```bash
vagrant up
```

### Analyze the SD card image

In the vagrant box you can mount and unmount the SD card image with two helper scripts

```bash
vagrant ssh
/vagrant/scripts/mount-sd-image.sh /build_env/images/hypriot*.img
```

The two partitions are mounted to `/mnt/pi-boot` and `mnt/pi-root` where you can modify things.
Afterwards unmount everything with

```bash
/vagrant/scripts/unmount-sd-image.sh /build_env/images/hypriot*.img
```

Your changes are written into the SD card image file.

### Test the latest SD build

```bash
vagrant ssh
sudo su
/vagrant/scripts/test_image.sh
```

### Rebuild with Vagrant

To rebuild another SD image just reboot the VM, so that any mountpoints and tmp file system removed.

```bash
vagrant reload
vagrant ssh -c "sudo /vagrant/scripts/build_image.sh"
```

## Build with Drone

Add this GitHub repo to the Drone CI server. Then customize the project settings as follows.

### Enable Privileged mode

You have to enable privileged mode, because the image builder needs access to mount loop devices.

### Private Variables

The following variables have to be defined in the GUI of the Drone Buildserver.

* `RPI_IMAGE_BUILDER_ROOT: $DRONE_BUILD_DIR`
* `BUILD_INPUTS: /tmp/cache/build_inputs`

For uploading the build results to Amazon S3 we need the following Amazon S3 credentials.

* `AWS_ACCESS_KEY_ID: your_aws_key`
* `AWS_SECRET_ACCESS_KEY: your_secret_access_key`

### Problems with loop devices
If you encounter error messages related to loop devices it is most probably a problem
with loop devices which haven not been released during the image building process.

To fix this manually use the following command on the build host:

```
for loop_device in $(losetup -a | awk '{print $1};' | sed "s/:$//"); do losetup -d $loop_device; done
```
