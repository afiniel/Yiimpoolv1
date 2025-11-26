#!/bin/env bash

##################################################################################
# This is the entry point for configuring the system.                            #
# Source: https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox   #
# Updated by: Afiniel for Yiimpool use...                                         #
##################################################################################

# Load required functions and configurations
set +e
source /etc/functions.sh
source /etc/yiimpool.conf 2>/dev/null || true
source "$HOME/Yiimpoolv1/yiimp_single/.wireguard.install.cnf" 2>/dev/null || true
set -e

# Ensure TERM is set for dialog commands
export TERM=${TERM:-xterm}

# Source wireguard configuration if enabled
if [[ ("$wireguard" == "true") ]]; then
    source "$STORAGE_ROOT/yiimp/.wireguard.conf"
fi

# Display installation type based on wireguard setting
if [[ ("$wireguard" == "true") ]]; then
    message_box "Yiimpool Yiimp installer" \
    "You have chosen to install Yiimp with WireGuard!
    
    This option will install all components of YiiMP on a single server along with WireGuard so you can easily add additional servers in the future.
    
    Please make sure any domain name or subdomain names are pointed to this server's IP before running this installer.
    
    After answering the following questions, setup will be automated.
    
    NOTE: If installing on a system with less than 8 GB of RAM, you may experience system issues!"
else
    message_box "Yiimpool Yiimp installer" \
    "You have chosen to install Yiimp without WireGuard!
    
    This option will install all components of YiiMP on a single server.
    
    Please make sure any domain name or subdomain names are pointed to this server's IP before running this installer.
    
    After answering the following questions, setup will be automated.
    
    NOTE: If installing on a system with less than 8 GB of RAM, you may experience system issues!"
fi

# Prompt for using a domain name or IP
set +e
dialog --title "Using Domain Name" \
--yesno "Are you using a domain name? Example: example.com?\n\nMake sure the DNS is updated!" 7 60 2>/dev/null
response=$?
set -e
case $response in
   0) UsingDomain=yes;;
   1) UsingDomain=no;;
   255) echo "[ESC] key pressed."; exit;;
esac

# If using a domain, further prompts for subdomain and domain name
if [[ "$UsingDomain" == "yes" ]]; then
    set +e
    dialog --title "Using Sub-Domain" \
    --yesno "Are you using a sub-domain for the main website domain? Example: pool.example.com?\n\nMake sure the DNS is updated!" 7 60 2>/dev/null
    response=$?
    set -e
    case $response in
       0) UsingSubDomain=yes;;
       1) UsingSubDomain=no;;
       255) echo "[ESC] key pressed."; exit;;
    esac

    # Input box for domain name
    if [ -z "${DomainName:-}" ]; then
        DEFAULT_DomainName=example.com
        input_box "Domain Name" \
        "Enter your domain name. If using a subdomain, enter the full domain as in pool.example.com.\n\nDo not add www. to the domain name.\n\nMake sure the domain is pointed to this server before continuing!\n\nDomain Name:" \
        "${DEFAULT_DomainName}" \
        DomainName

        if [ -z "${DomainName}" ]; then
            exit
        fi
    fi

    # Input box for Stratum URL
    if [ -z "${StratumURL:-}" ]; then
        DEFAULT_StratumURL=${DomainName}
        input_box "Stratum URL" \
        "Enter your stratum URL. It is recommended to use another subdomain such as stratum.${DomainName}.\n\nDo not add www. to the domain name.\n\nStratum URL:" \
        "${DEFAULT_StratumURL}" \
        StratumURL

        if [ -z "${StratumURL}" ]; then
            exit
        fi
    fi

    # Prompt for automatic SSL installation
    set +e
    dialog --title "Install SSL" \
    --yesno "Would you like the system to install SSL automatically?" 7 60 2>/dev/null
    response=$?
    set -e
    case $response in
       0) InstallSSL=yes;;
       1) InstallSSL=no;;
       255) echo "[ESC] key pressed."; exit;;
    esac
else
    # Set DomainName and StratumURL to server IP if not using a domain
    # Use error handling to prevent script failure if IP detection fails
    set +e
    DomainName=$(get_publicip_from_web_service 4 2>/dev/null || get_default_privateip 4 2>/dev/null)
    set -e
    
    # If IP detection failed or returned empty, prompt user for IP address
    if [ -z "${DomainName:-}" ]; then
        DEFAULT_DomainName=$(get_default_privateip 4 2>/dev/null || echo "127.0.0.1")
        input_box "Server IP Address" \
        "Unable to automatically detect your server's IP address.\n\nPlease enter your server's public IP address:\n\nServer IP Address:" \
        "${DEFAULT_DomainName}" \
        DomainName
        
        if [ -z "${DomainName}" ]; then
            # If user didn't provide IP, use the default
            DomainName="${DEFAULT_DomainName}"
        fi
    fi
    StratumURL=${DomainName}
    UsingSubDomain=no
    
    # Add SSL prompt even when using IP
    set +e
    dialog --title "Install SSL" \
    --yesno "Would you like the system to install SSL automatically?\n\nNote: Self-signed SSL will be used when installing with IP address." 8 60 2>/dev/null
    response=$?
    set -e
    case $response in
       0) InstallSSL=yes;;
       1) InstallSSL=no;;
       255) echo "[ESC] key pressed."; exit;;
    esac
fi

# Further prompts for support email, admin panel location, auto-exchange, dedicated coin ports, and public IP
if [ -z "${SupportEmail:-}" ]; then
    DEFAULT_SupportEmail=root@localhost
    input_box "System Email" \
    "Enter an email address for the system to send alerts and other important messages.\n\nSystem Email:" \
    "${DEFAULT_SupportEmail}" \
    SupportEmail

    if [ -z "${SupportEmail}" ]; then
        exit
    fi
fi

# Automatically set PublicIP based on SSH client IP or default private IP
if [ -z "${PublicIP:-}" ]; then
    if pstree -p | egrep --quiet --extended-regexp ".*sshd.*\($$\)"; then
        DEFAULT_PublicIP=$(echo "$SSH_CLIENT" | awk '{ print $1}')
    else
        DEFAULT_PublicIP=192.168.0.1
    fi

    input_box "Your Public IP" \
    "Enter your public IP from the remote system you will access your admin panel from.\n\nWe have guessed your public IP from the IP used to access this system.\n\nGo to whatsmyip.org if you are unsure if this is your public IP.\n\nYour Public IP:" \
    "${DEFAULT_PublicIP}" \
    PublicIP

    if [ -z "${PublicIP}" ]; then
        exit
    fi
fi

# Function for secure password handling for database
generate_random_password_database() {
    local default_value=$1
    local variable_name=$2
    if [ -z "${!variable_name:-}" ]; then
        local default_password=$(openssl rand -base64 29 | tr -d "=+/")
        input_box "Database Password" \
        "Enter your desired database password.\n\nYou may use the system generated password shown.\n\nDesired Database Password:" \
        "${default_password}" \
        "${variable_name}"

        if [ -z "${!variable_name}" ]; then
            exit
        fi
    fi
}

# Function for secure password handling for YiiMP admin panel
generate_random_password_yiimp_admin() {
    local default_value=$1
    local variable_name=$2
    if [ -z "${!variable_name:-}" ]; then
        local default_password=$(openssl rand -base64 29 | tr -d "=+/")
        input_box "Admin Password" \
        "Enter your desired admin password for YiiMP panel.\n\nYou may use the system generated password shown.\n\nThis will be used to login to your admin panel.\n\nDesired Admin Password:" \
        "${default_password}" \
        "${variable_name}"

        if [ -z "${!variable_name}" ]; then
            exit
        fi
    fi
}

# Function for secure password handling for blocknotify
generate_random_password_blocknotify() {
    local default_value=$1
    local variable_name=$2
    if [ -z "${!variable_name:-}" ]; then
        local default_password=$(openssl rand -base64 29 | tr -d "=+/")
        input_box "Blocknotify Password" \
        "Enter your desired blocknotify password.\n\nYou may use the system generated password shown.\n\nThis will be used for coin blocknotify.\n\nDesired Blocknotify Password:" \
        "${default_password}" \
        "${variable_name}"

        if [ -z "${!variable_name}" ]; then
            exit
        fi
    fi
}

# Function for YiiMP admin username
generate_yiimp_admin_user() {
    local default_value=$1
    local variable_name=$2
    if [ -z "${!variable_name:-}" ]; then
        local default_username="admin"
        input_box "Admin Username" \
        "Enter your desired admin username for YiiMP panel.\n\nThis will be used to login to your admin panel.\n\nDefault username is 'admin'.\n\nDesired Admin Username:" \
        "${default_username}" \
        "${variable_name}"

        if [ -z "${!variable_name}" ]; then
            exit
        fi
    fi
}

# Function for phpMyAdmin username
generate_phpmyadmin_user() {
    local default_value=$1
    local variable_name=$2
    if [ -z "${!variable_name:-}" ]; then
        local default_username="phpmyadmin"
        input_box "phpMyAdmin Username" \
        "Enter your desired username for phpMyAdmin.\n\nThis will be used to login to phpMyAdmin.\n\nDefault username is 'phpmyadmin'.\n\nDesired phpMyAdmin Username:" \
        "${default_username}" \
        "${variable_name}"

        if [ -z "${!variable_name}" ]; then
            exit
        fi
    fi
}

# Function for phpMyAdmin password
generate_random_password_phpmyadmin() {
    local default_value=$1
    local variable_name=$2
    if [ -z "${!variable_name:-}" ]; then
        local default_password=$(openssl rand -base64 29 | tr -d "=+/")
        input_box "phpMyAdmin Password" \
        "Enter your desired password for phpMyAdmin.\n\nYou may use the system generated password shown.\n\nThis will be used to login to phpMyAdmin.\n\nDesired phpMyAdmin Password:" \
        "${default_password}" \
        "${variable_name}"

        if [ -z "${!variable_name}" ]; then
            exit
        fi
    fi
}

# Generate database passwords
generate_random_password_database "${DEFAULT_DBRootPassword}" "DBRootPassword"
generate_random_password_database "${DEFAULT_PanelUserDBPassword}" "PanelUserDBPassword"
generate_random_password_database "${DEFAULT_StratumUserDBPassword}" "StratumUserDBPassword"

# Generate YiiMP admin credentials
generate_yiimp_admin_user "${DEFAULT_AdminUser}" "AdminUser"
generate_random_password_yiimp_admin "${DEFAULT_AdminPassword}" "AdminPassword"

# Generate phpMyAdmin credentials
generate_phpmyadmin_user "${DEFAULT_PHPMyAdminUser}" "PHPMyAdminUser"
generate_random_password_phpmyadmin "${DEFAULT_PHPMyAdminPassword}" "PHPMyAdminPassword"

# Generate blocknotify password
generate_random_password_blocknotify "${DEFAULT_BlocknotifyPassword}" "BlocknotifyPassword"

# Generate unique names for YiiMP DB and users for increased security
YiiMPDBName=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)
YiiMPPanelName=Panel$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)
StratumDBUser=Stratum$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)

clear

# Display confirmation dialog for user to verify inputs
set +e
dialog --title "Verify Your Responses" \
--yesno "Please verify your input before continuing:
Using Domain          : ${UsingDomain}
Using Sub-Domain      : ${UsingSubDomain}
Domain Name           : ${DomainName}
Stratum URL          : ${StratumURL}
Install SSL           : ${InstallSSL}
System Email          : ${SupportEmail}
Your Public IP        : ${PublicIP}
phpMyAdmin Username   : ${PHPMyAdminUser}" 17 60 2>/dev/null

# Get exit status of confirmation dialog
# 0 means user confirmed, 1 means user canceled
response=$?
set -e
case $response in
    0)
        # Save configuration to .yiimp.conf
        if [[ ("$wireguard" == "true") ]]; then
            echo "STORAGE_USER=${STORAGE_USER}
                  STORAGE_ROOT=${STORAGE_ROOT}
                  PRIMARY_HOSTNAME=${DomainName}
                  UsingDomain=${UsingDomain}
                  UsingSubDomain=${UsingSubDomain}
                  DomainName=${DomainName}
                  StratumURL=${StratumURL}
                  InstallSSL=${InstallSSL}
                  SupportEmail=${SupportEmail}
                  PublicIP=${PublicIP}
                  AutoExchange=${AutoExchange}
                  DBInternalIP=${DBInternalIP}
                  YiiMPDBName=${YiiMPDBName}
                  DBRootPassword='${DBRootPassword}'
                  YiiMPPanelName=${YiiMPPanelName}
                  PanelUserDBPassword='${PanelUserDBPassword}'
                  StratumDBUser=${StratumDBUser}
                  StratumUserDBPassword='${StratumUserDBPassword}'
                  AdminPassword='${AdminPassword}'
                  AdminUser='${AdminUser}'
                  PHPMyAdminUser='${PHPMyAdminUser}'
                  PHPMyAdminPassword='${PHPMyAdminPassword}'
                  BlocknotifyPassword='${BlocknotifyPassword}'
                  YiiMPRepo='https://github.com/Kudaraidee/yiimp.git'" | sudo -E tee "$STORAGE_ROOT/yiimp/.yiimp.conf" >/dev/null 2>&1
        else
            echo "STORAGE_USER=${STORAGE_USER}
                  STORAGE_ROOT=${STORAGE_ROOT}
                  PRIMARY_HOSTNAME=${DomainName}
                  UsingDomain=${UsingDomain}
                  UsingSubDomain=${UsingSubDomain}
                  DomainName=${DomainName}
                  StratumURL=${StratumURL}
                  InstallSSL=${InstallSSL}
                  SupportEmail=${SupportEmail}
                  PublicIP=${PublicIP}
                  AutoExchange=${AutoExchange}
                  YiiMPDBName=${YiiMPDBName}
                  DBRootPassword='${DBRootPassword}'
                  YiiMPPanelName=${YiiMPPanelName}
                  PanelUserDBPassword='${PanelUserDBPassword}'
                  StratumDBUser=${StratumDBUser}
                  StratumUserDBPassword='${StratumUserDBPassword}'
                  AdminPassword='${AdminPassword}'
                  AdminUser='${AdminUser}'
                  PHPMyAdminUser='${PHPMyAdminUser}'
                  PHPMyAdminPassword='${PHPMyAdminPassword}'
                  BlocknotifyPassword='${BlocknotifyPassword}'
                  YiiMPRepo='https://github.com/Kudaraidee/yiimp.git'" | sudo -E tee "$STORAGE_ROOT/yiimp/.yiimp.conf" >/dev/null 2>&1
        fi
        ;;
    1)
        # Restart script if user cancels
        clear
        bash "$(basename "$0")" && exit
        ;;
    255)
        clear
        echo "User canceled installation"
        exit 0
        ;;
esac

cd $HOME/Yiimpoolv1/yiimp_single