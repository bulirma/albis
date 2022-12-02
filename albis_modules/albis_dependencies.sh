#!/bin/sh

# external vars:
# 	$gum

# Installs additional dependecies not provided by oficial Artix Linux ISO.
check_and_install_albis_dependencies() {
	pacman -Sy
	parted -h 2>&1 >/dev/null || install parted
	wget -h 2>&1 >/dev/null || install wget
	$gum -h 2>&1 >/dev/null || { 
		_tmp_gum_dir="/tmp/albis_gum_temp_bin"
		mkdir "$_tmp_gum_dir"
		cd "$_tmp_gum_dir"
		_binary="gum_0.8.0_linux_x86_64.tar.gz"
		wget "https://github.com/charmbracelet/gum/releases/download/v0.8.0/$_binary"
		tar -zxf "$_binary"
		gum=$PWD/gum
		cd -
		unset _binary
		unset _tmp_gum_dir
	}
}
