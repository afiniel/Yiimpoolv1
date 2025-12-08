#!/bin/env bash

##################################################################################
# This is the entry point for configuring the system.                            #
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by Afiniel for yiimpool use...                                         #
##################################################################################

source /etc/functions.sh
cd ~/Yiimpoolv1/install
clear

# Get logged in user name
whoami=`whoami`
echo -e " Modifying existing user $whoami for yiimpool support."
sudo usermod -aG sudo ${whoami}

echo '# yiimp
# It needs passwordless sudo functionality.
'""''"${whoami}"''""' ALL=(ALL) NOPASSWD:ALL
' | sudo -E tee /etc/sudoers.d/${whoami} >/dev/null 2>&1

echo '
cd ~/Yiimpoolv1/install
bash start.sh
' | sudo -E tee /usr/bin/yiimpool >/dev/null 2>&1
sudo chmod +x /usr/bin/yiimpool

# Check required files and set global variables
cd $HOME/Yiimpoolv1/install
source pre_setup.sh

# Create the STORAGE_USER and STORAGE_ROOT directory if they don't already exist.
if ! id -u $STORAGE_USER >/dev/null 2>&1; then
sudo useradd -m $STORAGE_USER
fi
if [ ! -d $STORAGE_ROOT ]; then
sudo mkdir -p $STORAGE_ROOT
fi

# Save the global options in /etc/yiimpool.conf so that standalone
# tools know where to look for data.
echo 'STORAGE_USER='"${STORAGE_USER}"'
STORAGE_ROOT='"${STORAGE_ROOT}"'
PUBLIC_IP='"${PUBLIC_IP}"'
PUBLIC_IPV6='"${PUBLIC_IPV6}"'
DISTRO='"${DISTRO}"'
FIRST_TIME_SETUP='"${FIRST_TIME_SETUP}"'
PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee /etc/yiimpool.conf >/dev/null 2>&1

# Set Donor Addresses
echo 'BTCDON="bc1qc4qqz8eu5j7u8pxfrfvv8nmcka7whhm225a3f9"
LTCDON="MC9xjhE7kmeBFMs4UmfAQyWuP99M49sCQp"
ETHDON="0xdA929d4f03e1009Fc031210DDE03bC40ea66D044"
BCHDON="qpse55j0kg0txz0zyx8nsrv3pvd039c09ypplsfn87"
DOGEDON="DHNhm8FqNAQ1VTNwmCHAp3wfQ6PcfzN1nu"' | sudo -E tee /etc/yiimpooldonate.conf >/dev/null 2>&1

cd ~
sudo setfacl -m u:${whoami}:rwx /home/${whoami}/Yiimpoolv1
clear
echo -e "$YELLOW Your User:$MAGENTA ${whoami}$YELLOW has been modified for yiimpool support. ${NC}"
echo -e "$YELLOW You must$RED reboot$YELLOW the system for the new permissions to update and type$GREEN yiimpool$YELLOW to continue setup...${NC}"
exit 0