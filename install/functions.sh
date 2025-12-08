#!/bin/bash

##############################################
#											 #
# Current Modified by Afiniel (2022-06-06)   #
# Updated by Afiniel (2022-08-01)			 #
# 											 #
##############################################

source /etc/yiimpoolversion.conf

ESC_SEQ="\x1b["
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m'

function spinner {
    local pid=$!
    local delay=0.35
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# terminal art end screen.

function install_end_message() {

  clear

  # Define color codes (avoid hardcoding in the function)
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BOLD_YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  BOLD_CYAN='\033[1;36m'
  NC='\033[0m'  # Reset color

  echo "Yiimp Installation Complete!"
  echo

  figlet -f slant -w 100 "Success"

  echo -e "${BOLD_GREEN}**Yiimp Version:**${NC} $VERSION"
  echo

  echo -e "${BOLD_CYAN}**Database Information:**${NC}"
  echo "  - Login credentials are saved securely in ~/.my.cnf"
  echo

  echo -e "${BOLD_CYAN}**Pool and Admin Panel Access:**${NC}"
  echo "  - Pool: http://$server_name"
  echo "  - Admin Panel: http://$server_name/site/AdminPanel"
  echo "  - phpMyAdmin: http://$server_name/phpmyadmin"
  echo

  echo -e "${BOLD_CYAN}**Customization:**${NC}"
  echo "  - To modify the admin panel URL (currently set to '$admin_panel'):"
  echo "    - Edit ${BOLD_YELLOW}/var/web/yaamp/modules/site/SiteController.php${NC}"
  echo "    - Update line 11 with your desired URL"
  echo

  echo -e "${BOLD_CYAN}**Security Reminders:**${NC}"
  echo "  - Update public keys and wallet addresses in ${BOLD_YELLOW}/var/web/serverconfig.php${NC}"
  echo "  - Replace placeholder private keys in ${BOLD_YELLOW}/etc/yiimp/keys.php${NC} with your actual keys"
  echo "    - ${RED}Never share your private keys with anyone!${NC}"
  echo

  echo -e "${BOLD_YELLOW}**Next Steps:**${NC}"
  echo "  1. Reboot your server to finalize the installation process. ( ${RED}reboot${NC} )"
  echo "  2. Secure your installation by following best practices for server security."
  echo

  echo "Thank you for using the Yiimp Installer Script Fork by Afiniel!"

}

# A function to ask if the user wants to reboot the system
function ask_reboot() {
  read -p "Do you want to reboot the system? (y/n): " reboot_choice
  if [[ "$reboot_choice" == "y" ]]; then
    sudo reboot
  fi
}

function term_art() {
  clear

  # Define color codes
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BOLD_YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  BOLD_CYAN='\033[1;36m'
  NC='\033[0m'  # No Color

  center_text() {
      local text="$1"
      local width=$(tput cols)
      local padding=$(( (width - ${#text}) / 2 ))
      printf "%${padding}s%s\n" "" "$text"
  }

  # Calculate centered text with dashes for a modern border
  num_cols=$(tput cols)
  half_cols=$((num_cols / 2))
  box_width=40
  offset=$(( (num_cols - box_width) / 2 )) 

  if [ "$offset" -lt 0 ]; then
    offset=0
  fi

  printf "%${offset}s" " "
  echo -e "${BOLD_YELLOW}╔══════════════════════════════════════════╗${NC}"
  printf "%${offset}s" " "
  echo -e "${BOLD_YELLOW}║${NC}          ${BOLD_CYAN}Yiimp Installer Script${NC}          ${BOLD_YELLOW}║${NC}"
  printf "%${offset}s" " "
  echo -e "${BOLD_YELLOW}║${NC}            ${BOLD_CYAN}Fork By Afiniel!${NC}              ${BOLD_YELLOW}║${NC}"
  printf "%${offset}s" " "
  echo -e "${BOLD_YELLOW}╚══════════════════════════════════════════╝${NC}"

  echo
  center_text "Welcome to the Yiimp Installer!"
  echo
  echo -e "${BOLD_CYAN}This script will install:${NC}"
  echo
  echo -e "  ${GREEN}•${NC} MySQL for database management"
  echo -e "  ${GREEN}•${NC} Nginx web server with PHP for Yiimp operation"
  echo -e "  ${GREEN}•${NC} MariaDB as the database backend"
  echo
  echo -e "${BOLD_CYAN}Version:${NC} ${GREEN}${VERSION:-"unknown"}${NC}"
  echo
}

function term_yiimpool {
  clear

  # Consistent color definitions (assuming you use the same ones from the main script)
  YIIMP_CYAN="\e[36m"
  YIIMP_YELLOW="\e[33m"
  YIIMP_GREEN="\e[32m"
  YIIMP_RESET="\e[0m"

  # Center-aligned title with a cool ASCII font
  figlet -f slant -w 100 "YiimpooL" | lolcat -p 0.12 -s 50  # Adjust centering and speed as desired

  echo -e "${YIIMP_CYAN}  ----------------|---------------------  "
  echo -e "${YIIMP_YELLOW}  Yiimp Installer Script Fork By Afiniel!  "
  echo -e "${YIIMP_YELLOW}  Version: ${YIIMP_GREEN}$VERSION                   "
  echo -e "${YIIMP_CYAN}  ----------------|---------------------  "
  echo
}


function daemonbuiler_files {
	echo -e "$YELLOW Copy => Copy Daemonbuilder files.  <= ${NC}"
	cd $HOME/Yiimpoolv1
	sudo mkdir -p /etc/utils/daemon_builder
	sudo cp -r utils/start.sh $HOME/utils/daemon_builder
	sudo cp -r utils/menu.sh $HOME/utils/daemon_builder
	sudo cp -r utils/menu2.sh $HOME/utils/daemon_builder
	sudo cp -r utils/menu3.sh $HOME/utils/daemon_builder
	# sudo cp -r utils/errors.sh $HOME/utils/daemon_builder
	sudo cp -r utils/source.sh $HOME/utils/daemon_builder
	sudo cp -r utils/upgrade.sh $HOME/utils/daemon_builder
	# sudo cp -r utils/stratum.sh $HOME/utils
	sleep 0.5
	echo '
	#!/usr/bin/env bash
	source /etc/functions.sh # load our functions
	cd $STORAGE_ROOT/daemon_builder
	bash start.sh
	cd ~
	' | sudo -E tee /usr/bin/daemonbuilder >/dev/null 2>&1
	sudo chmod +x /usr/bin/daemonbuilder
	echo
	echo -e "$GREEN => Complete${NC}"
	sleep 2
}

function hide_output {
	OUTPUT=$(mktemp)
	$@ &>$OUTPUT &
	spinner
	E=$?
	if [ $E != 0 ]; then
		echo
		echo FAILED: $@
		echo -----------------------------------------
		cat $OUTPUT
		echo -----------------------------------------
		exit $E
	fi

	rm -f $OUTPUT
}

# function hide_output {
	# OUTPUT=$(tempfile)
	# $@ &>$OUTPUT &
	# spinner
	# E=$?
	# if [ $E != 0 ]; then
		# echo
		# echo FAILED: $@
		# echo -----------------------------------------
		# cat $OUTPUT
		# echo -----------------------------------------
		# exit $E
	# fi
# 
	# rm -f $OUTPUT
# }


function last_words {
	echo "<-------------------------------------|---------------------------------------->"
	echo
	echo -e "$YELLOW Thank you for using the Yiimpool Installer $GREEN $VERSION             ${NC}"
	echo
	echo -e "$YELLOW To run this installer anytime simply type: $GREEN yiimpool            ${NC}"
	echo -e "$YELLOW Donations for continued support of this script are welcomed at:       ${NC}"
	echo "<-------------------------------------|--------------------------------------->"
	echo -e "$YELLOW                     Donate Wallets:                                   ${NC}"
	echo "<-------------------------------------|--------------------------------------->"
	echo -e "$YELLOW Thank you for using Yiimpool Installer $VERSION fork by Afiniel!      ${NC}"
	echo
	echo -e "$YELLOW =>  To run this installer anytime simply type:$GREEN yiimpool         ${NC}"
	echo -e "$YELLOW =>  Do you want to support me? Feel free to use wallets below:        ${NC}"
	echo "<-------------------------------------|--------------------------------------->"
	echo -e "$YELLOW =>  BTC:$GREEN $BTCDON                                   		 ${NC}"
	echo -e "$YELLOW =>  BCH:$GREEN $BCHDON                                   		 ${NC}"
	echo -e "$YELLOW =>  ETH:$GREEN $ETHDON                                   		 ${NC}"
	echo -e "$YELLOW =>  DOGE:$GREEN $DOGEDON                                 		 ${NC}"
	echo -e "$YELLOW =>  LTC:$GREEN $LTCDON                                   		 ${NC}"
	echo "<-------------------------------------|-------------------------------------->"
	exit 0
}

function package_compile_crypto {

	# Installing Package to compile crypto currency
	echo -e "$MAGENTA => Installing needed Package to compile crypto currency <= ${NC}"

	hide_output sudo apt -y install software-properties-common build-essential
	hide_output sudo apt -y install libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils git cmake libboost-all-dev zlib1g-dev libz-dev libseccomp-dev libcap-dev libminiupnpc-dev gettext
	hide_output sudo apt -y install libminiupnpc10 libzmq5
	hide_output sudo apt -y install libcanberra-gtk-module libqrencode-dev libzmq3-dev
	hide_output sudo apt -y install libqt5gui5 libqt5core5a libqt5webkit5-dev libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
	hide_output sudo add-apt-repository -y ppa:bitcoin/bitcoin
	hide_output sudo apt update
	hide_output sudo apt -y install libdb4.8-dev libdb4.8++-dev libdb5.3 libdb5.3++
	hide_output sudo apt -y install bison libbison-dev
	hide_output sudo apt -y install libnatpmp-dev libnatpmp1 libqt5waylandclient5 libqt5waylandcompositor5 qtwayland5 systemtap-sdt-dev
	
	hide_output sudo apt-get -y install build-essential libzmq5 \
	libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils git cmake libboost-all-dev zlib1g-dev libz-dev \
	libseccomp-dev libcap-dev libminiupnpc-dev gettext libminiupnpc10 libcanberra-gtk-module libqrencode-dev libzmq3-dev \
	libqt5gui5 libqt5core5a libqt5webkit5-dev libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler
	hide_output sudo apt update
	hide_output sudo apt -y upgrade

	hide_output sudo apt -y install libgmp-dev libunbound-dev libsodium-dev libunwind8-dev liblzma-dev libreadline6-dev libldns-dev libexpat1-dev \
	libpgm-dev libhidapi-dev libusb-1.0-0-dev libudev-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev \
	libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev libboost-system-dev libboost-thread-dev \
	python3 ccache doxygen graphviz default-libmysqlclient-dev libnghttp2-dev librtmp-dev libssh2-1 libssh2-1-dev libldap2-dev libidn11-dev libpsl-dev
}

# Function to check if a package is installed and install it if not
install_if_not_installed() {
  local package="$1"
  if ! command -v "$package" &>/dev/null; then
    echo "Installing $package..."
    apt_install "$package"
  else
    echo "$package is already installed."
  fi
}

# Function to check package installation status
function check_package_installed() {
    if ! dpkg -l | grep -q "^ii  $1"; then
        echo "Failed to install package: $1"
        return 1
    fi
}

function apt_get_quiet {
	DEBIAN_FRONTEND=noninteractive hide_output sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" "$@"
}

function apt_install {
	PACKAGES=$@
	apt_get_quiet install $PACKAGES
}

function apt_update {
	sudo apt-get update
}

function apt_upgrade {
	hide_output sudo apt-get upgrade -y
}

function apt_dist_upgrade {
	hide_output sudo apt-get dist-upgrade -y
}

function apt_autoremove {
	hide_output sudo apt-get autoremove -y
}

function ufw_allow {
	if [ -z "$DISABLE_FIREWALL" ]; then
		sudo ufw allow $1 >/dev/null
	fi
}

function restart_service {
	hide_output sudo service $1 restart
}

## Dialog Functions ##
function message_box {
	dialog --title "$1" --msgbox "$2" 0 0
}

function input_box {
	# input_box "title" "prompt" "defaultvalue" VARIABLE
	# The user's input will be stored in the variable VARIABLE.
	# The exit code from dialog will be stored in VARIABLE_EXITCODE.
	declare -n result=$4
	declare -n result_code=$4_EXITCODE
	result=$(dialog --stdout --title "$1" --inputbox "$2" 0 0 "$3")
	result_code=$?
}

function input_menu {
	# input_menu "title" "prompt" "tag item tag item" VARIABLE
	# The user's input will be stored in the variable VARIABLE.
	# The exit code from dialog will be stored in VARIABLE_EXITCODE.
	declare -n result=$4
	declare -n result_code=$4_EXITCODE
	local IFS=^$'\n'
	result=$(dialog --stdout --title "$1" --menu "$2" 0 0 0 $3)
	result_code=$?
}

function get_publicip_from_web_service {
	# This seems to be the most reliable way to determine the
	# machine's public IP address: asking a very nice web API
	# for how they see us. Thanks go out to icanhazip.com.
	# See: https://major.io/icanhazip-com-faq/
	#
	# Pass '4' or '6' as an argument to this function to specify
	# what type of address to get (IPv4, IPv6).
	curl -$1 --fail --silent --max-time 15 icanhazip.com 2>/dev/null
}

function get_default_privateip {
	# Return the IP address of the network interface connected
	# to the Internet.
	#
	# Pass '4' or '6' as an argument to this function to specify
	# what type of address to get (IPv4, IPv6).
	#
	# We used to use `hostname -I` and then filter for either
	# IPv4 or IPv6 addresses. However if there are multiple
	# network interfaces on the machine, not all may be for
	# reaching the Internet.
	#
	# Instead use `ip route get` which asks the kernel to use
	# the system's routes to select which interface would be
	# used to reach a public address. We'll use 8.8.8.8 as
	# the destination. It happens to be Google Public DNS, but
	# no connection is made. We're just seeing how the box
	# would connect to it. There many be multiple IP addresses
	# assigned to an interface. `ip route get` reports the
	# preferred. That's good enough for us. See issue #121.
	#
	# With IPv6, the best route may be via an interface that
	# only has a link-local address (fe80::*). These addresses
	# are only unique to an interface and so need an explicit
	# interface specification in order to use them with bind().
	# In these cases, we append "%interface" to the address.
	# See the Notes section in the man page for getaddrinfo and
	# https://discourse.mailinabox.email/t/update-broke-mailinabox/34/9.
	#
	# Also see ae67409603c49b7fa73c227449264ddd10aae6a9 and
	# issue #3 for why/how we originally added IPv6.

	target=8.8.8.8

	# For the IPv6 route, use the corresponding IPv6 address
	# of Google Public DNS. Again, it doesn't matter so long
	# as it's an address on the public Internet.
	if [ "$1" == "6" ]; then target=2001:4860:4860::8888; fi

	# Get the route information.
	route=$(ip -$1 -o route get $target | grep -v unreachable)

	# Parse the address out of the route information.
	address=$(echo $route | sed "s/.* src \([^ ]*\).*/\1/")

	if [[ "$1" == "6" && $address == fe80:* ]]; then
		# For IPv6 link-local addresses, parse the interface out
		# of the route information and append it with a '%'.
		interface=$(echo $route | sed "s/.* dev \([^ ]*\).*/\1/")
		address=$address%$interface
	fi

	echo $address

}


# Yiimpool functions

# Function to upgrade stratum
upgrade_stratum() {
    log_message "$YELLOW" "Upgrading stratum..."
    
    # Set up directory variables
    YIIMP_DIR="$STORAGE_ROOT/yiimp/yiimp_setup/yiimp"
    
    # Remove existing directory if it exists
    if [[ -d "$YIIMP_DIR" ]]; then
        sudo rm -rf "$YIIMP_DIR"
    fi
    
    # Clone fresh YiiMP repository
    log_message "$GREEN" "Cloning fresh YiiMP repository..."
    if ! sudo git clone "${YiiMPRepo}" "$YIIMP_DIR"; then
        log_message "$RED" "Failed to clone YiiMP repository. Exiting..."
        return 1
    fi
    
    # Set gcc version
    log_message "$GREEN" "Setting gcc to version 9..."
    hide_output sudo update-alternatives --set gcc /usr/bin/gcc-9
    
    # Build stratum
    cd $YIIMP_DIR/stratum
    sudo git submodule init
    sudo git submodule update
    
    # Build secp256k1
    cd secp256k1 
    sudo chmod +x autogen.sh
    hide_output sudo ./autogen.sh
    hide_output sudo ./configure --enable-experimental --enable-module-ecdh --with-bignum=no --enable-endomorphism
    hide_output sudo make -j$((`nproc`+1))
    
    # Return to stratum directory
    cd $YIIMP_DIR/stratum
    
    # Build components
    log_message "$GREEN" "Building stratum components..."
    
    # Build algos
    if ! sudo make -C algos -j$(($(nproc)+1)); then
        log_message "$RED" "Failed to build algos. Please check the build output above for errors."
        return 1
    fi
    log_message "$GREEN" "algos built successfully!"
    
    # Build sha3
    if ! sudo make -C sha3 -j$(($(nproc)+1)); then
        log_message "$RED" "Failed to build sha3. Please check the build output above for errors."
        return 1
    fi
    log_message "$GREEN" "sha3 built successfully!"
    
    # Build iniparser
    if ! sudo make -C iniparser -j$(($(nproc)+1)); then
        log_message "$RED" "Failed to build iniparser. Please check the build output above for errors."
        return 1
    fi
    log_message "$GREEN" "iniparser built successfully!"
    
    # Build main stratum
    if ! sudo make -j$(($(nproc)+1)); then
        log_message "$RED" "Failed to build stratum. Please check the build output above for errors."
        return 1
    fi
    log_message "$GREEN" "stratum built successfully!"
    
    # Stop stratum service before installation
    sudo systemctl stop yiimp_stratum
    
    # Backup existing stratum configuration
    if [ -d "$STRATUM_DIR" ]; then
        sudo cp -r "$STRATUM_DIR/config" "$STRATUM_DIR/config_backup"
    fi
    
    # Install stratum
    log_message "$GREEN" "Installing stratum..."
    if ! sudo mv stratum "$STORAGE_ROOT/yiimp/site/stratum"; then
        log_message "$RED" "Failed to install stratum."
        return 1
    fi
    
    # Restore configuration if backup exists
    if [ -d "$STRATUM_DIR/config_backup" ]; then
        sudo cp -r "$STRATUM_DIR/config_backup/"* "$STRATUM_DIR/config/"
        sudo rm -r "$STRATUM_DIR/config_backup"
    fi
    
    # Copy yaamp.php
    log_message "$GREEN" "Copying yaamp.php to the site directory..."
    cd $YIIMP_DIR/web/yaamp/core/functions/
    sudo cp -r yaamp.php $STORAGE_ROOT/yiimp/site/web/yaamp/core/functions
    
    # Reset gcc version
    hide_output sudo update-alternatives --set gcc /usr/bin/gcc-10
    
    # Start stratum service

    
    log_message "$GREEN" "Stratum upgrade completed successfully!"
    return 0
}


display_version_info() {
    echo -e "${YELLOW}Current Version: ${GREEN}$VERSION${NC}"
    echo -e "${YELLOW}Checking for updates...${NC}"

    cd $HOME/Yiimpoolv1
    sudo git fetch --tags
    LATEST_TAG=$(sudo git describe --tags `sudo git rev-list --tags --max-count=1`)
    
    if [ "$VERSION" != "$LATEST_TAG" ]; then
        echo -e "${GREEN}New version available: $LATEST_TAG${NC}"
        echo -e "${YELLOW}Would you like to update? (y/n)${NC}"
        read -r update_choice
        
        if [[ "$update_choice" =~ ^[Yy]$ ]]; then
            cd $HOME/Yiimpoolv1/yiimp_upgrade
            source upgrade.sh --full
        else
            echo -e "${YELLOW}Update skipped${NC}"
        fi
    else
        echo -e "${GREEN}You are running the latest version${NC}"
    fi
    echo
}

BOLD='\033[1m'
DIM='\033[2m'

print_header() {
    echo -e "\n${BLUE}${BOLD}=== $1 ===${NC}\n"
}

print_status() {
    echo -e "${DIM}[${NC}${GREEN}●${NC}${DIM}]${NC} $1"
}

print_error() {
    echo -e "${RED}${BOLD}ERROR:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}WARNING:${NC} $1"
}

print_success() {
    echo -e "${GREEN}${BOLD}SUCCESS:${NC} $1"
}

print_info() {
    echo -e "${BLUE}${BOLD}INFO:${NC} $1"
}

print_divider() {
    echo -e "\n${DIM}────────────────────────────────────────────────────────${NC}\n"
}