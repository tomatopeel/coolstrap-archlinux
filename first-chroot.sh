#!/bin/bash

error_exit() {
  echo "$0: $1" 1>&2
  exit 1
}

DEVICE="$1"

#dd if=/dev/zero of="$DEVICE" seek=1 count=2047
#sleep 1
#
#dd if=/dev/urandom of="$DEVICE" seek=2048 status=progress
#sleep 1

sfdisk "$DEVICE" << EOF
1MiB,500MiB,L,*
-,-,L,-
EOF
sleep 1

mkfs.ext4 -F "${DEVICE}1" || error_exit "$LINENO: couldn't mkfs"
sleep 1

cryptsetup -y -v luksFormat "${DEVICE}2" &&
  cryptsetup open "${DEVICE}2" cryptroot &&
  mkfs.ext4 /dev/mapper/cryptroot &&
  mount /dev/mapper/cryptroot /mnt ||
  error_exit "$LINENO: couldn't cryptsetup/mkfs/mount ${DEVICE}2"

mkdir /mnt/boot && mount "${DEVICE}1" /mnt/boot ||
  error_exit "$LINENO: couldn't mount ${DEVICE}1 to /mnt/boot"

pacman-key --init
pacman-key --populate archlinux

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 3 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

pacman --noconfirm -Syuu

PKGS="arch-install-scripts sudo rsync pinentry pass jq bitcoin-cli bitcoin-daemon"
pacstrap /mnt base $PKGS
