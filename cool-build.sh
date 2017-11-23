#!/bin/bash

# add_packages FILE PKGS...
add_packages() {
  file="$1"
  shift 1
  printf "%s\n" "$@" >> "$file"
}

cwd=$(dirname $(readlink -f $0))
mkdir out; cd out

git clone https://git.archlinux.org/archiso.git
pkgsboth='archiso/configs/releng/packages.both'

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
      git clone https://github.com/monero-project/monero
      cd monero
      make
      ;;
  esac
done <<< "$selection"

#cd $cwd; rm -rf out

#echo "$selection" >> archiso/configs/releng/packages.both
#if [[ $selection == *"monero"* ]]; then
#  echo "It's there!"
#fi
