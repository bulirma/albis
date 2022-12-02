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
mkdir -p "$workdir/albis_modules"
wget "$src/albis_modules/options.sh" -O "$workdir/albis_modules/options.sh"
wget "$src/albis_modules/albis_config.sh" -O "$workdir/albis_modules/albis_config.sh"
wget "$src/albis_modules/albis_dependencies.sh" -O "$workdir/albis_modules/albis_dependencies.sh"
wget "$src/albis_modules/disk_utils.sh" -O "$workdir/albis_modules/disk_utils.sh"
wget "$src/albis_modules/install_procedures.sh" -O "$workdir/albis_modules/install_procedures.sh"
wget "$src/albis_modules/options.sh" -O "$workdir/albis_modules/options.sh"
wget "$src/albis_modules/postinstall.sh" -O "$workdir/albis_modules/postinstall.sh"
wget "$src/albis_modules/repos_helpers.sh" -O "$workdir/albis_modules/repos_helpers.sh"
