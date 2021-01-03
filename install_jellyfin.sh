#! /bin/bash

HOSTNAME='jellyfin'

cd /root/

# add jellyfin repository and install
wget -O - https://repo.jellyfin.org/debian/jellyfin_team.gpg.key | apt-key add -
echo "deb [arch=$( dpkg --print-architecture )] https://repo.jellyfin.org/debian $( lsb_release -c -s ) main" |  tee /etc/apt/sources.list.d/jellyfin.list
apt update
apt install jellyfin
sudo usermod -aG video jellyfin
sudo systemctl restart jellyfin

# add docker as well, just in case
# curl -fsSL https://get.docker.com -o get-docker.sh
# sh get-docker.sh
# usermod -aG docker Pi

# set hostname
echo "$HOSTNAME" > /etc/hostname
echo "$(cat /etc/hosts | sed "s/raspberrypi/$HOSTNAME/g")" | tee /etc/hosts
