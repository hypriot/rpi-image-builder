# QEMU

Test the SD card image with qemu

```bash
curl -o kernel-qemu http://xecdesign.com/downloads/linux-qemu/kernel-qemu
QEMU_AUDIO_DRV=none qemu-system-arm -curses -kernel /home/vagrant/kernel-qemu -cpu arm1176 -m 256 -M versatilepb -append "root=/dev/sda2 rw vga=normal console=ttyAMA0,115200" -nographic -hda /home/vagrant/hypriot-rpi-20150301-140537.img -redir tcp:2222::22
```

This could be the essential diff:

```
> CONFIG_ARM_ERRATA_326103=y
> CONFIG_ARM_ERRATA_364296=y
> CONFIG_ARM_PATCH_PHYS_VIRT=y
> CONFIG_ARM_TIMER_SP804=y
> CONFIG_ARM_VIC=y
> CONFIG_OABI_COMPAT=y
> CONFIG_MIGHT_HAVE_PCI=y
```

From http://xecdesign.com/compiling-a-kernel/ and http://xecdesign.com/qemu-emulating-raspberry-pi-the-easy-way/

See also

* http://www.raspberry-pi-geek.de/Magazin/2014/04/Raspberry-Pi-emulieren
* http://www.cnx-software.com/2011/10/18/raspberry-pi-emulator-in-ubuntu-with-qemu/

Download a patch

```bash
cd /var/kernel_build/cache
wget http://xecdesign.com/downloads/linux-qemu/linux-arm.patch
patch -p1 -d linux-kernel/ < linux-arm.patch
```

The relevant part is to preconfigure the kernel config with

```bash
make ARCH=arm versatile_defconfig
make ARCH=arm menuconfig
```

This turns off many RPi specific hardware that QEMU can't emulate.

### More things learned

Cross compilation of a QEMU kernel seems to be better with the standard cross compiler,
so we install it inside the VM.

```
vagrant ssh
sudo su
apt-get install -y gcc-arm-linux-gnueabihf
cd /var/kernel_build/linux-kernel/
patch -p1 -d . < ../linux-arm.patch
make ARCH=arm versatile_defconfig
make ARCH=arm menuconfig
```

Add the kernel config as described in http://xecdesign.com/compiling-a-kernel/

We also set

* File Systems -> overlay
* File Systems -> msdos + vfat
* Network -> IPv6


Patch one of the kernel sources to compile with gcc 4.8.2

```
diff --git a/arch/arm/kernel/asm-offsets.c b/arch/arm/kernel/asm-offsets.c
index 2d2d608..75fd051 100644
--- a/arch/arm/kernel/asm-offsets.c
+++ b/arch/arm/kernel/asm-offsets.c
@@ -49,7 +49,7 @@
 #error Your compiler is too buggy; it is known to miscompile kernels.
 #error    Known good compilers: 3.3, 4.x
 #endif
-#if GCC_VERSION >= 40800 && GCC_VERSION < 40803
+#if GCC_VERSION >= 40800 && GCC_VERSION < 40802
 #error Your compiler is too buggy; it is known to miscompile kernels
 #error and result in filesystem corruption and oopses.
 #endif
```

Then compile the QEMU kernel with these command and copy the output to vagrant's shared folder.

```
make ARCH=arm -j8 -k
cp arch/arm/boot/zImage /vagrant/
```

Take this kernel to the rpi-image-builder VM

```
cp /vagrant/zImage /home/vagrant/
QEMU_AUDIO_DRV=none qemu-system-arm -curses -kernel /home/vagrant/zImage -cpu arm1176 -m 256 -M versatilepb -append "root=/dev/sda2 rw vga=normal console=ttyAMA0,115200" -nographic -hda /home/vagrant/hypriot-rpi-20150316-153452.img -redir tcp:2222::22
```

Log into QEMU

```
$ uname -a
Linux black-pearl 3.18.9-hypriotos+ #9 Tue Mar 17 17:24:54 UTC 2015 armv6l GNU/Linux
HypriotOS: root@black-pearl in ~
```


## Kernel config of kernel-qemu

```bash
$ zcat /proc/config.gz
```

Diffing with our real Hypriot kernel:

```bash
$ diff hypriot-v6-static.txt qemu-static.txt | grep ">"
> CONFIG_ARCH_VERSATILE_PB=y
> CONFIG_ARCH_VERSATILE=y
> CONFIG_ARCH_WANT_OPTIONAL_GPIOLIB=y
> CONFIG_ARM_ERRATA_326103=y
> CONFIG_ARM_ERRATA_364296=y
> CONFIG_ARM_PATCH_PHYS_VIRT=y
> CONFIG_ARM_TIMER_SP804=y
> CONFIG_ARM_VIC=y
> CONFIG_BLK_DEV_CRYPTOLOOP=y
> CONFIG_BLK_DEV_SR=y
> CONFIG_CLKSRC_MMIO=y
> CONFIG_COMPAT_BRK=y
> CONFIG_CPU_USE_DOMAINS=y
> CONFIG_CRAMFS=y
> CONFIG_CRYPTO_HW=y
> CONFIG_DEBUG_LL_UART_NONE=y
> CONFIG_DEBUG_LL=y
> CONFIG_DEBUG_USER=y
> CONFIG_DECOMPRESS_BZIP2=y
> CONFIG_DECOMPRESS_LZMA=y
> CONFIG_DECOMPRESS_LZO=y
> CONFIG_DECOMPRESS_XZ=y
> CONFIG_DEVKMEM=y
> CONFIG_DEVPORT=y
> CONFIG_EXT2_FS=y
> CONFIG_EXT3_DEFAULTS_TO_ORDERED=y
> CONFIG_EXT3_FS_XATTR=y
> CONFIG_EXT3_FS=y
> CONFIG_FB_ARMCLCD=y
> CONFIG_FPE_NWFPE=y
> CONFIG_FW_LOADER_USER_HELPER=y
> CONFIG_GENERIC_HARDIRQS=y
> CONFIG_HAS_IOPORT=y
> CONFIG_HAVE_GENERIC_HARDIRQS=y
> CONFIG_HAVE_IDE=y
> CONFIG_HAVE_MACH_CLKDEV=y
> CONFIG_HID_A4TECH=y
> CONFIG_HID_APPLE=y
> CONFIG_HID_BELKIN=y
> CONFIG_HID_CHERRY=y
> CONFIG_HID_CHICONY=y
> CONFIG_HID_CYPRESS=y
> CONFIG_HID_EZKEY=y
> CONFIG_HID_KENSINGTON=y
> CONFIG_HID_LOGITECH=y
> CONFIG_HID_MICROSOFT=y
> CONFIG_HID_MONTEREY=y
> CONFIG_HOTPLUG=y
> CONFIG_HZ_PERIODIC=y
> CONFIG_ICST=y
> CONFIG_INET_LRO=y
> CONFIG_INET_XFRM_MODE_BEET=y
> CONFIG_INET_XFRM_MODE_TRANSPORT=y
> CONFIG_INET_XFRM_MODE_TUNNEL=y
> CONFIG_INLINE_READ_UNLOCK_IRQ=y
> CONFIG_INLINE_READ_UNLOCK=y
> CONFIG_INLINE_SPIN_UNLOCK_IRQ=y
> CONFIG_INLINE_WRITE_UNLOCK_IRQ=y
> CONFIG_INLINE_WRITE_UNLOCK=y
> CONFIG_INPUT_EVDEV=y
> CONFIG_INPUT_KEYBOARD=y
> CONFIG_INPUT_MOUSEDEV_PSAUX=y
> CONFIG_INPUT_MOUSE=y
> CONFIG_IOMMU_SUPPORT=y
> CONFIG_IP_PNP_BOOTP=y
> CONFIG_JBD=y
> CONFIG_JFFS2_FS_WRITEBUFFER=y
> CONFIG_JFFS2_FS=y
> CONFIG_JFFS2_RTIME=y
> CONFIG_JFFS2_ZLIB=y
> CONFIG_KEYBOARD_ATKBD=y
> CONFIG_KTIME_SCALAR=y
> CONFIG_LEGACY_PTYS=y
> CONFIG_MACH_VERSATILE_AB=y
> CONFIG_MIGHT_HAVE_PCI=y
> CONFIG_MINIX_FS=y
> CONFIG_MOUSE_PS2_ALPS=y
> CONFIG_MOUSE_PS2_CYPRESS=y
> CONFIG_MOUSE_PS2_LOGIPS2PP=y
> CONFIG_MOUSE_PS2_SYNAPTICS=y
> CONFIG_MOUSE_PS2_TRACKPOINT=y
> CONFIG_MOUSE_PS2=y
> CONFIG_MTD_BLKDEVS=y
> CONFIG_MTD_BLOCK=y
> CONFIG_MTD_CFI_ADV_OPTIONS=y
> CONFIG_MTD_CFI_I1=y
> CONFIG_MTD_CFI_I2=y
> CONFIG_MTD_CFI_INTELEXT=y
> CONFIG_MTD_CFI_NOSWAP=y
> CONFIG_MTD_CFI_UTIL=y
> CONFIG_MTD_CFI=y
> CONFIG_MTD_CMDLINE_PARTS=y
> CONFIG_MTD_GEN_PROBE=y
> CONFIG_MTD_MAP_BANK_WIDTH_1=y
> CONFIG_MTD_MAP_BANK_WIDTH_2=y
> CONFIG_MTD_MAP_BANK_WIDTH_4=y
> CONFIG_MTD_PHYSMAP=y
> CONFIG_MTD=y
> CONFIG_MULTI_IRQ_HANDLER=y
> CONFIG_NET_PACKET_ENGINE=y
> CONFIG_NET_VENDOR_3COM=y
> CONFIG_NET_VENDOR_ADAPTEC=y
> CONFIG_NET_VENDOR_ALTEON=y
> CONFIG_NET_VENDOR_AMD=y
> CONFIG_NET_VENDOR_ATHEROS=y
> CONFIG_NET_VENDOR_BROCADE=y
> CONFIG_NET_VENDOR_CHELSIO=y
> CONFIG_NET_VENDOR_CISCO=y
> CONFIG_NET_VENDOR_DEC=y
> CONFIG_NET_VENDOR_DLINK=y
> CONFIG_NET_VENDOR_EMULEX=y
> CONFIG_NET_VENDOR_EXAR=y
> CONFIG_NET_VENDOR_HP=y
> CONFIG_NET_VENDOR_MELLANOX=y
> CONFIG_NET_VENDOR_MYRI=y
> CONFIG_NET_VENDOR_NVIDIA=y
> CONFIG_NET_VENDOR_OKI=y
> CONFIG_NET_VENDOR_QLOGIC=y
> CONFIG_NET_VENDOR_RDC=y
> CONFIG_NET_VENDOR_REALTEK=y
> CONFIG_NET_VENDOR_SILAN=y
> CONFIG_NET_VENDOR_SIS=y
> CONFIG_NET_VENDOR_SUN=y
> CONFIG_NET_VENDOR_TEHUTI=y
> CONFIG_NET_VENDOR_TI=y
> CONFIG_NFSD=y
> CONFIG_NLS_CODEPAGE_850=y
> CONFIG_NLS_ISO8859_1=y
> CONFIG_NLS_ISO8859_8=y
> CONFIG_NLS_UTF8=y
> CONFIG_NTFS_FS=y
> CONFIG_OABI_COMPAT=y
> CONFIG_PCI_QUIRKS=y
> CONFIG_PCI_SYSCALL=y
> CONFIG_PCI=y
> CONFIG_PLAT_VERSATILE_CLCD=y
> CONFIG_PLAT_VERSATILE_CLOCK=y
> CONFIG_PLAT_VERSATILE_SCHED_CLOCK=y
> CONFIG_PLAT_VERSATILE=y
> CONFIG_PREEMPT_NONE=y
> CONFIG_RD_BZIP2=y
> CONFIG_RD_LZMA=y
> CONFIG_RD_LZO=y
> CONFIG_RD_XZ=y
> CONFIG_ROMFS_BACKED_BY_BLOCK=y
> CONFIG_ROMFS_FS=y
> CONFIG_ROMFS_ON_BLOCK=y
> CONFIG_RWSEM_GENERIC_SPINLOCK=y
> CONFIG_SCSI_PROC_FS=y
> CONFIG_SCSI_SPI_ATTRS=y
> CONFIG_SCSI_SYM53C8XX_2=y
> CONFIG_SCSI_SYM53C8XX_MMIO=y
> CONFIG_SERIAL_8250_DEPRECATED_OPTIONS=y
> CONFIG_SERIAL_8250_EXTENDED=y
> CONFIG_SERIAL_8250_MANY_PORTS=y
> CONFIG_SERIAL_8250_RSA=y
> CONFIG_SERIAL_8250_SHARE_IRQ=y
> CONFIG_SERIO_AMBAKMI=y
> CONFIG_SERIO_LIBPS2=y
> CONFIG_SERIO=y
> CONFIG_SLAB=y
> CONFIG_SMC91X=y
> CONFIG_SND_PCI=y
> CONFIG_TINY_RCU=y
> CONFIG_UIDGID_CONVERTED=y
> CONFIG_USB_ARCH_HAS_EHCI=y
> CONFIG_USB_ARCH_HAS_OHCI=y
> CONFIG_USB_ARCH_HAS_XHCI=y
> CONFIG_VERSATILE_FPGA_IRQ=y
> CONFIG_VGA_ARB=y
> CONFIG_XZ_DEC=y
> CONFIG_ZLIB_DEFLATE=y
```

## Test the kernel options

* Added the kernel options found in http://xecdesign.com/compiling-a-kernel/ with `make menuconfig` ot our Hypriot kernel for the Pi 1.
* Start a build on Drone server for the updated kernel.
* Sart a build on Drone server for the SD card image.

Now download the SD card image, extract it, mount the SD card image, extract the Pi 1 kernel.img, unmount it.

```bash
aws s3 cp s3://buildserver-production/images/hypriot-rpi-20150316-153452.img.zip .
unzip hypriot-rpi-20150316-153452.img.zip
vagrant ssh
sudo su
cp /vagrant/hypriot-rpi-20150316-153452.img .
/vagrant/scripts/mount-sd-image.sh /home/vagrant/hypriot-rpi-20150316-153452.img
cp /mnt/pi-boot/kernel.img .
/vagrant/scripts/unmount-sd-image.sh /home/vagrant/hypriot-rpi-20150316-153452.img
QEMU_AUDIO_DRV=none qemu-system-arm -curses -kernel /home/vagrant/kernel.img -cpu arm1176 -m 256 -M versatilepb -append "root=/dev/sda2 rw vga=normal console=ttyAMA0,115200" -nographic -hda /home/vagrant/hypriot-rpi-20150316-153452.img -redir tcp:2222::22
```

But still hangs :-(

## Stop QEMU

Press `ctrl+a c` to switch between console and monitor. Here you can enter `quit` to stop QEMU and return to your unix shell.
