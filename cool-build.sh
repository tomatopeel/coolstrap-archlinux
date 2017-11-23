#!/bin/bash

# add_packages FILE PKGS...
add_packages() {
  file="$1"
  shift 1
  printf "%s\n" "$@" >> "$file"
}

wd="$(dirname $(readlink -f $0))/out"
mkdir $wd; cd $wd

git clone https://git.archlinux.org/archiso.git
pkgsboth="$wd/archiso/configs/releng/packages.both"

selection=$(whiptail --title "Software Selection" --checklist \
  "Please select the desired wallet software to install" 20 78 3 \
  "btc_core" "Bitcoin Core" ON \
  "btc_electrum" "Electrum" ON \
  "xmr" "Monero" ON \
  3>&1 1>&2 2>&3 | sed 's/"//g' | sed 's/ /\n/g')

while read -r line; do
  case $line in
    btc_core)
      add_packages "$pkgsboth" bitcoin-cli bitcoin-daemon
      ;;
    btc_electrum)
      add_packages "$pkgsboth" electrum
      ;;
    xmr)
      git clone https://aur.archlinux.org/monero.git
      cd monero
      localrepo="$wd/localrepo"
      mkdir $localrepo
      MAKEFLAGS="-j$(nproc)" PKGDEST="$localrepo" makepkg
      ;;
  esac
done <<< "$selection"
