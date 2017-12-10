#!/bin/bash

error_exit() {
  echo "$0: $1" 1>&2
  exit 1
}

DEVICE="$1"

sfdisk "$DEVICE" << EOF
label: dos
device: "$DEVICE"
unit: sectors

"${DEVICE}1" : start=        2048, size=     1024000, type=83, bootable
"${DEVICE}2" : start=     1026048, size=     4194304, type=83
"${DEVICE}3" : start=     5220352, size=     2097152, type=83
EOF
sleep 1

mkfs.ext4 -F "${DEVICE}1" || error_exit "$LINENO: couldn't mkfs"
sleep 1
mkfs.ext4 -F "${DEVICE}2" || error_exit "$LINENO: couldn't mkfs"
sleep 1
mkfs.ext4 -F "${DEVICE}3" || error_exit "$LINENO: couldn't mkfs"
sleep 1

dd if=/dev/zero of="$DEVICE" seek=1 count=2047
sleep 1

mount "${DEVICE}2" /mnt || error_exit "couldn't mount ${DEVICE}2"
mkdir /mnt/boot || error_exit "couldn't mkdir"
mount "${DEVICE}1" /mnt/boot || error_exit "couldn't mount ${DEVICE}1"
mkdir /mnt/home || error_exit "couldn't mkdir"
mount "${DEVICE}3" /mnt/home || error_exit "couldn't mount ${DEVICE}3"

pacman-key --init
pacman-key --populate archlinux

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 3 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

pacman --noconfirm -Syuu

PKGS="arch-install-scripts sudo rsync pinentry pass jq bitcoin-cli bitcoin-daemon"
pacstrap /mnt base $PKGS
