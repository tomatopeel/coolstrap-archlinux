#!/bin/bash

cat << EOF >> ~/.bashrc
export GPG_TTY=$(tty)
EOF

gpg --gen-key --pinentry-mode loopback

cat << EOF >> ~/.gnupg/gpg-agent.conf
pinentry-program /usr/bin/pinentry-curses
EOF
