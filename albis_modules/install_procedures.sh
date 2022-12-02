#!/bin/sh

# external vars:
# 	$boot
# 	$target_device
# 	$init_system
# 	$mount_point
# 	$username
# 	$password
# 	$root_password
# 	$user_source_directory

# $1 ... init system
base_install() {
	_packages="
		base
		linux
		linux-firmware
		$init_system
		elogind-$init_system
		connman
		connman-$init_system
		grub
		wget
		sudo
	"
	basestrap "$mount_point" $( echo "$_packages" | xargs )
	fstabgen -U "$mount_point" >>"$mount_point/etc/fstab"
	unset _packages
}

install() {
	pacman --noconfirm --needed -S "$@" || return 1
}

install_dotfiles() {
	_temp_dir="$( sudo -u "$username" mktemp -d )"
	sudo -u "$username" git clone --depth 1 "$1" "$_temp_dir"
	sudo -u "$username" cp -rfT "$_temp_dir" "/home/$username"
	rm -rf "$_temp_dir"
	unset _temp_dir
}

base_config() {
	# time
	ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime
	hwclock --systohc

	# locale
	echo "
### Locales added by installation script
	
en_US.UTF-8 UTF-8
en_US ISO-8859-1" >>/etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" >/etc/locale.conf

	# host
	echo "$hostname" >/etc/hostname
	if [ "$init_system" = "openrc" ]; then
		echo "hostname=$hostname" >>/etc/conf.d/hostname
	fi
	echo "
127.0.0.1	localhost
::1		localhost
127.0.0.1	$hostname.localdomain $hostname" >>/etc/hosts

	# networking
	case "$init_system" in
		"openrc")
			rc-update add connmand
			;;
		"runit")
			ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default
			;;
		"*")
			return 1
			;;
	esac

	# bootloader
	case "$boot" in
		"legacy")
			grub-install --target=i386-pc "$target_device"
			;;
		"efi")
			grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub "$target_device"
			;;
		"*")
			return 1
			;;
	esac
	grub-mkconfig -o /boot/grub/grub.cfg
}

set_users() {
	# root password
	echo "root:$root_password" | chpasswd

	# user
	useradd -mG wheel -s /bin/bash "$username"
	echo "$username:$password" | chpasswd

	sudo -u "$username" mkdir -p "/home/$username/$user_source_directory"
}

# get rid of that horrible sound
system_beep_off() {
	rmmod pcspkr
	echo "blacklist pcspkr" >/etc/modprobe.d/nobeep.conf
}
