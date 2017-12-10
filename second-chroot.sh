#!/bin/bash

DEVICE="$1"
TIMEZONE="$2"
LOCALE="$3"
HOSTNAME=cooler

echo "TIMEZONE: $TIMEZONE"
echo "LOCALE: $LOCALE"
ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc

cat /etc/locale.gen | grep "$LOCALE"
sed -i "s/#$LOCALE/$LOCALE/" /etc/locale.gen
cat /etc/locale.gen | grep "$LOCALE"
echo "LANG=$LOCALE" > /etc/locale.conf

echo "$HOSTNAME" > /etc/hostname

mkinitcpio -p linux
pacman -S --noconfirm grub
grub-install --target=i386-pc "$DEVICE"
grub-mkconfig -o /boot/grub/grub.cfg
