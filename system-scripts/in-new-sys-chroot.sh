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
sed -i "${LN}iHOOKS=(base udev autodetect modconf keyboard keymap block encrypt filesystems fsck)" /etc/mkinitcpio.conf

LN="$(grep -n '^MODULES=' /etc/mkinitcpio.conf | cut -d: -f1)"
sed -i "${LN}d" /etc/mkinitcpio.conf
sed -i "${LN}iMODULES=(ext4 virtio virtio_blk virtio_pci virtio_net)" /etc/mkinitcpio.conf

LN="$(grep -n '^FILES=' /etc/mkinitcpio.conf | cut -d: -f1)"
sed -i "${LN}d" /etc/mkinitcpio.conf
sed -i "${LN}iFILES=(/crypto_keyfile.bin)" /etc/mkinitcpio.conf

dd bs=512 count=4 if=/dev/urandom of=/crypto_keyfile.bin || die
chmod 000 /crypto_keyfile.bin || die
chmod 600 /boot/initramfs-linux* || die
cryptsetup luksAddKey "${DEVICE}1" /crypto_keyfile.bin || die

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
