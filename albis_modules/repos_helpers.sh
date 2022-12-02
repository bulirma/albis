#!/bin/sh

include_universe_repo() {
	if ! grep -q "^\[universe\]" /etc/pacman.conf; then
		echo "
[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/" >>/etc/pacman.conf
		pacman --noconfirm -Sy
		pacman-key --init
	fi
}

enable_arch_repos() {
	wget https://github.com/archlinux/svntogit-packages/raw/packages/pacman-mirrorlist/trunk/mirrorlist -O /etc/pacman.d/mirrorlist-arch
	# uncomment servers for specified country
	_temp_list="$( mktemp )"
	awk -v country="Czechia" '/^ *$/ { p = 0; } // { line = $0; } /^#.*/ { if (p == 1) { sub("^#+", "", line); } } // { print line; } $0 ~ country { p = 1; }' /etc/pacman.d/mirrorlist-arch >"$_temp_list"
	cp "$_temp_list" /etc/pacman.d/mirrorlist-arch
	rm -f "$_temp_list"
	pacman --noconfirm --needed -S \
		artix-keyring artix-archlinux-support
	for _repo in extra community multilib; do
		grep -q "^\[$_repo\]" /etc/pacman.conf ||
			echo "
[$_repo]
Include = /etc/pacman.d/mirrorlist-arch" >>/etc/pacman.conf
	done
	pacman --noconfirm -Sy
	pacman-key --populate archlinux
	unset _temp_list
}
