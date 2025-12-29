#!/bin/env bash

##################################################################################
# This is the pre-flight check script for configuring the system.                #
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by Afiniel for yiimpool use...                                         #
##################################################################################

# Source functions and definitions
source /etc/functions.sh

echo -e "${YELLOW}Running pre-flight checks...${NC}\n"

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
    elif [[ "${UBUNTU_DESCRIPTION}" == "25.04" ]]; then
        DISTRO=25
    else
        echo "This script only supports Ubuntu 20.04, 23.04, and 24.04. Debian 12 is also supported."
        exit 1
    fi
else
    
    DEBIAN_DESCRIPTION=$(cat /etc/debian_version | cut -d. -f1)
    if [[ "${DEBIAN_DESCRIPTION}" == "13" ]]; then
        DISTRO=13
    elif [[ "${DEBIAN_DESCRIPTION}" == "12" ]]; then
        DISTRO=12
    elif [[ "${DEBIAN_DESCRIPTION}" == "11" ]]; then
        DISTRO=11
    else
        echo "This script only supports Ubuntu 20.04, 23.04, and 24.04. Debian 12 is also supported."
        exit 1
    fi
fi

# Set permissions
sudo chmod g-w /etc /etc/default /usr

# Check if swap is needed and allocate if necessary
SWAP_MOUNTED=$(cat /proc/swaps | tail -n+2)
SWAP_IN_FSTAB=$(grep "swap" /etc/fstab)
ROOT_IS_BTRFS=$(grep "\/ .*btrfs" /proc/mounts)
TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
AVAILABLE_DISK_SPACE=$(df / --output=avail | tail -n 1)

if [ -z "$SWAP_MOUNTED" ] && [ -z "$SWAP_IN_FSTAB" ] && [ ! -e /swapfile ] && [ -z "$ROOT_IS_BTRFS" ] && [ $TOTAL_PHYSICAL_MEM -lt 1536000 ] && [ $AVAILABLE_DISK_SPACE -gt 5242880 ]; then
    echo -e "${YELLOW}Adding a swap file to the system...${NC}"
    
    # Allocate and activate the swap file
    sudo fallocate -l 3G /swapfile
    if [ -e /swapfile ]; then
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
        echo "/swapfile  none swap sw 0  0" | sudo tee -a /etc/fstab
        echo -e "${GREEN}Swap file added and activated.${NC}\n"
    else
        echo -e "${RED}ERROR: Swap allocation failed.${NC}\n"
    fi
fi

# Check architecture
ARCHITECTURE=$(uname -m)
if [ "$ARCHITECTURE" != "x86_64" ]; then
    if [ -z "$ARM" ]; then
        echo -e "${RED}Yiimpool Installer only supports x86_64 architecture and will not work on any other architecture, like ARM or 32-bit OS.${NC}"
        echo -e "${RED}Your architecture is $ARCHITECTURE.${NC}\n"
        exit 1
    fi
fi

# Set STORAGE_USER and STORAGE_ROOT to default values if not already set
if [ -z "$STORAGE_USER" ]; then
    STORAGE_USER=${DEFAULT_STORAGE_USER:-"crypto-data"}
fi
if [ -z "$STORAGE_ROOT" ]; then
    STORAGE_ROOT=${DEFAULT_STORAGE_ROOT:-"/home/$STORAGE_USER"}
fi

echo -e "${GREEN}Pre-flight checks completed successfully.${NC}\n"