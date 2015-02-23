# hypriot-pi serverspec tests

To test the SD card image for the Raspberry Pi use this Serverspec tests.

## Preparation

1. Flash the SD card image
2. Put the SD card into your Raspberry Pi
3. Power on the Raspberry Pi
4. Retrieve the host name or IP address to reach the Pi

## Bundle

```bash
bundle install --path vendor/bundle
bundle install --binstubs
```

## Run tests

Set the `TARGET_HOST` environment variable to the host name or
IP address of your Pi. The user name for the test is `root`.

```bash
TARGET_HOST=pi4 bin/rspec spec/hypriot-pi
```
