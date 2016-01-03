#!/bin/bash
set -ex

# set up error handling for cleaning up
# after having an error
handle_error() {
  echo "FAILED: line $1, exit code $2"
  echo "Removing loop device"
  # ensure we are outside mounted image filesystem
  cd /
  # remove loop device for image
  kpartx -vds ${IMAGE_PATH}
  exit 1
}

trap 'handle_error $LINENO $?' ERR

# set up some variables for the script
export LC_ALL="C"

RPI_IMAGE_BUILDER_ROOT=${RPI_IMAGE_BUILDER_ROOT:="/vagrant"}

# read configuration
SETTINGS_PROFILE="hypriot"
. "$RPI_IMAGE_BUILDER_ROOT/settings/${SETTINGS_PROFILE}"

BUILD_ENV=${BUILD_ENV:="/build_env"}
BUILD_RESULTS=${BUILD_RESULTS:="$RPI_IMAGE_BUILDER_ROOT/build_results"}
BUILD_INPUTS=${BUILD_INPUTS:="$RPI_IMAGE_BUILDER_ROOT/build_inputs"}
BUILD_SCRIPTS=${BUILD_SCRIPTS:="$RPI_IMAGE_BUILDER_ROOT/scripts"}

mkdir -p ${BUILD_INPUTS}/kernel/$KERNEL_DATETIME
touch ${BUILD_INPUTS}/kernel/${KERNEL_DATETIME}/kernel-commit.txt
KERNEL_COMMIT=${KERNEL_COMMIT:=$(<${BUILD_INPUTS}/kernel/${KERNEL_DATETIME}/kernel-commit.txt)}

echo "###############"
echo "### Build results will go to $BUILD_RESULTS"

# locate path of RPi kernel
kernel_path="$BUILD_INPUTS/kernel"
mkdir -p $kernel_path
docker_path="$BUILD_INPUTS/docker"
mkdir -p $docker_path

# settings
_APT_SOURCE_DEBIAN="ftp://ftp.debian.org/debian"
_APT_SOURCE_DEBIAN_CDN="http://http.debian.net/debian"
_APT_SOURCE_RASPBIAN="http://mirrordirector.raspbian.org/raspbian/"
_USE_CACHE="yes"

_FSTAB="
proc			/proc	proc	defaults	0	0
/dev/mmcblk0p1	/boot	vfat	defaults	0	0
/dev/mmcblk0p2	/	  	ext4	defaults,noatime       0       1
"

_HOSTNAME=""

_NET_CONFIG=""				# dhcp|static
if [ "${_NET_CONFIG}" == "static" ]; then
	_NET_ADDRESS=""
	_NET_NETMASK=""
	_NET_GATEWAY=""
fi

_MODULES=""

_USER_NAME=""
_USER_PASS=""


#######################################
# NOT YET IN USE

_KEYMAP=""
_TIMEZONE=""
_LOCALES=""					#en_US.utf-8 de_DE.utf-8
_ENCODING=""

# _DISK_OPTION=""				# expand rootfs|create new partion from free space|nothing


########################################
# Overwrite variables with profile settings
. "$RPI_IMAGE_BUILDER_ROOT/settings/${SETTINGS_PROFILE}"



###############################################################################
# Apply-Functions


# using apt-get not only make it faster but
# also guards against ip6
# http://unix.stackexchange.com/questions/9940/convince-apt-get-not-to-use-ipv6-method
get_apt_source_mirror_url () {
	if [ "${_USE_CACHE}" = "no" ]; then
		echo "${_APT_SOURCE}"
	else
		HTTP="http://"
		echo -n "http://localhost:3142/${_APT_SOURCE#${HTTP}}"
	fi
}


get_apt_sources_list () {
echo "
deb ${_APT_SOURCE} ${_DEB_RELEASE} main contrib non-free rpi
#deb-src $(get_apt_source_mirror_url) ${_DEB_RELEASE} main contrib non-free rpi firmware
"
}

#######################################

# NETWORK CONFIG
set_network_config () {

	if [ -z "$1" ]; then
		echo "Error on set_network_config: No profile specified!"
		exit # TODO Set error code
	fi

	_NET_CONFIG_FILE="etc/network/interfaces"

	case "$1" in
    "dhcp")
      echo "
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp
iface eth0 inet6 auto

allow-hotplug wlan0
iface wlan0 inet dhcp
pre-up /usr/bin/occi
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
iface default inet dhcp
" > ${_NET_CONFIG_FILE}
				;;

		"static")
			if [ -z ${_NET_ADDRESS} ] || [ -z ${_NET_NETMASK} ] || [ -z ${_NET_GATEWAY} ]; then
				echo "Error on set_network_config: 'static' was specified, but no values where set."
				exit # TODO Set error code
			fi

			echo "
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
	address ${_NET_ADDRESS} # 192.0.2.7
	netmask ${_NET_NETMASK} # 255.255.255.0
	gateway ${_NET_GATEWAY} # 192.0.2.254
iface eth0 inet6 auto
" > ${_NET_CONFIG_FILE}
				;;

		*)
				# TODO Debug msg
				exit # TODO Set error code
				;;
	esac

}




#######################################
## Prepare bootstrap env

# define destination folder where created image file will be stored
mkdir -p ${BUILD_ENV}

TMPFS_SIZE=$(expr ${SD_CARD_SIZE} \* 3 / 2)

mount -t tmpfs -o size="${TMPFS_SIZE}m" tmpfs ${BUILD_ENV}

mount | grep tmpfs

mkdir -p $BUILD_ENV/images

cd $BUILD_ENV
rootfs="${BUILD_ENV}/rootfs"
bootfs="${rootfs}/boot"

BUILD_TIME="$(date +%Y%m%d-%H%M%S)"

IMAGE_PATH=""
IMAGE_PATH="${BUILD_ENV}/images/${SETTINGS_PROFILE}-rpi-${BUILD_TIME}.img"

BOOTFS_START=2048
BOOTFS_SIZE=$(expr ${BOOT_PARTITION_SIZE} \* 2048)
ROOTFS_START=$(expr ${BOOTFS_SIZE} + ${BOOTFS_START})
SD_MINUS_DD=$(expr ${SD_CARD_SIZE} - 256)  # old config: 1280 - 256 = 1024 for rootfs
ROOTFS_SIZE=$(expr ${SD_MINUS_DD} \* 1000000 / 512 - ${ROOTFS_START})

dd if=/dev/zero of=${IMAGE_PATH} bs=1MB count=${SD_CARD_SIZE}

DEVICE=$(losetup -f --show ${IMAGE_PATH})

echo "Image ${IMAGE_PATH} created and mounted as ${DEVICE}."

# Create partions
sfdisk --force ${DEVICE} <<PARTITION
unit: sectors

/dev/loop0p1 : start= ${BOOTFS_START}, size= ${BOOTFS_SIZE}, Id= c
/dev/loop0p2 : start= ${ROOTFS_START}, size= ${ROOTFS_SIZE}, Id=83
/dev/loop0p3 : start= 0, size= 0, Id= 0
/dev/loop0p4 : start= 0, size= 0, Id= 0
PARTITION

losetup -d $DEVICE
DEVICE=`kpartx -va ${IMAGE_PATH} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
bootp="/dev/mapper/${DEVICE}p1"
rootp="/dev/mapper/${DEVICE}p2"
DEVICE="/dev/${DEVICE}"

# Give some time to system to refresh
sleep 3

# create file systems
mkfs.vfat ${bootp}
mkfs.ext4 ${rootp} -L root -i 4096 # create 1 inode per 4kByte block (maximum ratio is 1 per 1kByte)

#######################################

mkdir -p ${rootfs}

mount ${rootp} ${rootfs}

mkdir -p ${rootfs}/proc
mkdir -p ${rootfs}/sys
mkdir -p ${rootfs}/dev
mkdir -p ${rootfs}/dev/pts
mkdir -p ${rootfs}/var/pkg/kernel
mkdir -p ${rootfs}/var/pkg/docker
mkdir -p ${rootfs}/var/pkg/gitdir

mount -t proc none ${rootfs}/proc
mount -t sysfs none ${rootfs}/sys
mount -o bind /dev ${rootfs}/dev
mount -o bind /dev/pts ${rootfs}/dev/pts
mount -o bind ${kernel_path} ${rootfs}/var/pkg/kernel
mount -o bind ${docker_path} ${rootfs}/var/pkg/docker
mount -o bind ${RPI_IMAGE_BUILDER_ROOT} ${rootfs}/var/pkg/gitdir

cd $rootfs

#######################################
# Start installation of base system
#debootstrap --arch armhf --variant=minbase --no-check-gpg --foreign ${_DEB_RELEASE} ${rootfs} $(get_apt_source_mirror_url) # TODO: Research how to use in production
# setup env

function unpack_debootstrap_tarball () {
  echo "### start unpacking debootstrap.tgz"
  debootstrap --unpack-tarball /tmp/cache/debootstrap_rpi.tgz --arch armhf --no-check-gpg --foreign ${_DEB_RELEASE} ${rootfs} $(get_apt_source_mirror_url)
}

function pack_debootstrap_tarball () {
  echo "### start packing debootstrap.tgz pack"
  debootstrap --arch armhf --no-check-gpg --foreign ${_DEB_RELEASE} ${rootfs} $(get_apt_source_mirror_url)
  (cd $rootfs; tar czf - var/lib/apt var/cache/apt) > /tmp/cache/debootstrap_rpi.tgz
}

mkdir -p /tmp/cache
if [ -e /tmp/cache/debootstrap_rpi.tgz ]; then
  unpack_debootstrap_tarball
else
  pack_debootstrap_tarball
  unpack_debootstrap_tarball
fi


# Complete installation process
cp /usr/bin/qemu-arm-static usr/bin/

LANG=C chroot ${rootfs} /debootstrap/debootstrap --second-stage

mount ${bootp} ${bootfs}

# Prevent services from starting during installation.
echo "#!/bin/sh
exit 101
EOF" > usr/sbin/policy-rc.d
chmod +x usr/sbin/policy-rc.d


# etc/apt/sources.list
get_apt_sources_list > etc/apt/sources.list

# create a default boot/config.txt file (details see http://elinux.org/RPiconfig)
echo "
hdmi_force_hotplug=1
" > boot/config.txt

# boot/cmdline.txt
echo "+dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 cgroup-enable=memory swapaccount=1 elevator=deadline rootwait console=ttyAMA0,115200 kgdboc=ttyAMA0,115200" > boot/cmdline.txt

# boot/occidentalis.txt (occi)
echo "
# hostname for your Hypriot Raspberry Pi:
hostname=${_HOSTNAME}

# basic wireless networking options:
# wifi_ssid=your-ssid
# wifi_password=your-presharedkey
" > boot/occidentalis.txt

# etc/fstab
echo "${_FSTAB}" > etc/fstab

# etc/hostname
echo "${_HOSTNAME}" > etc/hostname

# etc/network/interfaces
set_network_config ${_NET_CONFIG}

# etc/modules
echo "vchiq
snd_bcm2835
bcm2708-rng
" >> etc/modules

# debconf.set
echo "console-common	console-data/keymap/policy	select	Select keymap from full list
console-common	console-data/keymap/full	select	${_KEYMAP}
" > debconf.set

## Write firstboot script
echo "#!/bin/bash
# This script will run the first time the raspberry pi boots.
# It is ran as root.

echo 'Starting firstboot.sh' >> /dev/kmsg

# resize root partion to possible maximum
echo 'Resizing root partition' >> /dev/kmsg
/usr/local/bin/resize_root_partition

# Get current date from debian time server
ntpdate 0.debian.pool.ntp.org

echo 'Reconfiguring openssh-server' >> /dev/kmsg
echo '  Collecting entropy ...' >> /dev/kmsg

# Drain entropy pool to get rid of stored entropy after boot.
dd if=/dev/urandom of=/dev/null bs=1024 count=10 2>/dev/null

while entropy=\$(cat /proc/sys/kernel/random/entropy_avail); [ \$entropy -lt 100 ]
	do sleep 1
done

rm -f /etc/ssh/ssh_host_*
echo '  Generating new SSH host keys ...' >> /dev/kmsg
dpkg-reconfigure openssh-server
echo '  Reconfigured openssh-server' >> /dev/kmsg

# Set locale
export LANGUAGE=${_LOCALES}.${_ENCODING}
export LANG=${_LOCALES}.${_ENCODING}
export LC_ALL=${_LOCALES}.${_ENCODING}

cat << EOF | debconf-set-selections
locales   locales/locales_to_be_generated multiselect     ${_LOCALES}.${_ENCODING} ${_ENCODING}
EOF

rm /etc/locale.gen
dpkg-reconfigure -f noninteractive locales
update-locale LANG="${_LOCALES}.${_ENCODING}"

cat << EOF | debconf-set-selections
locales   locales/default_environment_locale select       ${_LOCALES}.${_ENCODING}
EOF

echo 'Reconfigured locale' >> /dev/kmsg

# Set timezone
echo '${_TIMEZONE}' > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

echo 'Reconfigured timezone' >> /dev/kmsg

echo 'Enabling and starting docker service' >> /dev/kmsg
systemctl enable docker.service
systemctl start docker.service

echo 'Import Docker Swarm image' >> /dev/kmsg
sleep 5
docker load < /var/hypriot/swarm.tar.gz
if ((\$? == 0)); then
  rm -f /var/hypriot/swarm.tar.gz
fi

" > root/firstboot.sh
chmod 755 root/firstboot.sh

######################################
# enable login on serial console
printf "# Spawn a getty on Raspberry Pi serial line\nT0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100\n" >> etc/inittab

#######################################
echo "#!/bin/bash
debconf-set-selections /debconf.set
rm -f /debconf.set

# make dpkg run faster
echo 'force-unsafe-io' | tee etc/dpkg/dpkg.cfg.d/02apt-speedup > /dev/null

apt-get update

apt-get -y install aptitude gpgv git-core binutils ca-certificates wget curl # TODO FIXME

echo 'add /etc/hypriot_release file'
cat << VERSION | tee /etc/hypriot_release
profile: ${SETTINGS_PROFILE}
image_build: ${BUILD_TIME}
image_commit: ${DRONE_COMMIT}
kernel_build: ${KERNEL_DATETIME}
kernel_commit: ${KERNEL_COMMIT}

VERSION

apt-get -y install aptitude gpgv git-core binutils ca-certificates wget curl bash-completion # TODO FIXME

# adding Debian Archive Automatic Signing Key (7.0/wheezy) <ftpmaster@debian.org> to apt-keyring
gpg --keyserver pgpkeys.mit.edu --recv-key 8B48AD6246925553
gpg -a --export 8B48AD6246925553 | apt-key add -

wget -q http://archive.raspberrypi.org/debian/raspberrypi.gpg.key -O - | apt-key add -

# install occi
echo 'deb http://apt.adafruit.com/raspbian/ wheezy main' >> etc/apt/sources.list
wget -q https://apt.adafruit.com/apt.adafruit.com.gpg.key -O - | apt-key add -

apt-get update

curl -s -L --output /usr/bin/rpi-update https://raw.github.com/Hexxeh/rpi-update/master/rpi-update && chmod +x /usr/bin/rpi-update
touch /boot/start.elf
mkdir -p /lib/modules
SKIP_BACKUP=1 SKIP_KERNEL=1 /usr/bin/rpi-update
echo 'Listing /lib/modules/'
ls -al /lib/modules/

apt-get -y install ${_APT_PACKAGES} # FIXME

# patch /usr/bin/occi to improve finding wlan interface
sed -i s/\'ifconfig\',\ \'-s\'/\'ifconfig\',\ \'-a\'/ /usr/bin/occi

rm -f /etc/ssh/ssh_host_*

apt-get -y install lua5.1 triggerhappy
apt-get -y install dmsetup parted
apt-get -y install rng-tools
apt-get -y install sudo

echo "***** Installing HyprIoT source list *****"
wget -q https://packagecloud.io/gpg.key -O - | apt-key add -
echo 'deb https://packagecloud.io/Hypriot/Schatzkiste/debian/ wheezy main' > /etc/apt/sources.list.d/hypriot.list
echo "***** HyprIoT source list installed *****"

apt-get update

echo "***** Installing HyprIoT kernel *****"
dpkg -i /var/pkg/kernel/${KERNEL_DATETIME}/raspberrypi-bootloader_${KERNEL_DATETIME}_armhf.deb
dpkg -i /var/pkg/kernel/${KERNEL_DATETIME}/libraspberrypi0_${KERNEL_DATETIME}_armhf.deb
dpkg -i /var/pkg/kernel/${KERNEL_DATETIME}/libraspberrypi-dev_${KERNEL_DATETIME}_armhf.deb
dpkg -i /var/pkg/kernel/${KERNEL_DATETIME}/libraspberrypi-bin_${KERNEL_DATETIME}_armhf.deb
dpkg -i /var/pkg/kernel/${KERNEL_DATETIME}/libraspberrypi-doc_${KERNEL_DATETIME}_armhf.deb
echo "***** HyprIoT kernel installed *****"

echo "***** Installing RPi3 bootfiles *****"
wget -q http://downloads.hypriot.com/rpi3-bootfiles.tar.gz -O - | tar xvzf - -C /boot
echo "***** RPi3 bootfiles installed *****"

echo "***** Installing HyprIoT kernel headers *****"
dpkg -i /var/pkg/kernel/${KERNEL_DATETIME}/linux-headers-${KERNEL_VERSION}-hypriotos+_${KERNEL_VERSION}-hypriotos+-1_armhf.deb
dpkg -i /var/pkg/kernel/${KERNEL_DATETIME}/linux-headers-${KERNEL_VERSION}-hypriotos-v7+_${KERNEL_VERSION}-hypriotos-v7+-2_armhf.deb
echo "***** HyprIoT kernel headers installed *****"

echo "***** Installing rpi-serial-console script *****"
wget -q https://raw.githubusercontent.com/lurch/rpi-serial-console/master/rpi-serial-console -O usr/local/bin/rpi-serial-console
chmod +x usr/local/bin/rpi-serial-console
echo "***** rpi-serial-console installed *****"

echo "***** Installing docker-cleanup-volumes script *****"
wget -q https://raw.githubusercontent.com/chadoe/docker-cleanup-volumes/master/docker-cleanup-volumes.sh -O usr/local/bin/docker-cleanup-volumes
chmod +x usr/local/bin/docker-cleanup-volumes
echo "***** docker-cleanup-volumes installed *****"

echo "***** Installing HyprIoT docker *****"
dpkg -i /var/pkg/docker/deb/${DOCKER_DEB}
echo "***** HyprIoT docker installed *****"

echo "***** Installing docker-compose *****"
apt-get install -y docker-compose=${DOCKER_COMPOSE_VERSION}
echo "***** HyprIoT docker-compose installed *****"

echo "***** Installing docker-machine *****"
apt-get install -y docker-machine=${DOCKER_MACHINE_VERSION}
echo "***** HyprIoT docker-machine installed *****"

echo "***** Copying Docker Swarm image *****"
mkdir -p /var/hypriot
cp /var/pkg/docker/swarm.tar.gz /var/hypriot
echo "***** Copying Docker Swarm finished *****"

echo "***** Installing HyprIoT user=pi *****"
useradd -m pi --group docker --shell /bin/bash
echo "pi:raspberry" | chpasswd
mkdir -p /etc/sudoers.d
echo "pi ALL=NOPASSWD: ALL" > /etc/sudoers.d/user-pi
chmod 0440 /etc/sudoers.d/user-pi
echo "***** Installing HyprIoT user=pi *****"

echo "***** Installing HyprIoT bash prompt *****"
cp /var/pkg/gitdir/scripts/files/bash_prompt/bashrc /root/.bashrc
cp /var/pkg/gitdir/scripts/files/bash_prompt/bash_prompt /root/.bash_prompt

cp /var/pkg/gitdir/scripts/files/bash_prompt/bashrc /home/pi/.bashrc
cp /var/pkg/gitdir/scripts/files/bash_prompt/bash_prompt /home/pi/.bash_prompt
chown -R pi:pi /home/pi
echo "***** HyprIoT bash prompt installed *****"

echo "***** Installing resize_root_partition script *****"
cp /var/pkg/gitdir/scripts/files/resize_root_partition /usr/local/bin/resize_root_partition
chmod +x /usr/local/bin/resize_root_partition

echo "***** Installing Hypriot Cluster Lab *****"
apt-get install hypriot-cluster-lab

echo "***** Enabling password login for root *****"
sed -i -e 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

echo \"${_USER_NAME}:${_USER_PASS}\" | chpasswd
sed -i -e 's/KERNEL\!=\"eth\*|/KERNEL\!=\"/' /lib/udev/rules.d/75-persistent-net-generator.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f third-stage
" > third-stage
chmod +x third-stage

LANG=C chroot ${rootfs} /third-stage

###################
# Execute firstboot.sh only on first boot
echo "Execute firstboot.sh only on first boot ..."
echo "#!/bin/sh -e
if [ ! -e /root/firstboot_done ]; then
	touch /root/firstboot_done
	if [ -e /root/firstboot.sh ]; then
		/root/firstboot.sh
	fi
fi

exit 0
" > etc/rc.local

###################
# write apt source list again
echo "write apt source list again  ..."
get_apt_sources_list > etc/apt/sources.list

###################
# cleanup
echo "### cleanup ..."
echo "#!/bin/bash -x
apt-get update
apt-get clean
rm -f /etc/ssl/private/ssl-cert-snakeoil.key
rm -f /etc/ssl/certs/ssl-cert-snakeoil.pem
rm -f /var/lib/urandom/random-seed
" > cleanup
echo "rm -f /usr/sbin/policy-rc.d" >> cleanup
echo "rm -f cleanup" >> cleanup

chmod +x cleanup

LANG=C chroot ${rootfs} /cleanup

###################

cd ${rootfs}
sync
sleep 30

# Kill processes still running in chroot.
for rootpath in /proc/*/root; do
	rootlink=$(readlink $rootpath)
	if [ "x${rootlink}" != "x" ]; then
		if [ "x${rootlink:0:${#rootfs}}" = "x${rootfs}" ]; then
			# this process is in the chroot...
			PID=$(basename $(dirname "$rootpath"))
			kill -9 "$PID"
		fi
	fi
done

# make sure we are not anymore in any mounted directory
# else we might get a device busy error later when
# we want to unmap the loopback device with kpartx
cd /


echo "### Unmounting"
umount -l ${rootfs}/dev/pts || true
umount -l ${rootfs}/dev || true
umount -l ${rootfs}/sys || true
umount -l ${rootfs}/proc || true
umount -l ${bootp} || true
umount -l ${rootfs}/var/pkg/docker || true
umount -l ${rootfs}/var/pkg/kernel || true
umount -l ${rootfs}/var/pkg/gitdir || true
umount -l ${rootfs} || true

sync
sleep 5

echo "### remove dev mapper devices for image partitions"
kpartx -vds ${IMAGE_PATH} || true
sleep 5
kpartx -vds ${IMAGE_PATH}

echo "### compress $IMAGE_PATH to ${IMAGE_PATH}.zip"
chmod -x $IMAGE_PATH
pigz --zip $IMAGE_PATH
IMAGE_PATH=${IMAGE_PATH}.zip

echo "### copy $IMAGE_PATH to $BUILD_RESULTS directory."
mkdir -p $BUILD_RESULTS
cp $IMAGE_PATH $BUILD_RESULTS/

echo "### create sha256 checksum"
cd $BUILD_RESULTS && shasum -a 256 ${SETTINGS_PROFILE}-rpi-${BUILD_TIME}.img.zip > ${SETTINGS_PROFILE}-rpi-${BUILD_TIME}.img.zip.sha256

echo "### Created image ${IMAGE_PATH}."

exit ${SUCCESS}
