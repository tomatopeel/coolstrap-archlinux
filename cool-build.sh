#!/bin/bash

# add_packages FILE PKGS...
add_packages() {
  file="$1"
  shift 1
  printf "%s\\n" "$@" >> "$file"
}

build_monero() {
  git clone https://aur.archlinux.org/monero.git
  cd monero || return
  PKGDEST="$localrepo" makepkg
}

wd="$(dirname "$(readlink -f "$0")")/out"
mkdir "$wd"; cd "$wd" || exit
localrepo="$wd/localrepo"
mkdir "$localrepo"

git clone https://git.archlinux.org/archiso.git
relengdir="$wd/archiso/configs/releng"
pkgsboth="$relengdir/packages.both"

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
      build_monero
      add_packages "$pkgsboth" monero
      ;;
  esac
done <<< "$selection"

cd "$localrepo" || exit
for file in ./*; do
  repo-add localrepo.db.tar.gz "$file"
done

cd "$relengdir" || exit
rm airootfs/etc/udev/rules.d/81-dhcpcd.rules
cat >> pacman.conf <<EOF
[localrepo]
SigLevel = Optional TrustAll
Server = file://$localrepo
EOF

mkdir out
sudo ./build.sh -v

iso=$(ls ./out)
sudo mv "out/$iso" "$wd"
cd "$wd" || exit
sudo find . ! -name "$iso" -type f -o -type d -exec rm -rf {} +
