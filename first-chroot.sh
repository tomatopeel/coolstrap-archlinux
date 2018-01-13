#!/bin/bash

error_exit() {
  echo "$0: $1" 1>&2
  exit 1
}

DEVICE="$1"

cryptsetup open "${DEVICE}2" cryptroot ||
  error_exit "$LINENO: couldn't cryptsetup open ${DEVICE}2"

mount /dev/mapper/cryptroot /mnt ||
  error_exit "$LINENO: couldn't mount cryptroot to /mnt"

mkdir /mnt/boot && mount "${DEVICE}1" /mnt/boot ||
  error_exit "$LINENO: couldn't mount ${DEVICE}1 to /mnt/boot"

pacman-key --init
pacman-key --populate archlinux

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 3 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

pacman --noconfirm -Syuu

PKGS="arch-install-scripts sudo rsync pinentry pass jq lxde"
pacstrap /mnt base $PKGS
