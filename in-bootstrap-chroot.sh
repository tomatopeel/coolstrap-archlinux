#!/bin/bash

die() {
	if [[ ! -z "$1" ]]; then echo "Error: $1" >&2; fi
	echo "Exiting..." >&2; exit 1
}

DEVICE="$1"
BD_PW="$2"

echo -n "$BD_PW" | cryptsetup open "${DEVICE}2" cryptroot - ||
  die "$LINENO: couldn't cryptsetup open ${DEVICE}2"

mount /dev/mapper/cryptroot /mnt ||
  die "$LINENO: couldn't mount cryptroot to /mnt"

mkdir /mnt/boot && mount "${DEVICE}1" /mnt/boot ||
  die "$LINENO: couldn't mount ${DEVICE}1 to /mnt/boot"

pacman-key --init
pacman-key --populate archlinux

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 3 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

pacman --noconfirm -Syuu

PKGS="base arch-install-scripts sudo rsync"
pacstrap /mnt $PKGS

umount "${DEVICE}1" || die "couldn't umount ${DEVICE}1"
umount /dev/mapper/cryptroot || die "couldn't umount cryptroot"

exit 0
