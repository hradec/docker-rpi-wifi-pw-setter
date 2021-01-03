#! /bin/bash

set -o pipefail
set -o nounset
set -o errexit

img=/images/$1
extra_script="$4"

echo "HI! I'm going to set SSH access and wifi config in the Raspbian image."
echo
echo -n "Trying to find ${img}... "
if [ -f "${img}" ]; then
    echo found!
else
    echo
    echo "Could not find the image file $img..."
    exit 2
fi
echo

# now setup wifi!
if [ $# -lt 3 ] ; then
    echo -n "Your SSID: "
    read ssid
    echo -n "Your wifi password: "
    read pw
else
    ssid=$2
    pw=$3
fi

cat << EOF >> /tmp/wifi
network={
    ssid="${ssid}"
    psk="${pw}"
}
EOF

# install missing packages, if they are not available in the image!
if [ "$(which partprobe)" == "" ] || [ "$(which qemu-arm-static)" == "" ] ; then
    echo '==========================================================================================='
    echo 'We need to install some missing packages in the docker image... '
    echo '==========================================================================================='
    apt update
    apt install -y parted qemu-user-static
fi

mkdir -p /mnt/disk1 /mnt/disk2

# cleanup empty loop devices, just in case
for n in $(losetup | grep '.*/$' | awk '{print $1}') ; do
    echo $n
    losetup -d $n
done

# we use losetup to create a loop device for the image,
# and then call partprobe to create the partitions devices as well
echo '==========================================================================================='
echo 'mounting image...'
echo '==========================================================================================='
losetup -f "${img}"
if [ $? -ne 0 ] ; then
    echo "ERROR: Couldn't mount the image partitions!!"

else
    losetup
    loop=$(losetup | grep ${img} | awk '{print $1}')
    echo ">>> $loop"
    partprobe ${loop}
    lsblk $loop

    for nr in 1 2; do
        #i=$(fdisk -l "${img}" | grep "${img}${nr}" | awk '{printf "offset=%d", $2*512}')
        #fdisk -l "${img}" | grep "${img}${nr}" | awk '{printf "offset=%d", $2}'
        #echo $i,$nr
        #mount -o loop,${i} "${img}" /mnt/disk${nr}
        mount ${loop}p${nr} /mnt/disk${nr} 2>/dev/null || echo "Error mounting partition $nr"
    done

    rootfs=$(dirname $(find /mnt -name 'boot'))
    bootfs=$(dirname $(find /mnt -name 'kernel.img'))

    if [ -e $rootfs/boot ] ; then
        if [ "$bootfs" == ""  ] ; then
            echo "ERROR: Can't setup wifi because couldn't find boot fat32 partition!!"
        else
            echo '==========================================================================================='
            echo 'enable ssh using qemu-static-arm and chroot...'
            echo '==========================================================================================='
            # we need this so we can run arm code using chroot
            cp /usr/bin/qemu-arm-static $rootfs/usr/bin

            # mount the necessary stuff to chroot in
            for f in dev dev/pts sys proc run ; do mount --bind /$f $rootfs/$f ; done
            mount --bind $bootfs $rootfs/boot/

            # Enable ssh access by putting a file named 'ssh' in the boot partition
            chroot $rootfs systemctl enable ssh 2>&1 | egrep -v 'qemu|preload'

            echo '==========================================================================================='
            echo 'setup wifi...'
            echo '==========================================================================================='
            # set wifi on boot partition so raspian will bring the wifi up at boot!
            cp /tmp/wifi $bootfs/wpa_supplicant.conf

            # run extra setup script inside qemu arm emulator, so it will run
            # just as if it was running in the raspberry pi
            # use this to install extra software, like docker, jellyfin, etc.
            if [ "$extra_script" != "" ] ; then
                cp $extra_script $rootfs/root/extra_script
                if [ "$(cat $rootfs/root/extra_script)" != "" ] ; then
                    echo '==========================================================================================='
                    echo 'run extra script using qemu-static-arm inside the image...'
                    echo '==========================================================================================='
                    chmod a+x $rootfs/root/extra_script
                    chroot $rootfs /bin/bash -c 'apt install -y --force-yes apt-transport-https sudo' 2>&1 | egrep -v 'qemu|preload'
                    chroot $rootfs /root/extra_script 2>&1 | egrep -v 'qemu|preload'
                fi
                /bin/bash
            fi

            # umount chroot stuff
            for f in dev dev/pts sys proc run ; do umount $rootfs/$f ; done

            echo '==========================================================================================='
            echo
            echo "We're done!"
            echo "You can now write the image to your SD card, see "
            echo "https://www.raspberrypi.org/documentation/installation/installing-images/README.md"
            echo
            echo '==========================================================================================='
        fi
    else

        echo "ERROR: Couldn't mount the image partitions!!"

    fi

    for path in $(ls /mnt/) ; do
        umount /mnt/$path
    done
    losetup -d ${loop}
    losetup | grep image.img
fi
