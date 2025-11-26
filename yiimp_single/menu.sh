#!/bin/env bash

#
# WireGuard Menu
#
# Author: Afiniel
#
# Updated: 2025-01-30
#

source /etc/yiimpooldonate.conf
source /etc/functions.sh

RESULT=$(dialog --stdout --default-item 1 --title "Yiimpool YiiMP Installer $VERSION" --menu "Choose an option" -1 55 7 \
    ' ' "- Do you want to install YiiMP with WireGuard? -" \
    1 "Yes" \
    2 "No" \
    3 exit)

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
        exit;
        ;;
esac
