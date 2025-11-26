#!/bin/env bash

#
# Yiimpool Menu Script
#
# Author: Afiniel
# Updated: 2025-02-16
#

# Load configuration and functions
source /etc/yiimpool.conf
source /etc/yiimpoolversion.conf
source /etc/functions.sh

display_version_info

set +e
RESULT=$(dialog --stdout --nocancel --default-item 1 --title "Yiimpool Menu $VERSION" --menu "Choose an option" -1 55 6 \
    ' ' "- Install YiiMP -" \
    1 "Install YiiMP Single Server" \
    2 "Options" \
    3 "Exit")

set -e
case "$RESULT" in
    1)
        clear
        echo "Preparing to install YiiMP Single Server..."
        cd $HOME/Yiimpoolv1/yiimp_single
        bash start.sh
        ;;
    2)
        clear
        cd $HOME/Yiimpoolv1/install
        bash options.sh
        ;;
    3)
        clear
        motd
        echo -e "${GREEN}Exiting Yiimpool Menu${NC}"
        echo -e "${YELLOW}Type 'yiimpool' anytime to return to the menu${NC}"
        exit 0
        ;;
esac
