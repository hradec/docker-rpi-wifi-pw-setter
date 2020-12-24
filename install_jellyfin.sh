#! /bin/bash

HOSTNAME='jellyfin'

cd /root/

# upgrade distro
apt-get update && apt-get upgrade

# add jellyfin repository and install
echo "deb [arch=armhf] https://repo.jellyfin.org/debian $( lsb_release -c -s ) main" | tee /etc/apt/sources.list.d/jellyfin.list
apt update
apt install jellyfin

# add docker as well, just in case
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker Pi

# set hostname
echo "$HOSTNAME" > /etc/hostname
echo "$(cat /etc/hosts | sed "s/raspberrypi/$HOSTNAME/g")" | tee /etc/hosts
