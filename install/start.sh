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
    print_status "Loading previous configuration from /etc/yiimpool.conf"
    # Load the old .conf file to get existing configuration options loaded
    # into variables with a DEFAULT_ prefix.
    cat /etc/yiimpool.conf | sed s/^/DEFAULT_/ >/tmp/yiimpool.prev.conf
    source /tmp/yiimpool.prev.conf
    print_success "Previous configuration loaded"
    print_status "Loading donation settings and version information"
    source /etc/yiimpooldonate.conf
    source /etc/yiimpoolversion.conf
    print_success "Donation and version information loaded"
    rm -f /tmp/yiimpool.prev.conf
    print_info "Removed temporary yiimpool.prev.conf"
else
    FIRST_TIME_SETUP=1
    print_warning "First-time setup detected (no /etc/yiimpool.conf yet)"
fi

if [[ "$FIRST_TIME_SETUP" == "1" ]]; then
    clear
    cd "$HOME/Yiimpoolv1/install"

    print_header "First-time YiimPool setup"
    print_status "Installing helper scripts to /etc and /usr/bin"
    # Copy functions to /etc
    source functions.sh
    sudo cp -r functions.sh /etc/
    sudo cp -r editconf.py /usr/bin
    sudo chmod +x /usr/bin/editconf.py
    print_success "functions.sh and editconf.py installed"

    # Check system setup: Are we running as root on Ubuntu 22.04+ on a
    # machine with enough memory?
    # If not, this shows an error and exits.
    print_header "Pre-flight system checks"
    source preflight.sh

    # Ensure Python reads/writes files in UTF-8.
    if ! locale -a | grep en_US.utf8 >/dev/null; then
        print_status "Generating en_US.UTF-8 locale"
        hide_output locale-gen en_US.UTF-8
    fi

    export LANGUAGE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_TYPE=en_US.UTF-8
    print_success "Locale set to en_US.UTF-8"

    # Fix so line drawing characters are shown correctly in Putty on Windows. See #744.
    export NCURSES_NO_UTF8_ACS=1
    print_info "NCURSES_NO_UTF8_ACS=1 (better line drawing in PuTTY)"

    print_header "Bootstrap packages"
    print_status "Installing figlet, lolcat, dialog, git, and Python tools (apt update may take a minute)"
    hide_output sudo apt-get update
    hide_output sudo apt-get install -y figlet
    hide_output sudo apt-get install -y lolcat
    hide_output sudo apt-get install -y dialog python3 python3-pip acl nano git apt-transport-https
    print_success "Bootstrap packages installed"

    # Are we running as root?
    if [[ $EUID -ne 0 ]]; then
        print_status "Non-root session: showing welcome dialog"
        # Welcome
        message_box "Yiimpool Installer $VERSION" \
        "${YELLOW}Hello and thanks for using the Yiimpool Installer!${NC}
        \n\n${GREEN}Installation for the most part is fully automated. In most cases any user responses that are needed are asked prior to the installation.${NC}
        \n\n${RED}NOTE: You should only install this on a brand new Ubuntu 22.04, 23.04, 24.04, or 25.04 installation.${NC}"
        source existing_user.sh
        exit
    else
        print_status "Running as root: creating unprivileged install user next"
        source create_user.sh
        exit
    fi
    cd ~

else
    clear
    print_header "YiimPool installer (returning session)"
    print_status "Reloading configuration from /etc/yiimpool.conf"

    # Ensure Python reads/writes files in UTF-8.
    if ! locale -a | grep en_US.utf8 >/dev/null; then
        print_status "Generating en_US.UTF-8 locale"
        hide_output locale-gen en_US.UTF-8
    fi

    export LANGUAGE=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_TYPE=en_US.UTF-8
    print_success "Locale set to en_US.UTF-8"

    export NCURSES_NO_UTF8_ACS=1
    print_info "NCURSES_NO_UTF8_ACS=1 (better line drawing in PuTTY)"

    print_status "Refreshing /etc/functions.sh from the repository copy"
    # Always refresh /etc/functions.sh so it stays in sync with the repo
    sudo cp -f "$HOME/Yiimpoolv1/install/functions.sh" /etc/functions.sh
    source /etc/functions.sh
    source /etc/yiimpool.conf
    print_success "Functions and yiimpool.conf loaded"

    print_header "Main menu"
    print_info "Choose Install or Manage & Upgrade options"
    cd "$HOME/Yiimpoolv1/install"
    source menu.sh
    cd ~
fi