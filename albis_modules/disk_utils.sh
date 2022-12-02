#!/bin/sh

# external vars:
# 	$target_device
# 	$mount_point

# Lists disks and outputs them to stdout.
list_disks() {
	lsblk -dlp | awk '/ (8|259):/ { print $1" ("$4")" }'
}

# This function is divided into three sections
# Partitioning ... parted is recommended to use
# Formatting
# Mounting ...for root mount point definition use the $mount_point variable
setup_disk() {
	# partitioning
	parted -s "$target_device" mklabel msdos \
		mkpart primary 2MiB 130MiB \
		mkpart primary 130MiB 2178MiB \
		mkpart primary 2178MiB 100%

	# formatting
	mkfs.fat -F32 "${target_device}1"
	mkswap "${target_device}2"
	swapon "${target_device}2"
	mkfs.ext4 "${target_device}3"

	# mounting
	mkdir -p "$mount_point"
	mount "${target_device}3" "$mount_point"
	mkdir "$mount_point/boot"
	mount "${target_device}1" "$mount_point/boot"
}
