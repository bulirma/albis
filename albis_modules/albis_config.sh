#!/bin/sh

# external vars:
# 	$boot
# 	$gum
# 	$target_device
# 	$init_system
# 	$mount_point
# 	$username
# 	$password
# 	$root_password
# 	$dotfiles_repository

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
		echo "Dofiles repository URL:"
		#dotfiles_repository="$( read_matching "https?:\/\/[a-z0-9-_.]\+\.[a-z]+(\/[A-Za-z0-9-_\/]\+(\.git)\?)\?")"
		dotfiles_repository="$( $gum input )"
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
