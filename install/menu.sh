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

# Ensure TERM is set for dialog commands
export TERM=${TERM:-xterm}
export NCURSES_NO_UTF8_ACS=1

display_version_info

# Check if dialog is available
if ! command -v dialog >/dev/null 2>&1; then
    echo "Error: dialog command not found. Please install it with: sudo apt-get install dialog"
    exit 1
fi

# Check if TTY is available
if [ ! -t 0 ] || [ ! -t 1 ]; then
    echo "Error: This script requires an interactive terminal."
    exit 1
fi

# Ensure /dev/tty exists and is accessible
if [ ! -c /dev/tty ]; then
    echo "Error: /dev/tty device not found."
    exit 1
fi

# Run dialog and capture result
# Redirect stderr to /dev/tty so errors are visible but don't interfere with stdout capture
RESULT=$(dialog --stdout --default-item 1 --title "Yiimpool Menu $VERSION" --menu "Choose an option" -1 55 4 \
    ' ' "- Install YiiMP -" \
    1 "Install YiiMP Single Server" \
    2 "Options" \
    3 "Exit" 2>/dev/tty)
DIALOG_EXIT=$?

# Handle dialog exit codes
case $DIALOG_EXIT in
    0)
        # Dialog succeeded - check if we have a result
        if [ -z "$RESULT" ]; then
            # This shouldn't happen with exit code 0, but handle it anyway
            clear
            echo "Error: No selection was made."
            exit 1
        fi
        # RESULT is valid, continue to case statement
        ;;
    1)
        # User canceled (ESC or Cancel button)
        clear
        echo "Menu canceled."
        exit 0
        ;;
    255)
        # Dialog error - cannot access terminal
        echo "Error: Dialog cannot access the terminal."
        echo "Please ensure you are running this script in an interactive terminal."
        echo "If you're running via 'yiimpool' command, try running the script directly:"
        echo "  bash $HOME/Yiimpoolv1/install/menu.sh"
        exit 1
        ;;
    *)
        # Other error
        echo "Dialog exited with unexpected code: $DIALOG_EXIT"
        exit 1
        ;;
esac

case "$RESULT" in
    1)
        clear
        echo "Preparing to install YiiMP Single Server..."
        cd $HOME/Yiimpoolv1/yiimp_single || {
            echo "Error: Cannot change to directory $HOME/Yiimpoolv1/yiimp_single"
            exit 1
        }
        # Ensure terminal environment variables are set for start.sh
        export TERM=${TERM:-xterm}
        export NCURSES_NO_UTF8_ACS=1
        # Execute start.sh - temporarily disable ERR trap and error exit to handle dialog errors gracefully
        # The ERR trap from the parent script (install/start.sh) would otherwise catch exit code 255
        set +e
        trap '' ERR 2>/dev/null || true  # Temporarily disable ERR trap with empty handler
        bash start.sh || true  # Allow command to fail without triggering trap
        START_EXIT=$?
        trap - ERR 2>/dev/null || true  # Re-enable ERR trap by removing our empty handler
        set -e
        
        # Exit codes 1 (user cancel) and 255 (dialog terminal issue) are expected - continue normally
        # Only exit for other unexpected error codes
        if [ $START_EXIT -ne 0 ] && [ $START_EXIT -ne 1 ] && [ $START_EXIT -ne 255 ]; then
            echo "Installation script exited with unexpected code: $START_EXIT"
            exit $START_EXIT
        fi
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
