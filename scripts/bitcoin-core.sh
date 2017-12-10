#!/bin/bash

error_exit() {
  echo "$0: $1" 1>&2
  exit 1
}

repeat-try() {
  n=0
  until [ $n -ge 5 ]
  do
    "$@" && return
    n=$[$n+1]
    printf "%s\nTrying again, attempt #$n...\n" "$msg"
    sleep "$n"
  done
  error_exit "$msg"
}

PASS_KEY=cold-btc
pass generate "$PASS_KEY" -f 32 1>/dev/null 2>&1 ||
  error_exit "$LINENO: Couldn't gen pw"
PW=$(pass "$PASS_KEY" || error_exit "$LINENO: couldn't get pw")

DATADIR="$(pwd)/data"
mkdir "$DATADIR" || error_exit "$LINENO: couldn't mkdir data"

msg="$((LINENO+1)): couldn't start bitcoind"
repeat-try bitcoind -daemon -datadir="$DATADIR"

msg="$((LINENO+1)): couldn't encryptwallet"
repeat-try bitcoin-cli -datadir="$DATADIR" encryptwallet "$PW"

msg="$((LINENO+1)): couldn't start bitcoind"
repeat-try bitcoind -daemon -datadir="$DATADIR"

msg="$((LINENO+1)): couldn't walletpassphrase"
repeat-try bitcoin-cli -datadir="$DATADIR" walletpassphrase "$PW" 300

msg="$((LINENO+1)): couldn't backupwallet"
repeat-try bitcoin-cli -datadir="$DATADIR" backupwallet backup.dat

msg="$((LINENO+1)): couldn't stop"
repeat-try bitcoin-cli -datadir="$DATADIR" stop

msg="$((LINENO+1)): couldn't cp"
cp -f backup.dat "$DATADIR/wallet.dat" || error_exit "$msg"

msg="$((LINENO+1)): couldn't start bitcoind"
repeat-try bitcoind -daemon -datadir="$DATADIR"

msg="$((LINENO+1)): couldn't walletpassphrase"
repeat-try bitcoin-cli -datadir="$DATADIR" walletpassphrase "$PW" 300

msg="$((LINENO+1)): couldn't stop"
repeat-try bitcoin-cli -datadir="$DATADIR" listreceivedbyaddress 0 true |
  jq .[].address -r > addrs
