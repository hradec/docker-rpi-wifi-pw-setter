FROM debian

MAINTAINER Remmelt Pit <remmelt@gmail.com>

RUN apt update
RUN apt install -y parted qemu-user-static

VOLUME ["/images"]

ADD set_pw.sh /usr/local/bin/set_pw.sh

ENTRYPOINT ["set_pw.sh", "image.img"]
