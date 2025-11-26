#!/bin/env bash

#####################################################
# Created by Afiniel for Yiimpool use
#
# This is the main Options menu for Yiimpool
#
# Author: Afiniel
# Updated: 2025-02-16
#####################################################

source /etc/yiimpooldonate.conf
source /etc/functions.sh
source /etc/yiimpoolversion.conf

show_menu() {  
    RESULT=$(dialog --stdout --title "Yiimpool Menu $VERSION" --menu "Choose an option" -1 60 8 \
        ' ' "═══════════  Options ═══════════" \
        1 "Upgrade Stratum Only" \
        2 "Add Stratum" \
        3 "Restore from Backup" \
        4 "System Health Check" \
        5 "View Update History" \
        6 "Database Tool Menu" \
        7 "Exit")
    
    case "$RESULT" in
        1)
            clear
            echo -e "${YELLOW}Starting stratum upgrade...${NC}"
            cd $HOME/Yiimpoolv1/yiimp_upgrade
            source upgrade.sh --stratum-only
            exit 0
            ;;
        2)
            clear
            echo -e "${YELLOW}Adding new stratum...${NC}"
            echo "Not completed yet, sorry."
            exit 0
            ;;
        3)
            clear
            #cd $HOME/Yiimpoolv1/yiimp_upgrade/utils
            #source restore.sh
            #show_menu
            echo "Not completed yet, sorry."
            exit 0
            ;;
        4)
            clear
            echo -e "${YELLOW}Running system health check...${NC}"
            cd $HOME/Yiimpoolv1/yiimp_upgrade
            source health_check.sh
            echo -e "${GREEN}Health check complete!${NC}"
            exit 0
            ;;
        5)
            clear
            echo -e "${YELLOW}Update History:${NC}"
            cd $HOME/Yiimpoolv1
            git log --pretty=format:"%h - %s (%cr) <%an>" --since="30 days ago"
            exit 0
            ;;
        6)
            clear
            echo -e "${GREEN}Entering Database Import menu${NC}"
            cd $HOME/Yiimpoolv1/yiimp_upgrade
            source dbtoolmenu.sh
            ;;
        7)
            clear
            motd
            echo -e "${GREEN}Exiting Yiimpool Menu${NC}"
            echo -e "${YELLOW}Type 'yiimpool' anytime to return to the menu${NC}"
            exit 0
            ;;
        *)
            show_menu
            ;;
    esac
}

# Start the menu
clear
show_menu
