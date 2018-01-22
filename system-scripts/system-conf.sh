#!/bin/bash

if [[ ! "$(pacman -Qi sudo)" ]]; then
  pacman -S --noconfirm sudo
fi

if [[ ! "$(grep -P '^%wheel ALL=\(ALL\) NOPASSWD: ALL' /etc/sudoers)" ]]; then
  echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
