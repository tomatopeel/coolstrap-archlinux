#!/bin/bash

cwd=$(dirname $(readlink -f $0))

selection=$(whiptail --title "Software Selection" --checklist \
  "Please select the desired wallet software to install" 20 78 3 \
  "bitcoin-cli bitcoin-daemon" "Bitcoin Core" ON \
  "monero" "Monero" ON \
  "electrum" "Electrum" ON \
  3>&1 1>&2 2>&3 | sed 's/"//g' | sed 's/ /\n/g')

while read -r line; do
  case $line in
    monero)
      git clone https://github.com/monero-project/monero
      cd monero
      make
      ;;
    bitcoin-cli)
      echo "bitcoin core!"
      ls
      ;;
    electrum)
      echo "electrum!"
      ls
      ;;
  esac
done <<< "$selection"

#echo "$selection" >> archiso/configs/releng/packages.both
#if [[ $selection == *"monero"* ]]; then
#  echo "It's there!"
#fi
