#!/bin/bash

error_exit() {
  echo "$0: $1" 1>&2
  exit 1
}

command -v haveged 1>/dev/null || error_exit "Please install haveged"

if [ -z "$DEVICE" ]; then
  error_exit "Please set DEVICE e.g.:\nDEVICE=/dev/sdb $0"
  exit 1
fi

if [ `id -u` != 0 ] ; then
  error_exit "Please run with root privileges"
fi


TIMEZONE=$(timedatectl | grep 'Time zone' | awk '{print $3}')
LOCALE=$(locale | grep 'LANG=' | sed 's/LANG=//')
DATE=$(date -d now '+%Y.%m')
MIRRURL=https://mirrors.kernel.org/archlinux/iso/latest
TARBALL=archlinux-bootstrap-"$DATE".01-x86_64.tar.gz

if [ ! -d "root.x86_64" ]; then
  if [ ! -f "$TARBALL" ]; then
    curl -O "$MIRRURL/$TARBALL"
  fi
  tar xzf "$TARBALL"
fi

LN=$(grep -n "## Worldwide" \
  root.x86_64/etc/pacman.d/mirrorlist | cut -d: -f1)
SEDEXP="$((LN+1)),$((LN+3)){s/#Server/Server/}"
sed -i "$SEDEXP" root.x86_64/etc/pacman.d/mirrorlist

cp first-chroot.sh root.x86_64/usr/bin/first-chroot.sh
root.x86_64/bin/arch-chroot root.x86_64 first-chroot.sh "$DEVICE"

echo "========== first-chroot complete =========="
sleep 1
umount "${DEVICE}1" || error_exit "couldn't umount ${DEVICE}1"
sleep 1
umount /dev/mapper/cryptroot || error_exit "couldn't umount ${DEVICE}2"
sleep 1
umount root.x86_64 2>/dev/null
sleep 1

mkdir mnt
mount /dev/mapper/cryptroot mnt || error_exit "couldn't mount ${DEVICE}2"
sleep 1
mount "${DEVICE}1" mnt/boot || error_exit "couldn't mount ${DEVICE}1"
sleep 1

root.x86_64/usr/bin/genfstab -U mnt > mnt/etc/fstab

cp second-chroot.sh mnt/usr/bin/second-chroot.sh
root.x86_64/bin/arch-chroot mnt second-chroot.sh \
  "$DEVICE" "$TIMEZONE" "$LOCALE"

echo "========== second-chroot complete =========="
sleep 1

rsync -a scripts mnt/home/cooler/

umount "${DEVICE}1" || error_exit "couldn't umount ${DEVICE}1"
sleep 1
umount /dev/mapper/cryptroot || error_exit "couldn't umount ${DEVICE}2"
sleep 1
umount mnt 2>/dev/null
cryptsetup close cryptroot

echo DONE
