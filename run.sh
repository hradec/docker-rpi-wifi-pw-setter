#! /bin/bash


while getopts wrx: option ; do
    case "${option}"
    in
        w) WIFI="${OPTARG}";;
        r) RESIZE="${OPTARG}";;
        x) EXTRA="${OPTARG}";;
    esac
done

img=$(readlink -f $1)
d="$(dirname ${img})"
f="$(basename ${img})"
path=$(dirname $(readlink -f $BASH_SOURCE))
ssid=$(echo $WIFI | awk -F':' '{print $1}')
ssid_passwd=$(echo $WIFI | awk -F':' '{print $2}')

HELP="$WIFI$RESIZE$EXTRA$ssid$ssid_passwd"
if [ "$HELP" == "" ] ; then
    echo -e "\n$(basename $0) <image filename> \n"
    echo -e "\n\noptions:\n"
    echo -e "\t-w   : set wifi ssid:passwd. ex: -w wifiName:secretPasswd"
    echo -e "\t-r   : resize the image by +N (b)ytes|(m)egabytes|(g)igabytes. ex: -r +2gb"
    echo -e "\t-x   : extra script to run inside image using qemu-static-arm. ex: -x install_jellyfin.sh"
    echo ''
fi

# deal with any extra script we want to run inside the rpi emulation environment
if [ "$EXTRA" != "" ] ; then
    extra_script=$(readlink -f $EXTRA)
    extra_volume="--volume $extra_script:/root/extra_script"
    extra_script="/root/hostfolder/$(basename $extra_script)"
fi

docker run --rm --privileged --tty --interactive \
    --volume "$img:/images/image.img" \
    --volume "$path/set_pw.sh:/usr/local/bin/set_pw.sh" \
    --volume "$path/:/root/hostfolder" \
    $extra_volume \
    remmelt/docker-rpi-wifi-pw-setter \
$ssid $ssid_passwd $extra_script
