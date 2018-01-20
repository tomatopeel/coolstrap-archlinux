#!/bin/bash

die() {
	if [[ ! -z "$1" ]]; then echo "Error: $1" >&2; fi
	echo "Exiting..." >&2; exit 1
}

DEVICE="$1"
TIMEZONE="$2"
LOCALE="$3"
HOSTN="$4"
USER_NAME="$5"
read -r USER_PW

ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime ||
  die "couldn't link timezone"

hwclock --systohc || die "couldn't hwclock"

LN="$(grep -in "^#$LOCALE" /etc/locale.gen | cut -d: -f1)"
sed -i "${LN}s/^#//" /etc/locale.gen ||
  die "couldn't sed locale"

echo "LANG=$LOCALE" > /etc/locale.conf

locale-gen || die "couldn't locale-gen"

echo "$HOSTN" > /etc/hostname 

LN="$(grep -n '^HOOKS=' /etc/mkinitcpio.conf | cut -d: -f1)"
sed -i "${LN}d" /etc/mkinitcpio.conf
sed -i "${LN}iHOOKS=(base udev autodetect modconf block keymap keyboard encrypt filesystems fsck)" /etc/mkinitcpio.conf

LN="$(grep -n '^MODULES=' /etc/mkinitcpio.conf | cut -d: -f1)"
sed -i "${LN}d" /etc/mkinitcpio.conf
sed -i "${LN}iMODULES=(virtio virtio_blk virtio_pci virtio_net)" /etc/mkinitcpio.conf

mkinitcpio -p linux || die "couldn't mkinitcpio"
pacman -S --noconfirm grub || die "couldn't install grub package"

UUID="$(blkid -s UUID "${DEVICE}1" | sed -e 's/^.*"\(.*\)"/\1/')"
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\".*\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet cryptdevice=UUID=$UUID:cryptroot root=\/dev\/mapper\/cryptroot\"/" /etc/default/grub
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub

grub-install --force --target=i386-pc "$DEVICE" ||
  die "couldn't install grub-install"

grub-mkconfig -o /boot/grub/grub.cfg ||
  die "couldn't grub-mkconfig"

useradd -m -G wheel -s /bin/bash "$USER_NAME"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "$USER_NAME:$USER_PW" | chpasswd &&
	passwd -l root
