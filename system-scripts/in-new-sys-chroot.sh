#!/bin/bash

die() {
	if [[ ! -z "$1" ]]; then echo "Error: $1" >&2; fi
	echo "Exiting..." >&2; exit 1
}

DEVICE="$1"
TIMEZONE="$2"
LOCALE="$3"
HOST_NAME="$4"
CRYPTROOT="$5"

ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime ||
  die "couldn't link timezone"

hwclock --systohc || die "couldn't hwclock"

LN="$(grep -in "^#$LOCALE" /etc/locale.gen | cut -d: -f1)"
sed -i "${LN}s/^#//" /etc/locale.gen ||
  die "couldn't sed locale"

echo "LANG=$LOCALE" > /etc/locale.conf

locale-gen || die "couldn't locale-gen"

echo "$HOST_NAME" > /etc/hostname 

LN="$(grep -n '^HOOKS=' /etc/mkinitcpio.conf | cut -d: -f1)"
sed -i "${LN}d" /etc/mkinitcpio.conf
sed -i "${LN}iHOOKS=(base udev autodetect modconf block keymap keyboard encrypt filesystems fsck)" /etc/mkinitcpio.conf

LN="$(grep -n '^MODULES=' /etc/mkinitcpio.conf | cut -d: -f1)"
sed -i "${LN}d" /etc/mkinitcpio.conf
sed -i "${LN}iMODULES=(virtio virtio_blk virtio_pci virtio_net)" /etc/mkinitcpio.conf

mkinitcpio -p linux || die "couldn't mkinitcpio"
pacman -S --noconfirm grub || die "couldn't install grub package"

UUID="$(blkid -s UUID "${DEVICE}1" | sed -e 's/^.*"\(.*\)"/\1/')"
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\".*\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet cryptdevice=UUID=$UUID:$CRYPTROOT root=\/dev\/mapper\/$CRYPTROOT\"/" /etc/default/grub
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub

grub-install --force --target=i386-pc "$DEVICE" ||
  die "couldn't install grub-install"

grub-mkconfig -o /boot/grub/grub.cfg ||
  die "couldn't grub-mkconfig"

passwd -l root || die
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers || die
