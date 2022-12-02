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


load_modules() {
	for module in $( find "$workdir/albis_modules" -name "*.sh" | xargs ); do
		. "$module"
	done
}

workdir="$( dirname "$0" )"

load_modules

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
	tmp_dest_dir="$mount_point/root/albis"
	mkdir -p "$tmp_dest_dir"
	bootstrapped=true
	interactive=false
	{
		save_var bootstrapped 
		save_var interactive
	} >"$tmp_dest_dir/$config_file"
	save_config >>"$tmp_dest_dir/$config_file"
	cp "$0" "$tmp_dest_dir/"
	cp -r "$workdir/albis_modules" "$tmp_dest_dir/"
	artix-chroot "$mount_point" /bin/sh -c "cd /root/albis; sh albis.sh $config_file $username $password $root_password"
	rm -rf "$tmp_dest_dir"
	finalize
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
