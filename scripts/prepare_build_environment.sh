# vim:ft=sh
#!/bin/bash

# get the most recent package information
# if the last update is more than 24h ago
last_access=$(stat -c %Z /var/lib/apt/periodic/update-success-stamp)
last_access=${last_access:-0}

if [ "$[$(date +%s) - $last_access]" -ge 86400 ]; then
  sudo apt-get update
fi

# setup apt-fast for parallel downloads
echo "Installing Apt-fast"
sudo apt-get install software-properties-common python-software-properties
sudo add-apt-repository ppa:saiarcot895/myppa
sudo apt-get update
cat << EOF > /etc/apt-fast.conf
_APTMGR=apt-get
DOWNLOADBEFORE=true
MIRRORS=( 'http://mirror.netcologne.de/ubuntu,http://ftp.hosteurope.de/mirror/archive.ubuntu.com,http://ftp.uni-bayreuth.de/linux/ubuntu/ubuntu/,http://mirror.serverloft.eu/ubuntu/ubuntu/' )
_MAXNUM=10
DLLIST='/tmp/apt-fast.list'
_DOWNLOADER='aria2c -c -j ${_MAXNUM} -x ${_MAXNUM} -s ${_MAXNUM} --min-split-size=1M -i ${DLLIST} --connect-timeout=600 --timeout=600 -m0'
DLDIR='/var/cache/apt/archives/apt-fast'
APTCACHE='/var/cache/apt/archives'
EOF
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confold" -y install apt-fast
alias apt-get='apt-fast'

# install packages needed for building the sd card image
sudo apt-get install -y python-pip build-essential libncurses5-dev tree binfmt-support qemu qemu-user-static debootstrap kpartx lvm2 dosfstools apt-cacher-ng

# needed to fetch packages from s3
pip install awscli

# remove cached packages in /var/cache/apt/archives
apt-get clean
rm -rf /var/lib/apt/lists/*

