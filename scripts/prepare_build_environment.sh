# vim:ft=sh
#!/bin/bash


# get the most recent package information
# if the last update is more than 24h ago
function update_package_sources () {
last_access=$(stat -c %Z /var/lib/apt/periodic/update-success-stamp)
last_access=${last_access:-0}

if [ "$[$(date +%s) - $last_access]" -ge 86400 ]; then
  sudo apt-get update
fi
}

# Apt-Fast is an alternative to Apt which
# downloads packages in parallel
function setup_apt_fast () {
echo "Set up Apt-Fast"

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# install and configure apt-fast
apt-get install -y aria2
cp $SCRIPT_DIR/files/apt-fast /usr/bin/
chmod +x /usr/bin/apt-fast
cp $SCRIPT_DIR/files/apt-fast.conf /etc/apt-fast.conf

# configure apt-fast as alternative/alias for apt-get
sudo mv /usr/bin/apt-get /usr/bin/apt-get-standard
sudo update-alternatives --install /usr/bin/apt-get apt-get /usr/bin/apt-fast 100
sudo update-alternatives --install /usr/bin/apt-get apt-get /usr/bin/apt-get-standard 90
sudo update-alternatives --set apt-get /usr/bin/apt-fast
}

function install_prerequisites () {
# this fixed the "update-binfmts: warning: Couldn't load the binfmt_misc module." error
# I do not understand why it is needed now
# more documenation about this can be found here https://www.kernel.org/doc/Documentation/binfmt_misc.txt
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc

# install packages needed for building the sd card image
sudo apt-get install -y python-pip build-essential libncurses5-dev tree binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools apt-cacher-ng pigz

# needed to fetch packages from s3
sudo pip install awscli

# needed for servespec tests
sudo apt-get install -y ruby psmisc sshpass
sudo gem install bundler
}

export DEBIAN_FRONTEND=noninteractive

update_package_sources
setup_apt_fast
install_prerequisites
