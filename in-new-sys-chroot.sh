#!/bin/bash

die() {
	if [[ ! -z "$1" ]]; then echo "Error: $1" >&2; fi
	echo "Exiting..." >&2; exit 1
}

DEVICE="$1"
TIMEZONE="$2"
LOCALE="$3"
HOSTN="$4"
USERNAME="$5"
PASSWORD="$6"

ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime ||
  die "couldn't link timezone"

hwclock --systohc || die "couldn't hwclock"

cat /etc/locale.gen | grep "$LOCALE"
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen ||
  die "couldn't sed locale"

cat /etc/locale.gen | grep "$LOCALE"
echo "LANG=$LOCALE" > /etc/locale.conf

echo "$HOSTN" > /etc/hostname 

LN="$(grep -n '^HOOKS=' /etc/mkinitcpio.conf | cut -d: -f1)"
sed -i "${LN}d" /etc/mkinitcpio.conf
sed -i "${LN}iHOOKS=(base udev autodetect modconf block keymap keyboard encrypt filesystems fsck)" /etc/mkinitcpio.conf

mkinitcpio -p linux || die "couldn't mkinitcpio"
pacman -S --noconfirm grub || die "couldn't install grub package"

UUID="$(blkid -s UUID "${DEVICE}2" | sed -e 's/^.*"\(.*\)"/\1/')"
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\".*\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet cryptdevice=UUID=$UUID:cryptroot root=\/dev\/mapper\/cryptroot\"/" /etc/default/grub

grub-install --force --target=i386-pc "$DEVICE" ||
  die "couldn't install grub-install"

grub-mkconfig -o /boot/grub/grub.cfg ||
  die "couldn't grub-mkconfig"

useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "$USERNAME:$PASSWORD" | chpasswd &&
	passwd -l root
