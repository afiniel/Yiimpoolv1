#!/usr/bin/env bash

#
# YiimPool Menu Script
#
# Author: Afiniel
# Updated: 2026-03-06
#

# Load configuration and functions
source /etc/yiimpool.conf
source /etc/yiimpoolversion.conf
source /etc/functions.sh

display_version_info

RESULT=$(dialog --stdout --nocancel --default-item 1 --title "YiimPool menu $VERSION" --menu "Install the pool or open maintenance tools" -1 60 6 \
    ' ' "═══════════  YiimPool Installer ═══════════" \
    1 "Install YiiMP Single Server" \
    2 "Manage & Upgrade Options" \
    3 "Exit")

case "$RESULT" in
    1)
        clear
        print_header "YiiMP single-server install"
        print_status "Starting the WireGuard prompt and pool installer (this can take a long time)"
        cd $HOME/Yiimpoolv1/yiimp_single
        source start.sh
        ;;
    2)
        clear
        print_header "Manage and upgrade"
        cd $HOME/Yiimpoolv1/install
        source options.sh
        ;;
    3)
        clear
        motd
        print_success "Exited YiimPool menu"
        print_info "Run yiimpool anytime to open this menu again"
        exit 0
        ;;
esac