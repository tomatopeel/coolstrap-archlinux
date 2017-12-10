## Cooler

*Disclaimer: This is a WIP and I am new/naive, so there may be some huge security flaws with this general approach, don't trust anything. If in doubt, buy a Trezor.*

Build scripts for Archlinux-based GNU/Linux *persistent* live USB system(s); intended, for now, to be ran offline to generate wallets i.e. wallet files, HD/mnemonic seeds, private keys etc.

It's just some horrible shell scripts (my first half-serious shell script project, code reviews welcome) but this comes with the following perks:

* Uses a bootstrap/chroot approach, so builds can (hopefully) be performed on any GNU/Linux (tested on Ubuntu 16.04). Perhaps it'd be possible to make this portable to BSD's too? TBC.
* Very easy to add further wallet software and security functionality.
* Very easy to duplicate across cheap media (USB thumb drives) for redundancy and poverty.
* All-in-one


To Do's:

* Cold transaction scripts
* Encrypted volumes

### Get Started

1. `sudo DEVICE=/dev/sdX ./main.sh` where X is your block device.
2. Reboot from the device.
3. `scripts/init-gpg.sh`
4. `pass init [your gpg-id]`
5. `scripts/bitcoin.sh`
