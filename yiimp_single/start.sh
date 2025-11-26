#!/bin/env bash

##################################################################################
# This is the entry point for configuring the system.                            #
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by Afiniel for yiimpool use...                                         #
##################################################################################

source /etc/yiimpooldonate.conf
source /etc/yiimpoolversion.conf
source /etc/functions.sh
source /etc/yiimpool.conf

# Ensure TERM is set for dialog commands
export TERM=${TERM:-xterm}

# Load yiimp instance config if readable; otherwise continue (questions.sh will create it)
if [ -r "$STORAGE_ROOT/yiimp/.yiimp.conf" ]; then
    source $STORAGE_ROOT/yiimp/.yiimp.conf
else
    
    if [ -f "$STORAGE_ROOT/yiimp/.yiimp.conf" ]; then
        sudo chgrp "$(id -gn)" "$STORAGE_ROOT/yiimp/.yiimp.conf" 2>/dev/null || true
        sudo chmod 640 "$STORAGE_ROOT/yiimp/.yiimp.conf" 2>/dev/null || true
        if [ -r "$STORAGE_ROOT/yiimp/.yiimp.conf" ]; then
            source $STORAGE_ROOT/yiimp/.yiimp.conf
        else
            print_warning "Unable to read $STORAGE_ROOT/yiimp/.yiimp.conf; proceeding to questions"
        fi
    else
        print_warning "Config $STORAGE_ROOT/yiimp/.yiimp.conf not found; proceeding to questions"
    fi
fi

# Ensure Python reads/writes files in UTF-8. If the machine
# triggers some other locale in Python, like ASCII encoding,
# Python may not be able to read/write files. This is also
# in the management daemon startup script and the cron script.

if ! locale -a | grep en_US.utf8 > /dev/null; then
# Generate locale if not exists
hide_output locale-gen en_US.UTF-8
fi

export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_TYPE=en_US.UTF-8

# Fix so line drawing characters are shown correctly in Putty on Windows. See #744.
export NCURSES_NO_UTF8_ACS=1

# Create the temporary installation directory if it doesn't already exist.
if [ ! -d $STORAGE_ROOT/yiimp/yiimp_setup ]; then
    sudo mkdir -p $STORAGE_ROOT/{wallets,yiimp/{yiimp_setup/log,site/{web,stratum,configuration,crons,log},starts}}
    sudo touch $STORAGE_ROOT/yiimp/yiimp_setup/log/installer.log
fi

sudo chmod 755 /home/crypto-data/

# Start the installation.
source menu.sh
source questions.sh
source $HOME/Yiimpoolv1/yiimp_single/.wireguard.install.cnf

if [[ ("$wireguard" == "true") ]]; then
  source wireguard.sh
fi

source system.sh
source self_ssl.sh
source db.sh
source nginx_upgrade.sh
source web.sh
bash stratum.sh
source compile_crypto.sh
#source daemon.sh

# TODO: Fix the wiregard.
# To let users start us yiimp on multi servers.´

# if [[ ("$UsingDomain" == "yes") ]]; then
# source send_mail.sh
# fi

source server_cleanup.sh
source motd.sh
source server_harden.sh
source $STORAGE_ROOT/yiimp/.yiimp.conf

clear


YIIMP_GREEN="\e[32m"
YIIMP_BLUE="\e[36m"
YIIMP_YELLOW="\e[33m"
YIIMP_RED="\e[31m"
YIIMP_WHITE="\e[97m"
YIIMP_PURPLE="\e[35m"
YIIMP_CYAN="\e[36m"
YIIMP_RESET="\e[0m"


YIIMP_BOLD="\e[1m"
YIIMP_DIM="\e[2m"
YIIMP_ITALIC="\e[3m"
YIIMP_UNDERLINE="\e[4m"


YIIMP_HEADER="${YIIMP_BLUE}╔══════════════════════════════════════════════════════════════════════════╗${YIIMP_RESET}"
YIIMP_FOOTER="${YIIMP_BLUE}╚══════════════════════════════════════════════════════════════════════════╝${YIIMP_RESET}"
YIIMP_DIVIDER="${YIIMP_BLUE}║──────────────────────────────────────────────────────────────────────────${YIIMP_RESET}"


center_text() {
    local text="$1"
    local width=74  # Adjusted for the new border width
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%${padding}s%s%${padding}s\n" "" "$text" ""
}


print_message() {
    clear
    echo -e "${YIIMP_HEADER}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}$(center_text "${YIIMP_GREEN}YiimPool Installer ${VERSION} by Afiniel${YIIMP_RESET}")"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}$(center_text "${YIIMP_CYAN}Thank you for using the YiimPool Installer!${YIIMP_RESET}")"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}"
    
    
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}$(center_text "${YIIMP_RED}! ACTION REQUIRED !${YIIMP_RESET}")"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}$(center_text "${YIIMP_YELLOW}System MUST be rebooted before YiiMP will function${YIIMP_RESET}")"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}"
    
    
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} ${YIIMP_CYAN}Required Steps:${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} 1. Reboot system: ${YIIMP_GREEN}sudo reboot${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} 2. After reboot, run:${YIIMP_GREEN}screen -r debug${YIIMP_WHITE} to check for any issues${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}"
    
    
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} ${YIIMP_CYAN}Tools:${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • ${YIIMP_GREEN}daemonbuilder${YIIMP_WHITE} - Build coin wallets${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • ${YIIMP_GREEN}addport${YIIMP_WHITE} - Add new stratum ports${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • ${YIIMP_GREEN}yiimpool${YIIMP_WHITE} - Access YiiMPool main menu${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}"
    
    
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} ${YIIMP_CYAN}After Reboot:${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • All services will start automatically${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • Allow up to 1 minute for all services to initialize${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • Admin panel will be available at: ${YIIMP_GREEN}http://${DomainName}/admin${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}"
    
    
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} ${YIIMP_CYAN}Important Notes:${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • All pool credentials and are stored in:${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}   ${YIIMP_GREEN}$STORAGE_ROOT/yiimp/.yiimp.conf${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • This includes: Database credentials, Stratum passwords,${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}   phpMyAdmin users, and other important settings${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • Stratum ports are blocked by default${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • Use ${YIIMP_GREEN}ufw allow PORT , or use ${YIIMP_GREEN}addport${YIIMP_WHITE} to open ports${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET}"
    
   
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} ${YIIMP_CYAN}If you want Support:${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • BTC:  ${YIIMP_GREEN}${BTCDON}${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • ETH:  ${YIIMP_GREEN}${ETHDON}${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • DOGE: ${YIIMP_GREEN}${DOGEDON}${YIIMP_RESET}"
    echo -e "${YIIMP_BLUE}║${YIIMP_RESET} • LTC:  ${YIIMP_GREEN}${LTCDON}${YIIMP_RESET}"
    echo -e "${YIIMP_FOOTER}"
    echo
    echo -e "${YIIMP_RED}IMPORTANT: System must be rebooted..!${YIIMP_RESET}"
    echo -e "${YIIMP_GREEN}Run this command to reboot: ${YIIMP_WHITE}sudo reboot${YIIMP_RESET}"
}

print_message
exit 0
ask_reboot

