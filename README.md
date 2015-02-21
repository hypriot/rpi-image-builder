[![Build Status](https://builder.hypriot.com/api/badge/github.com/hypriot/rpi-image-builder/status.svg?branch=master)](https://builder.hypriot.com/github.com/hypriot/rpi-image-builder)

# rpi-image-builder

Build a SD card image for the Raspberry Pi 1 and 2.

## Build inputs


### Kernel deb packages

The five kernel deb packages are downloaded from S3 bucket `s3://buildserver-production/kernel/` to local `build_inputs/kernel/` directory.

* `libraspberrypi-bin_<date-time>_armhf.deb`
* `libraspberrypi-dev_<date-time>_armhf.deb`
* `libraspberrypi-doc_<date-time>_armhf.deb`
* `libraspberrypi0_<date-time>_armhf.deb`
* `raspberrypi-bootloader_<date-time>_armhf.deb`

### Docker deb package

The docker deb package is downloaded from S3 bucket `s3://buildserver-production/docker/deb/` to local `build_inputs/docker/deb/` directory.

* `docker-hypriot_1.5.0-<buildnumber>_armhf.deb`

## Build outputs

The final SD card image will be uploaded to S3 to `s3://buildserver-production/images/hypriot-date-time.img`.

## Build with Vagrant

To build the SD card image locally with Vagrant, enter

```bash
vagrant up
```

**FIX:** It is unclear to the author how AWS environments will be transported into the VM.

## Build with Drone

Add this GitHub repo to the Drone CI server. Then customize the project settings as follows.

### Enable Privileged mode

You have to enable privileged mode, because the image builder needs access to mount loop devices.

### Private Variables

The following variables have to be defined in the GUI of the Drone Buildserver.

* `RPI_IMAGE_BUILDER_ROOT: $DRONE_BUILD_DIR`

For uploading the build results to Amazon S3 we need the follwing Amazon S3 credentials

* `AWS_ACCESS_KEY_ID: your_aws_key`
* `AWS_SECRET_ACCESS_KEY: your_secret_access_key`
