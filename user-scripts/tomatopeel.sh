#!/bin/bash

die() {
  if [[ ! -z "$1" ]]; then echo "Error: $1" >&2; fi
  echo "Exiting..." >&2; exit 1
}

PKGS="networkmanager i3-gaps i3blocks i3lock i3status xorg xorg-xinit git rxvt-unicode network-manager-applet rofi ttf-ubuntu-font-family ttf-font-awesome pass autocutsel gnome-keyring chromium gtk2"
sudo pacman -S --noconfirm --needed $PKGS || die

sudo systemctl enable NetworkManager

if [[ ! -d ~/dotfiles ]]; then
  git clone -b coolstrap https://github.com/tomatopeel/dotfiles
fi

shopt -s dotglob
for f in ~/dotfiles/*; do
  if [[ "${f##*/}" == ".git" ]]; then continue; fi
  if [[ -f "$HOME/${f##*/}" ]]; then
    rm -f "$HOME/${f##*/}"
  fi
  ln -s "$f" "$HOME/${f##*/}"
done

systemctl --user enable urxvtd

#USER_NAME="$1"
#HOME="/home/$USER_NAME"
#
#if [[ ! -d "$HOME" ]]; then
#  die "$HOME not found"
#fi
#
#git clone 
#
#chown -R "$USER_NAME:$USER_NAME" "$HOME"
