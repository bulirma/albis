#!/bin/sh

postinstall_config() {
	# sudoers
	echo "%wheel ALL=(ALL:ALL) ALL" >/etc/sudoers.d/00-albis

	# startup
	echo "exec startxfce4" >"/home/$username/.xinitrc"
}

finalize() {
	umount -R "$mount_point"
}
