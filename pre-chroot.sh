#!/bin/bash

error_exit() {
  echo "$0: $1" 1>&2
  exit 1
}

command -v haveged || error_exit "Please install haveged"

if [ -z "$DEVICE" ]; then
  error_exit "Please set DEVICE e.g.:\nDEVICE=/dev/sdb $0"
  exit 1
fi

if [ `id -u` != 0 ] ; then
  error_exit "Please run with root privileges"
fi


DATE=$(date -d now '+%Y.%m')
MIRRURL=https://mirrors.kernel.org/archlinux/iso/latest
TARBALL=archlinux-bootstrap-"$DATE".01-x86_64.tar.gz

if [ ! -d "root.x86_64" ]; then
  if [ ! -f "$TARBALL" ]; then
    curl -O "$MIRRURL/$TARBALL"
  fi
  tar xzf "$TARBALL"
fi

LN=$(grep -n '## Worldwide' \
  root.x86_64/etc/pacman.d/mirrorlist | cut -d: -f1)
SEDEXP="$((LN+1)),$((LN+3)){s/#Server/Server/}"
sed -i "$SEDEXP" root.x86_64/etc/pacman.d/mirrorlist

cp post-chroot.sh root.x86_64/usr/bin/
root.x86_64/bin/arch-chroot root.x86_64 first-chroot.sh "$DEVICE"

TIMEZONE=$(timedatectl | grep 'Time zone' | awk '{print $3}')
LOCALE=$(locale | grep 'LANG=' | sed 's/LANG=//')
root.x86_64/bin/arch-chroot root.x86_64/mnt second-chroot.sh "$TIMEZONE" "$LOCALE"
