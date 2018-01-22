#!/bin/bash

die() {
  if [[ ! -z "$1" ]]; then echo "Error: $1" >&2; fi
  echo "Exiting..." >&2; exit 1
}

USER_NAME="$1"

useradd -m -G wheel -s /bin/bash "$USER_NAME" || die
passwd "$USER_NAME" || die
