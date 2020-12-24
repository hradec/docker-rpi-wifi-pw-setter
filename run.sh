#! /bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 <unzipped raspbian image> <wifi ssid name> <wifi passwd>"
    exit 1
fi

img=$(readlink -f $1)
d="$(dirname ${img})"
f="$(basename ${img})"
path=$(dirname $(readlink -f $BASH_SOURCE))
ssid=$2
ssid_passwd=$3

# deal with any extra script we want to run inside the rpi emulation environment
if [ "$4" != "" ] ; then
    extra_script=$(readlink -f $4)
    extra_volume="--volume $extra_script:/root/extra_script"
fi

docker run --rm --privileged --tty --interactive \
    --volume "$img:/images/image.img" \
    --volume "$path/set_pw.sh:/usr/local/bin/set_pw.sh" \
    --volume "$path/:/root/hostfolder" \
    $extra_volume \
    remmelt/docker-rpi-wifi-pw-setter \
$ssid $ssid_passwd
