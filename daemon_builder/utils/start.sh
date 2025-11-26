#!/usr/bin/env bash
#####################################################
# This is the entry point for configuring the system.
# Updated by Afiniel
#####################################################

source /etc/daemonbuilder.sh
source /etc/functions.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf

source /etc/yiimpool.conf
source $STORAGE_ROOT/daemon_builder/conf/info.sh

cd $STORAGE_ROOT/daemon_builder
# Ensure Python reads/writes files in UTF-8. If the machine
# triggers some other locale in Python, like ASCII encoding,
# Python may not be able to read/write files. This is also
# in the management daemon startup script and the cron script.

if ! locale -a | grep en_US.utf8 > /dev/null; then
# Generate locale if not exists
sudo locale-gen en_US.UTF-8
fi

export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

# Fix so line drawing characters are shown correctly in Putty on Windows. See #744.
export NCURSES_NO_UTF8_ACS=1

if (( $EUID == 0 )); then
	# Welcome
	message_box "DaemonBuilder" \
	"Hello and thanks for using the DaemonBuilder!
	\nYou are logged in as ROOT.
	\n\nIMPORTANT: Please run this script logged in as a regular USER. Thank you."
	cd ..
	cd ~
	clear
	exit;
else
	message_box "Daemon Installer" \
	"Warning! This script only works with servers set up with the Yiimpool installer!
	\n\nSetup for the most part is fully automated. Very little user input is required."

	# Start the installation.
	source menu.sh
fi
