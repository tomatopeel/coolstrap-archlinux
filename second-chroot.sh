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

LN="$(grep -n '^HOOKS=' /etc/mkinitcpio.conf | cut -d: -f1)"
sed -i "${LN}d" /etc/mkinitcpio.conf
sed -i "${LN}iHOOKS=(base udev autodetect modconf block keymap keyboard encrypt filesystems fsck)" /etc/mkinitcpio.conf

mkinitcpio -p linux || error_exit "couldn't mkinitcpio"
pacman -S --noconfirm grub || error_exit "couldn't install grub package"

UUID="$(blkid -s UUID /dev/sdb2 | sed -e 's/^.*"\(.*\)"/\1/')"
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\".*\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet cryptdevice=UUID=$UUID:cryptroot root=\/dev\/mapper\/cryptroot\"/" /etc/default/grub

grub-install --force --target=i386-pc "$DEVICE" ||
  error_exit "couldn't install grub-install"

grub-mkconfig -o /boot/grub/grub.cfg ||
  error_exit "couldn't grub-mkconfig"

useradd -m -G wheel -s /bin/bash cooler
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
passwd cooler && passwd -l root
