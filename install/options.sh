#!/usr/bin/env bash

#####################################################
# Created by Afiniel for Yiimpool use
#
# This is the main Options menu for YiimPool.
# Accessible via: yiimpool → Manage & Upgrade Options
#
# Author: Afiniel
# Updated: 2026-03-06
#####################################################

source /etc/yiimpooldonate.conf
source /etc/functions.sh
source /etc/yiimpoolversion.conf

show_menu() {
    RESULT=$(dialog --stdout --title "YiimPool options $VERSION" --menu "Upgrades and maintenance tools" -1 65 10 \
        ' ' "═══════════  Upgrade ═══════════" \
        1 "Upgrade YiimPool Installer" \
        2 "Upgrade Stratum Only" \
        ' ' "═══════════  Tools ═════════════" \
        3 "Add New Stratum Server" \
        4 "Restore from Backup" \
        5 "System Health Check" \
        6 "View Update History" \
        7 "Database Tool Menu" \
        ' ' "════════════════════════════════" \
        8 "Exit")

    case "$RESULT" in
        1)
            clear
            cd "$HOME/Yiimpoolv1/install"
            source bootstrap_upgrade.sh
            exit 0
            ;;
        2)
            clear
            print_status "Starting stratum-only upgrade"
            cd "$HOME/Yiimpoolv1/yiimp_upgrade"
            source upgrade.sh --stratum-only
            exit 0
            ;;
        3)
            clear
            print_status "Starting add-stratum-server flow"
            cd "$HOME/Yiimpoolv1/install"
            source start_add_stratum.sh
            exit 0
            ;;
        4)
            clear
            print_status "Starting restore from backup"
            cd "$HOME/Yiimpoolv1/yiimp_upgrade/utils"
            source restore.sh
            exit 0
            ;;
        5)
            clear
            print_status "Running system health check..."
            cd "$HOME/Yiimpoolv1/yiimp_upgrade"
            source health_check.sh
            exit 0
            ;;
        6)
            clear
            print_status "Git history (last 30 days)"
            echo
            cd "$HOME/Yiimpoolv1"
            git log --pretty=format:"%C(yellow)%h%Creset  %s  %C(cyan)(%cr)%Creset  <%an>" \
                --since="30 days ago" \
                || print_warning "No git history available"
            echo
            print_info "Press Enter to return to this menu"
            read -r
            show_menu
            ;;
        7)
            clear
            print_status "Opening database tool menu"
            cd "$HOME/Yiimpoolv1/yiimp_upgrade"
            source dbtoolmenu.sh
            ;;
        8)
            clear
            motd
            print_success "Exited Manage & Upgrade menu"
            print_info "Run yiimpool anytime to open the main menu again"
            exit 0
            ;;
        *)
            show_menu
            ;;
    esac
}

# Start the menu
clear
print_header "Manage and upgrade"
print_info "Upgrades, stratum servers, backups, health check, and database tools"
show_menu
