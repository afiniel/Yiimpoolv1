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
if [[ -n "$TERMUX_VERSION" ]]; then
    # Termux Android environment
    DISTRO=termux
    echo -e "${GREEN}Termux Android environment detected (version: $TERMUX_VERSION)${NC}\n"
elif [[ -f /etc/lsb-release ]]; then

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
        echo "This script only supports Ubuntu 16.04, 18.04, 20.04, 23.04, and 24.04. Debian 12 and Termux Android are also supported."
        exit 1
    fi
else
    
    DEBIAN_DESCRIPTION=$(cat /etc/debian_version | cut -d. -f1)
    if [[ "${DEBIAN_DESCRIPTION}" == "12" ]]; then
        DISTRO=12
    elif [[ "${DEBIAN_DESCRIPTION}" == "11" ]]; then
        DISTRO=11
    else
        echo "This script only supports Ubuntu 16.04, 18.04, 20.04, 23.04, and 24.04. Debian 12 and Termux Android are also supported."
        exit 1
    fi
fi

# Set permissions (skip for Termux as it doesn't have sudo)
if [[ "$DISTRO" != "termux" ]]; then
    sudo chmod g-w /etc /etc/default /usr
fi

# Check if swap is needed and allocate if necessary (skip for Termux)
if [[ "$DISTRO" != "termux" ]]; then
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
else
    echo -e "${YELLOW}Termux environment detected - skipping swap configuration${NC}\n"
fi

# Check architecture
ARCHITECTURE=$(uname -m)
if [ "$ARCHITECTURE" != "x86_64" ]; then
    if [[ "$DISTRO" == "termux" ]]; then
        echo -e "${GREEN}Termux Android environment detected with $ARCHITECTURE architecture${NC}\n"
        # Termux supports ARM, so we allow it to continue
    elif [ -z "$ARM" ]; then
        echo -e "${RED}Yiimpool Installer only supports x86_64 architecture and will not work on any other architecture, like ARM or 32-bit OS.${NC}"
        echo -e "${RED}Your architecture is $ARCHITECTURE. For Android/Termux, ARM is supported.${NC}\n"
        exit 1
    fi
fi

# Set STORAGE_USER and STORAGE_ROOT to default values if not already set
if [ -z "$STORAGE_USER" ]; then
    if [[ "$DISTRO" == "termux" ]]; then
        STORAGE_USER=${DEFAULT_STORAGE_USER:-"crypto-data"}
    else
        STORAGE_USER=${DEFAULT_STORAGE_USER:-"crypto-data"}
    fi
fi
if [ -z "$STORAGE_ROOT" ]; then
    if [[ "$DISTRO" == "termux" ]]; then
        STORAGE_ROOT=${DEFAULT_STORAGE_ROOT:-"$HOME/crypto-data"}
    else
        STORAGE_ROOT=${DEFAULT_STORAGE_ROOT:-"/home/$STORAGE_USER"}
    fi
fi

echo -e "${GREEN}Pre-flight checks completed successfully.${NC}\n"
