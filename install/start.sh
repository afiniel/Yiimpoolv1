#!/usr/bin/env bash

##################################################################################
# This is the entry point for configuring the system.                            #
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by Afiniel for yiimpool use...                                         #
##################################################################################

# Include functions for color output and other utilities
source /etc/functions.sh

# Define colors if not defined in functions.sh
YELLOW=${YELLOW:-"\033[1;33m"}
GREEN=${GREEN:-"\033[0;32m"}
RED=${RED:-"\033[0;31m"}
NC=${NC:-"\033[0m"} # No Color

# Recall the last settings used if we're running this a second time.
if [ -f /etc/yiimpool.conf ]; then
    echo -e "${YELLOW}Loading previous configuration settings...${NC}\n"
    # Load the old .conf file to get existing configuration options loaded
    # into variables with a DEFAULT_ prefix.
    cat /etc/yiimpool.conf | sed s/^/DEFAULT_/ >/tmp/yiimpool.prev.conf
    source /tmp/yiimpool.prev.conf
    echo -e "${GREEN}Loaded previous configuration settings.${NC}\n"
    echo -e "${YELLOW}Loading donation settings and version information...${NC}\n"
    source /etc/yiimpooldonate.conf
    source /etc/yiimpoolversion.conf
    echo -e "${GREEN}Loaded donation settings and version information.${NC}\n"
    rm -f /tmp/yiimpool.prev.conf
    echo -e "${GREEN}Removed temporary previous configuration file.${NC}\n"
else
    FIRST_TIME_SETUP=1
    echo -e "${YELLOW}First-time setup detected.${NC}\n"
fi

if [[ "$FIRST_TIME_SETUP" == "1" ]]; then
    clear
    cd "$HOME/Yiimpoolv1/install"

    echo -e "${YELLOW}Performing first-time setup...${NC}\n"
    # Copy functions to /etc
    source functions.sh
    sudo cp -r functions.sh /etc/
    sudo cp -r editconf.py /usr/bin
    sudo chmod +x /usr/bin/editconf.py
    echo -e "${GREEN}Copied functions and editconf.py to system directories.${NC}\n"

    # Check system setup: Are we running as root on Ubuntu 16.04/18.04/20.04 on a
    # machine with enough memory?
    # If not, this shows an error and exits.
    echo -e "${YELLOW}Running preflight system checks...${NC}\n"
    source preflight.sh

    # Ensure Python reads/writes files in UTF-8.
    if ! locale -a | grep en_US.utf8 >/dev/null; then
        echo -e "${YELLOW}Generating en_US.UTF-8 locale...${NC}\n"
        hide_output locale-gen en_US.UTF-8
    fi

    export LANGUAGE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_TYPE=en_US.UTF-8
    echo -e "${GREEN}Set system locale to en_US.UTF-8.${NC}\n"

    # Fix so line drawing characters are shown correctly in Putty on Windows. See #744.
    export NCURSES_NO_UTF8_ACS=1
    echo -e "${GREEN}Configured NCURSES for correct line drawing characters.${NC}\n"

    # Check for user
    echo -e "${YELLOW}Installing necessary packages for setup to continue...${NC}\n"
    hide_output sudo apt-get -q -q update
    hide_output sudo apt-get install -y figlet
    hide_output sudo apt-get install -y lolcat
    apt_get_quiet install dialog python3 python3-pip acl nano git apt-transport-https || exit 1
    echo -e "${GREEN}Installed necessary packages.${NC}\n"

    # Are we running as root?
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Running as a non-root user. Displaying welcome message...${NC}\n"
        # Welcome
        message_box "Yiimpool Installer $VERSION" \
        "${YELLOW}Hello and thanks for using the Yiimpool Installer!${NC}
        \n\n${GREEN}Installation for the most part is fully automated. In most cases any user responses that are needed are asked prior to the installation.${NC}
        \n\n${RED}NOTE: You should only install this on a brand new Ubuntu 20.04, Ubuntu 18.04, or Ubuntu 16.04 installation.${NC}"
        source existing_user.sh
        exit
    else
        echo -e "${YELLOW}Running as root. Proceeding to create user...${NC}\n"
        source create_user.sh
        exit
    fi
    cd ~

else
    clear
    echo -e "${YELLOW}Loading configuration for subsequent runs...${NC}\n"

    # Ensure Python reads/writes files in UTF-8.
    if ! locale -a | grep en_US.utf8 >/dev/null; then
        echo -e "${YELLOW}Generating en_US.UTF-8 locale...${NC}\n"
        hide_output locale-gen en_US.UTF-8
    fi

    export LANGUAGE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_TYPE=en_US.UTF-8
    echo -e "${GREEN}Set system locale to en_US.UTF-8.${NC}\n"

    export NCURSES_NO_UTF8_ACS=1
    echo -e "${GREEN}Configured NCURSES for correct line drawing characters.${NC}\n"

    echo -e "${YELLOW}Loading system functions and configuration...${NC}\n"
    source /etc/functions.sh
    source /etc/yiimpool.conf
    echo -e "${GREEN}Loaded system functions and configuration.${NC}\n"

    # Start yiimpool
    echo -e "${YELLOW}Starting Yiimpool installation...${NC}\n"
    cd "$HOME/Yiimpoolv1/install"
    source menu.sh
    cd ~
fi