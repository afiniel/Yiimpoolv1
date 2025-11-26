#!/bin/env bash

##################################################################################
# This is the pre-flight check script for configuring the system.                #
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by Afiniel for yiimpool use...                                         #
##################################################################################

# Source functions and definitions (prefer local copy to avoid stale /etc version)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set +u
if [ -f "$SCRIPT_DIR/functions.sh" ]; then
    source "$SCRIPT_DIR/functions.sh"
else
    source /etc/functions.sh
fi
set -u

# Enable strict mode and add informative ERR trap for debugging
set -euo pipefail
trap 'status=$?; cmd=$BASH_COMMAND; print_error "status=$status cmd=$cmd"' ERR

print_header "Pre-flight checks"

# Identify OS
if [[ -f /etc/rpi-issue ]]; then
    # Raspberry Pi OS detection
    RASBERRY_PI_DESCRIPTION=$(lsb_release -rs 2>/dev/null || cat /etc/debian_version | cut -d. -f1)
    if [[ "${RASBERRY_PI_DESCRIPTION}" == "13" ]] || [[ "${RASBERRY_PI_DESCRIPTION}" == "12" ]] || [[ "${RASBERRY_PI_DESCRIPTION}" == "11" ]]; then
        DISTRO=13
    else
        echo "This script only supports Raspberry Pi OS 13, 12, and 11. Ubuntu 16.04, 18.04, 20.04, 23.04, 24.04 and Debian 12 are also supported."
        exit 1
    fi
elif [[ -f /etc/lsb-release ]]; then
    # Ubuntu detection
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
        echo "This script only supports Ubuntu 16.04, 18.04, 20.04, 23.04, and 24.04. Raspberry Pi OS 13, 12, 11 and Debian 12 are also supported."
        exit 1
    fi
else
    # Debian detection
    DEBIAN_DESCRIPTION=$(cat /etc/debian_version | cut -d. -f1)
    if [[ "${DEBIAN_DESCRIPTION}" == "12" ]]; then
        DISTRO=12
    elif [[ "${DEBIAN_DESCRIPTION}" == "11" ]]; then
        DISTRO=11
    else
        echo "This script only supports Ubuntu 16.04, 18.04, 20.04, 23.04, and 24.04. Raspberry Pi OS 13, 12, 11 and Debian 12 are also supported."
        exit 1
    fi
fi


sudo chmod g-w /etc /etc/default /usr

SWAP_MOUNTED=$(cat /proc/swaps | tail -n+2)
SWAP_IN_FSTAB=""
if grep -q "swap" /etc/fstab 2>/dev/null; then
    SWAP_IN_FSTAB="yes"
fi
ROOT_IS_BTRFS=""
if grep -q "\/ .*btrfs" /proc/mounts 2>/dev/null; then
    ROOT_IS_BTRFS="yes"
fi
TOTAL_PHYSICAL_MEM=$(head -n 1 /proc/meminfo | awk '{print $2}')
AVAILABLE_DISK_SPACE=$(df / --output=avail | tail -n 1)

if [ -z "$SWAP_MOUNTED" ] && [ -z "$SWAP_IN_FSTAB" ] && [ ! -e /swapfile ] && [ -z "$ROOT_IS_BTRFS" ] && [ $TOTAL_PHYSICAL_MEM -lt 1536000 ] && [ $AVAILABLE_DISK_SPACE -gt 5242880 ]; then
    print_status "Adding a swap file to the system"
    
    # Allocate and activate the swap file
    sudo fallocate -l 3G /swapfile
    if [ -e /swapfile ]; then
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
        echo "/swapfile  none swap sw 0  0" | sudo tee -a /etc/fstab
        print_success "Swap file added and activated"
    else
        print_error "Swap allocation failed"
    fi
fi

# Check architecture
ARCHITECTURE=$(uname -m)
if [ "$ARCHITECTURE" != "x86_64" ] && [ "$ARCHITECTURE" != "aarch64" ]; then
    if [ -z "${ARM:-}" ]; then
        echo -e "${RED}Yiimpool Installer only supports x86_64 and aarch64 architectures and will not work on any other architecture, like 32-bit OS or other ARM variants.${NC}"
        echo -e "${RED}Your architecture is $ARCHITECTURE.${NC}\n"
        exit 1
    fi
fi

# Set STORAGE_USER and STORAGE_ROOT to default values if not already set
if [ -z "${STORAGE_USER:-}" ]; then
    STORAGE_USER=${DEFAULT_STORAGE_USER:-"crypto-data"}
fi
if [ -z "${STORAGE_ROOT:-}" ]; then
    STORAGE_ROOT=${DEFAULT_STORAGE_ROOT:-"/home/$STORAGE_USER"}
fi

print_success "Pre-flight checks completed"
