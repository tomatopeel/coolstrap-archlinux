#!/bin/bash

die() {
  if [[ ! -z "$1" ]]; then echo "Error: $1" >&2; fi
  echo "Exiting..." >&2; exit 1
}

PKGS="networkmanager i3-gaps i3blocks i3lock i3status xorg xorg-xinit git rxvt-unicode network-manager-applet"
sudo pacman -S --noconfirm --needed $PKGS || die

sudo systemctl enable NetworkManager

if [[ ! -d ~/dotfiles ]]; then
  git clone https://github.com/tomatopeel/dotfiles
fi

shopt -s dotglob
for f in ~/dotfiles/*; do
  if [[ -f "$HOME/${f##*/}" ]]; then
    rm -f "$HOME/${f##*/}"
  fi
  ln -s "$f" "$HOME/${f##*/}"
done

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
