#!/usr/bin/env bash

#
# WireGuard Menu
#
# Author: Afiniel
#
# Updated: 2026-03-06
#

source /etc/yiimpooldonate.conf
source /etc/functions.sh
source /etc/yiimpoolversion.conf

# Ensure TERM is set for dialog commands
export TERM=${TERM:-xterm}
export NCURSES_NO_UTF8_ACS=1

RESULT=$(dialog --stdout --default-item 1 --title "YiimPool YiiMP installer $VERSION" --menu "Choose WireGuard mode for this pool" -1 60 5 \
    ' ' "═══  Install YiiMP with WireGuard VPN?  ═══" \
    1 "Yes - Install with WireGuard (Multi-Server)" \
    2 "No  - Install without WireGuard (Single-Server)" \
    3 "Exit" 2>/dev/tty)
DIALOG_EXIT=$?

# Handle dialog exit codes
if [ $DIALOG_EXIT -ne 0 ]; then
    if [ $DIALOG_EXIT -eq 1 ]; then
        # User canceled
        clear
        exit 0
    elif [ $DIALOG_EXIT -eq 255 ]; then
        print_error "Dialog cannot access the terminal (need an interactive TTY)"
        exit 1
    else
        print_error "Dialog exited with code $DIALOG_EXIT"
        exit 1
    fi
fi

# Check if result is empty
if [ -z "$RESULT" ]; then
    clear
    exit 0
fi

case "$RESULT" in
    1)
        clear;
        echo 'wireguard=true' | sudo -E tee "$HOME"/Yiimpoolv1/yiimp_single/.wireguard.install.cnf >/dev/null 2>&1;
        echo 'DBInternalIP=10.0.0.2
              server_type=db' | sudo -E tee "$STORAGE_ROOT"/yiimp/.wireguard.conf >/dev/null 2>&1;
        ;;
    2)
        clear;
        echo 'wireguard=false' | sudo -E tee "$HOME"/Yiimpoolv1/yiimp_single/.wireguard.install.cnf >/dev/null 2>&1;
        ;;
    3)
        clear;
        exit 0;
        ;;
    *)
        clear;
        print_error "Invalid menu selection"
        exit 1;
        ;;
esac
