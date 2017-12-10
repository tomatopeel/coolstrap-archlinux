#!/bin/bash

error_exit() {
  echo "$0: $1" 1>&2
  exit 1
}

DEVICE="$1"
TIMEZONE="$2"
LOCALE="$3"
HOSTNAME=cooler

ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime ||
  error_exit "couldn't link timezone"

hwclock --systohc || error_exit "couldn't hwclock"

cat /etc/locale.gen | grep "$LOCALE"
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen ||
  error_exit "couldn't sed locale"

cat /etc/locale.gen | grep "$LOCALE"
echo "LANG=$LOCALE" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname

mkinitcpio -p linux || error_exit "couldn't mkinitcpio"
pacman -S --noconfirm grub || error_exit "couldn't install grub package"

grub-install --force --target=i386-pc "$DEVICE" ||
  error_exit "couldn't install grub-install"

grub-mkconfig -o /boot/grub/grub.cfg ||
  error_exit "couldn't grub-mkconfig"

useradd -m -G wheel -s /bin/bash cooler
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers
