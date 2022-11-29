#!/bin/sh

workdir="$1"
[ -d "$workdir" ] || {
	echo "[Error]
Missing working directory path as the first argument."
	exit 1
}
src="$2"

wget -h >/dev/null || pacman --noconfirm --needed -Sy wget

wget "$src/albis.sh" -O "$workdir/albis.sh"
wget "$src/options.sh" -O "$workdir/options.sh"
