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
"${DEVICE}2" : start=     1026048, size=     6291456, type=83
EOF

mkfs.ext4 -F "${DEVICE}1" || error_exit "couldn't mkfs"
mkfs.ext4 -F "${DEVICE}2" || error_exit "couldn't mkfs"

mount "${DEVICE}2" /mnt || error_exit "couldn't mount ${DEVICE}2"
mkdir /mnt/boot || error_exit "couldn't mkdir"
mount "${DEVICE}1" /mnt/boot || error_exit "couldn't mount ${DEVICE}1"

pacman-key --init
pacman-key --populate archlinux
pacman -Syyu --noconfirm
pacstrap /mnt base
