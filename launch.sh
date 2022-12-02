#!/bin/sh

workdir="$( mktemp -d )"
src="https://raw.githubusercontent.com/bulirma/albis/master"

wget -h >/dev/null || pacman --noconfirm --needed -Sy wget

wget "$src/download.sh" -O "$workdir/download.sh"

sh "$workdir/download.sh" "$workdir" "$src" || exit 1
clear
sh "$workdir/albis.sh" && clear

rm -rf "$workdir"

exit 0
