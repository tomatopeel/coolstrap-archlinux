#!/bin/bash

die() {
  if [[ ! -z "$1" ]]; then echo "Error: $1" >&2; fi
  echo "Exiting..." >&2; exit 1
}

PKGS="networkmanager i3 xorg xorg-xinit"
pacman -S --noconfirm $PKGS | die

systemctl enable NetworkManager

USER_NAME="$1"
HOME="/home/$USER_NAME"

if [[ ! -d "$HOME" ]]; then
  die "$HOME not found"
fi

git clone 

chown -R "$USER_NAME:$USER_NAME" "$HOME"
