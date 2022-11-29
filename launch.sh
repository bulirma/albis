#!/bin/sh

workdir="$( mktemp -d )"
#src="http://192.168.42.101"
src="http://192.168.88.250"

wget -h >/dev/null || pacman --noconfirm --needed -Sy wget

wget "$src/download.sh" -O "$workdir/download.sh"

sh "$workdir/download.sh" "$workdir" "$src" || exit 1
sh "$workdir/albis.sh"

rm -rf "$workdir"
