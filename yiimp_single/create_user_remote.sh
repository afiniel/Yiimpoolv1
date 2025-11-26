#!/bin/env bash

##################################################################################
# This is the entry point for configuring the system.                            #
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by Afiniel for yiimpool use...                                         #
##################################################################################

export TERM=xterm

if [ -z "${TAG}" ]; then
TAG=v2.5.1
fi
echo 'VERSION='"${TAG}"'' | sudo -E tee /etc/yiimpoolversion.conf >/dev/null 2>&1

if [ -f /etc/functions.sh ]; then
  source /etc/functions.sh
else
  sudo cp -r /tmp/functions.sh /etc/
  source /etc/functions.sh
fi

ESC_SEQ="\x1b["
NC=${NC:-"\033[0m"} # No Color
RED=$ESC_SEQ"31;01m"
GREEN=$ESC_SEQ"32;01m"
YELLOW=$ESC_SEQ"33;01m"
BLUE=$ESC_SEQ"34;01m"
MAGENTA=$ESC_SEQ"35;01m"
CYAN=$ESC_SEQ"36;01m"

 # Check for user
echo -e "${YELLOW}Installing necessary packages for setup to continue...${NC}\n"
sudo apt-get update
sudo apt-get install -y figlet
sudo apt-get install -y lolcat
sudo apt-get install -y dialog python3 python3-pip acl nano git apt-transport-https
echo -e "${GREEN}Installed necessary packages.${NC}\n"

source /etc/yiimpoolversion.conf
source /etc/functions.sh

echo -e " Begin remote server creations, installer may look hung...$COL_RESET"

# Get logged in user name
whoami=`whoami`
echo -e " Modifying existing user $whoami for Yiimpoolv1 support."
sudo usermod -aG sudo ${whoami}

echo '# yiimp
# It needs passwordless sudo functionality.
'""''"${whoami}"''""' ALL=(ALL) NOPASSWD:ALL
' | sudo -E tee /etc/sudoers.d/${whoami} >/dev/null 2>&1

if [ ! -f /usr/bin/dialog ] || [ ! -f /usr/bin/python3 ] || [ ! -f /usr/bin/pip3 ] || [ ! -f /usr/bin/acl ] || [ ! -f /usr/bin/nano ] || [ ! -f /usr/bin/git ] ; then
sudo apt-get -q -q update
sudo apt-get install -y dialog python3 python3-pip acl nano apt-transport-https git curl
fi

# Identify OS
if [[ -f /etc/lsb-release ]]; then

    UBUNTU_DESCRIPTION=$(lsb_release -rs)
    if [[ "${UBUNTU_DESCRIPTION}" == "24.04" ]]; then
        DISTRO=24
    elif [[ "${UBUNTU_DESCRIPTION}" == "23.04" ]]; then
        DISTRO=23
    elif [[ "${UBUNTU_DESCRIPTION}" == "22.04" ]]; then
        DISTRO=22
    elif [[ "${UBUNTU_DESCRIPTION}" == "20.04" ]]; then
        DISTRO=20
    elif [[ "${UBUNTU_DESCRIPTION}" == "18.04" ]]; then
        DISTRO=18
    elif [[ "${UBUNTU_DESCRIPTION}" == "16.04" ]]; then
        DISTRO=16
    else
        echo "This script only supports Ubuntu 16.04, 18.04, 20.04, 23.04, and 24.04. Debian 12 is also supported."
        exit 1
    fi
else
    
    DEBIAN_DESCRIPTION=$(cat /etc/debian_version | cut -d. -f1)
    if [[ "${DEBIAN_DESCRIPTION}" == "12" ]]; then
        DISTRO=12
    else
        echo "This script only supports Ubuntu 16.04, 18.04, 20.04, 23.04, and 24.04. Debian 12 is also supported."
        exit 1
    fi
fi

# Set permissions
sudo chmod g-w /etc /etc/default /usr

TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
  if [ $TOTAL_PHYSICAL_MEM -lt 2000000 ]; then
    if [ ! -d /vagrant ]; then
      TOTAL_PHYSICAL_MEM=$(expr \( \( $TOTAL_PHYSICAL_MEM \* 1024 \) / 1000 \) / 1000)
      echo "Your Crypto-Pool Server needs more memory (RAM) to function properly."
      echo "Please provision a machine with at least 2 GB, 6 GB recommended."
      echo "This machine has $TOTAL_PHYSICAL_MEM MB memory."
      exit
    fi
  fi
if [ $TOTAL_PHYSICAL_MEM -lt 2000000 ]; then
  echo "WARNING: Your Crypto-Pool Server has less than 4 GB of memory."
  echo " It might run unreliably when under heavy load."
fi

# Check swap
echo -e " Checking if swap space is needed and if so creating...$COL_RESET"
  SWAP_MOUNTED=$(cat /proc/swaps | tail -n+2)
  SWAP_IN_FSTAB=$(grep "swap" /etc/fstab)
  ROOT_IS_BTRFS=$(grep "\/ .*btrfs" /proc/mounts)
  TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
  AVAILABLE_DISK_SPACE=$(df / --output=avail | tail -n 1)
if
  [ -z "$SWAP_MOUNTED" ] &&
  [ -z "$SWAP_IN_FSTAB" ] &&
  [ ! -e /swapfile ] &&
  [ -z "$ROOT_IS_BTRFS" ] &&
  [ $TOTAL_PHYSICAL_MEM -lt 19000000 ] &&
  [ $AVAILABLE_DISK_SPACE -gt 5242880 ]
then
echo "Adding a swap file to the system..."
  dd if=/dev/zero of=/swapfile bs=2048 count=$[1024*1024] status=none
    if [ -e /swapfile ]; then
      chmod 600 /swapfile
      hide_output mkswap /swapfile
      swapon /swapfile
    fi
    if swapon -s | grep -q "\/swapfile"; then
      echo "/swapfile  none swap sw 0  0" >> /etc/fstab
    else
      echo "ERROR: Swap allocation failed"
    fi
fi
echo -e "$GREEN Done...$COL_RESET"

ARCHITECTURE=$(uname -m)
  if [ "$ARCHITECTURE" != "x86_64" ] && [ "$ARCHITECTURE" != "aarch64" ]; then
    if [ -z "$ARM" ]; then
      echo "Yiimpool Setup Installer only supports x86_64 and aarch64 architectures and will not work on any other architecture, like 32 bit OS or other ARM variants."
      echo "Your architecture is $ARCHITECTURE"
      exit
    fi
fi

echo -e "$YELLOW => Setting our global variables <= ${NC}"

# If the machine is behind a NAT, inside a VM, etc., it may not know
# its IP address on the public network / the Internet. Ask the Internet
# and possibly confirm with user.
if [ -z "${PUBLIC_IP:-}" ]; then
# Ask the Internet.
GUESSED_IP=$(get_publicip_from_web_service 4 || true)

# On the first run, if we got an answer from the Internet then don't
# ask the user.
if [[ -z "${DEFAULT_PUBLIC_IP:-}" && ! -z "$GUESSED_IP" ]]; then
PUBLIC_IP=$GUESSED_IP

# On later runs, if the previous value matches the guessed value then
# don't ask the user either.
elif [ "${DEFAULT_PUBLIC_IP:-}" == "$GUESSED_IP" ]; then
PUBLIC_IP=$GUESSED_IP
fi

if [ -z "${PUBLIC_IP:-}" ]; then
input_box "Public IP Address" \
"Enter the public IP address of this machine, as given to you by your ISP.
\n\nPublic IP address:" \
"$DEFAULT_PUBLIC_IP" \
PUBLIC_IP

if [ -z "$PUBLIC_IP" ]; then
# user hit ESC/cancel
exit
fi
fi
fi

# Same for IPv6. But it's optional. Also, if it looks like the system
# doesn't have an IPv6, don't ask for one.
if [ -z "${PUBLIC_IPV6:-}" ]; then
	# Ask the Internet.
	GUESSED_IP=$(get_publicip_from_web_service 6 || true)
	MATCHED=0
	if [[ -z "${DEFAULT_PUBLIC_IPV6:-}" && ! -z "$GUESSED_IP" ]]; then
		PUBLIC_IPV6=$GUESSED_IP
	elif [[ "${DEFAULT_PUBLIC_IPV6:-}" == "$GUESSED_IP" ]]; then
		# No IPv6 entered and machine seems to have none, or what
		# the user entered matches what the Internet tells us.
		PUBLIC_IPV6=$GUESSED_IP
		MATCHED=1
	elif [[ -z "${DEFAULT_PUBLIC_IPV6:-}" ]]; then
		DEFAULT_PUBLIC_IPV6=$(get_default_privateip 6 || true)
	fi

	if [[ -z "${PUBLIC_IPV6:-}" && $MATCHED == 0 ]]; then
		input_box "IPv6 Address (Optional)" \
			"Enter the public IPv6 address of this machine, as given to you by your ISP.
			\n\nLeave blank if the machine does not have an IPv6 address.
			\n\nPublic IPv6 address:" \
			${DEFAULT_PUBLIC_IPV6:-} \
			PUBLIC_IPV6

		if [ ! $PUBLIC_IPV6_EXITCODE ]; then
			# user hit ESC/cancel
			exit
		fi
	fi
fi


if [ "$PUBLIC_IP" = "auto" ]; then
PUBLIC_IP=$(get_publicip_from_web_service 4 || get_default_privateip 4)
fi

if [ "$PUBLIC_IPV6" = "auto" ]; then
PUBLIC_IPV6=$(get_publicip_from_web_service 6 || get_default_privateip 6)
fi

# Set STORAGE_USER and STORAGE_ROOT to default values (crypto-data and /home/crypto-data), unless
# we've already got those values from a previous run.
if [ -z "$STORAGE_USER" ]; then
  STORAGE_USER=$([[ -z "$DEFAULT_STORAGE_USER" ]] && echo "crypto-data" || echo "$DEFAULT_STORAGE_USER")
fi
if [ -z "$STORAGE_ROOT" ]; then
  STORAGE_ROOT=$([[ -z "$DEFAULT_STORAGE_ROOT" ]] && echo "/home/$STORAGE_USER" || echo "$DEFAULT_STORAGE_ROOT")
fi

# Create the STORAGE_USER and STORAGE_ROOT directory if they don't already exist.
if ! id -u $STORAGE_USER >/dev/null 2>&1; then
  sudo useradd -m $STORAGE_USER
fi
if [ ! -d $STORAGE_ROOT ]; then
  sudo mkdir -p $STORAGE_ROOT
fi

# Save the global options in /etc/Yiimpoolv1.conf so that standalone
# tools know where to look for data.
echo 'STORAGE_USER='"${STORAGE_USER}"'
STORAGE_ROOT='"${STORAGE_ROOT}"'
PUBLIC_IP='"${PUBLIC_IP}"'
DISTRO='"${DISTRO}"'
PUBLIC_IPV6='"${PUBLIC_IPV6}"'' | sudo -E tee /etc/Yiimpoolv1.conf >/dev/null 2>&1
echo -e "$GREEN Done...$COL_RESET"