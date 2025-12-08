#!/bin/env bash

#
# YiimPool Menu Script
#
# Author: Afiniel
# Updated: 2023-03-16
#

# Load configuration and functions
source /etc/yiimpool.conf
source /etc/yiimpoolversion.conf
source /etc/functions.sh

display_version_info

RESULT=$(dialog --stdout --nocancel --default-item 1 --title "YiimPool Menu $VERSION" --menu "Choose an option" -1 55 6 \
    ' ' "- Install Yiimp -" \
    1 "Install Yiimp Single Server" \
    2 "Options" \
    3 "Exit")

case "$RESULT" in
    1)
        clear
        echo "Preparing to install Yiimp Single Server..."
        cd $HOME/Yiimpoolv1/yiimp_single
        source start.sh
        ;;
    2)
        clear
        cd $HOME/Yiimpoolv1/install
        source options.sh
        ;;
    3)
        clear
        motd
        echo -e "${GREEN}Exiting YiimPool Menu${NC}"
        echo -e "${YELLOW}Type 'yiimpool' anytime to return to the menu${NC}"
        exit 0
        ;;
esac