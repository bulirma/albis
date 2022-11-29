#!/bin/sh


intro() {
	echo "
  #                                     #
 #+#####################################+#
  #                                     # 
  #           .:     :                  #
  #            :     :      .           #
  #      ...   +     +           ...    #
  #     +  +   +     +++.   +   +       #      
  #    +   +   #     #  #   +    **+    #
  #    #==#|   ###   +##*   #   ==+     #
  #                                     # 
 #+#####################################+#
  #                                     #

Artix Linux Bootstrapping Installation Script(s).
"
}


# Lists disks and outputs them to stdout.
list_disks() {
	lsblk -dlp | awk '/ (8|259):/ { print $1" ("$4")" }'
}


list_timezones() {
	_workdir="$PWD"
	cd /usr/share/zoneinfo
	find -type f -not -path "*/posix/*" -not -path "*/right/*" \
		-not -name "*.*" | cut -c3-
	cd "$_workdir"
	unset _workdir
}


# Accepts input matching the regex.
# $1 ... regex
read_matching() {
	while ! echo "$_string" | grep -q "$1"; do
		_string="$( $gum input --placeholder "$1" )"
	done
	echo "$_string"
}


# $1 ... a user for whom the password is set
get_password() {
	while true; do
		_password="$( $gum input --password --placeholder "New $1's password..." )"
		[ -z "$_password" ] && continue
		_conf_pass="$( $gum input --password --placeholder "Retype the password..." )"
		if [ "$_password" = "$_conf_pass" ]; then
			break
		fi
		echo "Passwords do not match."
	done
	echo "$_password"
	unset _password _conf_pass
}


read_config() {
	# username
	if [ -z "$username" ]; then
		echo "Type your desired username:"
		username="$( read_matching ".\+" )"
		echo "$username"
	fi
	
	# password
	password="$( get_password "$username" )"
	_same=false
	$gum confirm "Use same password for root?" && _same=true
	if $_same; then
		root_password="$password"
	else
		root_password="$( get_password root )"
	fi
	unset _same

	if [ -z "$hostname" ]; then
		echo "Type hostname:"
		hostname="$( read_matching ".\+" )"
		echo "$hostname"
	fi

	if [ -z "$init_system" ]; then
		echo "Choose init system:"
		init_system="$( echo "$init_systems" | $gum choose )"
		echo "$init_system"
	fi

	if [ -z "$boot" ]; then
		echo "Choose init system:"
		boot="$( echo "$boot_options" | $gum choose )"
		echo "$boot"
	fi

	if [ -z "$target_device" ]; then
		echo "Choose disk on which the system will be installed:"
		target_device="$( list_disks | $gum choose | cut -d' ' -f1 )"
		echo "$target_device"
	fi

	if [ -z "$timezone" ]; then
		timezone="$( list_timezones | $gum filter --placeholder "Select timezone..." )"
		echo "Timezone:"
		echo "$timezone"
	fi

	# todo: URL/URI validation
	if [ -z "$dotfiles_repository" ]; then
		dotfiles_repository="$( $gum input --placeholder "Dotfiles repository URL/URI...")"
		echo "Dotfiles repository:"
		echo "$dotfiles_repository"
	fi
}


# Outputs variable definition to stdout.
save_var() {
	_value="$( eval echo "\$$1" )"
	printf '%s="%s"\n' "$1" "$_value"
	unset _value
}


save_config() {
	save_var username
	save_var hostname
	save_var init_system
	save_var boot
	save_var target_device
	save_var timezone
	save_var dotfiles_repository
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
	temp_list="$( mktemp )"
	awk -v country="Czechia" '/^ *$/ { p = 0; } // { line = $0; } /^#.*/ { if (p == 1) { sub("^#+", "", line); } } // { print line; } $0 ~ country { p = 1; }' /etc/pacman.d/mirrorlist-arch >"$temp_list"
	cp "$temp_list" /etc/pacman.d/mirrorlist-arch
	rm -f "$temp_list"
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

postinstall_config() {
	# sudoers
	echo "%wheel ALL=(ALL:ALL) ALL" >/etc/sudoers.d/00-albis

	# startup
	echo "exec startxfce4" >"/home/$username/.xinitrc"
}

finalize() {
	umount -R "$mount_point"
	unset password
	unset root_password
}


# Installs additional dependecies not provided by oficial
# Artix Linux ISO.
check_and_install_albis_dependencies() {
	pacman -Sy
	parted -h 2>&1 >/dev/null || install parted
	wget -h 2>&1 >/dev/null || install wget
	$gum -h 2>&1 >/dev/null || { 
		_binary="gum_0.8.0_linux_x86_64.tar.gz"
		wget "https://github.com/charmbracelet/gum/releases/download/v0.8.0/$_binary"
		tar -zxf "$_binary"
		gum=$PWD/gum
		unset _binary
	}
}


### Script ###

workdir="$( dirname "$0" )"

if [ -f "$workdir/options.sh" ]; then
	. "$workdir/options.sh"
else
	echo "[Error]
The 'options.sh' file is missing.
Ensure that it is in the same path as 'albis.sh'.
" >&2
	exit 1
fi

username="$2"
password="$3"
root_password="$4"

config_file="$1"
if [ -f "$config_file" ]; then
	echo "$config_file" | grep -q '^/' || config_file="$workdir/$config_file"
	. "$config_file"
fi

gum=gum
[ -z "$interactive" ] && interactive=true
[ -z "$bootstrapped" ] && bootstrapped=false
[ -z "$mount_point" ] && mount_point="/mnt"
[ -z "$config_file" ] && config_file="config.sh"
[ -z "$user_source_directory" ] && user_source_directory=".local/src"

$interactive && intro

$bootstrapped || {
	echo "Installing additional dependecies. It might take a while..."
	check_and_install_albis_dependencies
	read_config
}
$interactive && $gum confirm "Would you like to review config?" && {
	clear
	save_config | less
}

if ! $bootstrapped; then
	setup_disk
	base_install
	bootstrapped=true
	interactive=false
	{
		save_var bootstrapped 
		save_var interactive
	} >"$mount_point/root/$config_file"
	save_config >>"$mount_point/root/$config_file"
	cp "$0" "$mount_point/root/"
	cp "$workdir/options.sh" "$mount_point/root/"
	artix-chroot "$mount_point" /bin/sh -c "cd ~; sh albis.sh $config_file $username $password $root_password"
	#finalize
else
	base_config
	system_beep_off
	set_users
	include_universe_repo
	enable_arch_repos
	install $( echo "$packages" | xargs )
	#install_dotfiles
	postinstall_config
fi

exit 0
