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
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\".*\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet cryptdevice=UUID=$UUID:part2 root=\/dev\/mapper\/part2\"/" /etc/default/grub
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub

grub-install --force --target=i386-pc "$DEVICE" ||
  die "couldn't install grub-install"

grub-mkconfig -o /boot/grub/grub.cfg ||
  die "couldn't grub-mkconfig"

useradd -m -G wheel -s /bin/bash "$USER_NAME"
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "$USER_NAME:$USER_PW" | chpasswd &&
	passwd -l root
