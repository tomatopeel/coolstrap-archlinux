#!/bin/bash

die() {
	if [[ ! -z "$1" ]]; then echo "Error: $1" >&2; fi
	echo "Exiting..." >&2; exit 1
}

read -r BD_PW
DEVICE="$1"

for i in 1 2; do
  echo -n "$BD_PW" | cryptsetup open "$DEVICE$i" "part$i" - ||
    die "$LINENO: couldn't cryptsetup open $DEVICE$i"
done

mount /dev/mapper/part2 /mnt ||
  die "$LINENO: couldn't mount part2 to /mnt"

mkdir /mnt/boot && mount /dev/mapper/part1 /mnt/boot ||
  die "$LINENO: couldn't mount ${DEVICE}1 to /mnt/boot"

pacman-key --init
pacman-key --populate archlinux

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
rankmirrors -n 3 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

pacman --noconfirm -Syuu

PKGS="base arch-install-scripts sudo rsync"
pacstrap /mnt $PKGS

for i in 1 2; do
  umount "/dev/mapper/part$i" || die "couldn't umount part$i"
done

exit 0
