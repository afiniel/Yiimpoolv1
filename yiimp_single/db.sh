#!/usr/bin/env bash

#####################################################
# Created by Afiniel for Yiimpool use
#
# This script installs and configures MariaDB for a 
# YiiMP pool setup, including creating DB users and 
# importing default database values.
#
# Author: Afiniel
# Date: 2024-07-15
#####################################################

source /etc/functions.sh
source /etc/yiimpoolversion.conf
source /etc/yiimpool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
source $HOME/Yiimpoolv1/yiimp_single/.wireguard.install.cnf

set -eu -o pipefail

function print_error {
    read -r line file <<<$(caller)
    echo "An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" >&2
}
trap print_error ERR

term_art

print_info "Starting MariaDB setup"
print_info "Using STORAGE_ROOT='$STORAGE_ROOT'"
print_info "Using YiiMPDBName='${YiiMPDBName}'"
print_info "Using YiiMPPanelName='${YiiMPPanelName}', StratumDBUser='${StratumDBUser}'"

if [[ ("$wireguard" == "true") ]]; then
    source $STORAGE_ROOT/yiimp/.wireguard.conf
    print_info "WireGuard enabled, loaded .wireguard.conf"
fi

MARIADB_VERSION='11.8'

print_header "MariaDB Installation"
print_info "Installing MariaDB version $MARIADB_VERSION"
print_info "Pre-seeding MariaDB root password for version ${MARIADB_VERSION}"

sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password password $DBRootPassword"
sudo debconf-set-selections <<< "maria-db-$MARIADB_VERSION mysql-server/root_password_again password $DBRootPassword"

print_status "Installing MariaDB packages..."
print_info "Running apt_install mariadb-server mariadb-client"
apt_install mariadb-server mariadb-client
print_success "MariaDB installation completed"

print_header "Database Configuration"
print_status "Creating database users for YiiMP..."

if [[ "$wireguard" == "false" ]]; then
    DB_HOST="localhost"
    print_info "Using localhost for database connections"
    print_info "wireguard=false, DB_HOST set to 'localhost'"
else
    DB_HOST="$DBInternalIP"
    print_info "Using WireGuard IP ($DBInternalIP) for database connections"
    print_info "wireguard=true, DB_HOST set to '$DBInternalIP'"
fi

print_status "Setting up database and user permissions..."
Q1="CREATE DATABASE IF NOT EXISTS ${YiiMPDBName};"
Q2="GRANT ALL ON ${YiiMPDBName}.* TO '${YiiMPPanelName}'@'${DB_HOST}' IDENTIFIED BY '$PanelUserDBPassword';"
Q3="GRANT ALL ON ${YiiMPDBName}.* TO '${StratumDBUser}'@'${DB_HOST}' IDENTIFIED BY '$StratumUserDBPassword';"
Q4="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}${Q4}"

print_info "Running initial SQL against MariaDB (create DB and grant privileges)"
sudo mysql -u root -p"${DBRootPassword}" -e "$SQL"
print_success "Database users created successfully"

print_header "Database Configuration Files"
print_status "Creating my.cnf configuration..."

print_info "Writing MariaDB client configuration to '$STORAGE_ROOT/yiimp/.my.cnf'"
echo "[clienthost1]
user=${YiiMPPanelName}
password=${PanelUserDBPassword}
database=${YiiMPDBName}
host=${DB_HOST}
[clienthost2]
user=${StratumDBUser}
password=${StratumUserDBPassword}
database=${YiiMPDBName}
host=${DB_HOST}
[mysql]
user=root
password=${DBRootPassword}
" | sudo -E tee "$STORAGE_ROOT/yiimp/.my.cnf" >/dev/null 2>&1

sudo chmod 0600 "$STORAGE_ROOT/yiimp/.my.cnf"
print_info "Set permissions 0600 on '$STORAGE_ROOT/yiimp/.my.cnf'"
print_success "Database configuration file created"

print_header "Database Import"
print_status "Importing YiiMP default database values..."
cd "$STORAGE_ROOT/yiimp/yiimp_setup/yiimp/sql"

print_status "Importing main database dump..."
print_info "Importing main dump from '2024-03-06-complete_export.sql.gz' into database '${YiiMPDBName}'"
sudo zcat 2024-03-06-complete_export.sql.gz | sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}"

SQL_FILES=(
    2024-03-18-add_aurum_algo.sql
    2024-03-29-add_github_version.sql
    2024-03-31-add_payout_threshold.sql
    2024-04-01-add_auto_exchange.sql
    2024-04-01-shares_blocknumber.sql
    2024-04-05-algos_port_color.sql
    2024-04-22-add_equihash_algos.sql
    2024-04-23-add_pers_string.sql
    2024-04-29-add_sellthreshold.sql
    2024-05-04-add_neoscrypt_xaya_algo.sql
    2025-02-06-add_usemweb.sql
    2025-02-13-add_xelisv2-pepew.sql
    2025-02-23-add_algo_kawpow.sql
    2025-03-31-rename_table_exchange.sql
    2025-10-05-add_argon2d1000.sql
    2025-10-07-add_yespowerADVC.sql
    2025-10-27-add_flex.sql
    2025-10-27-add_rinhash.sql
    2025-10-28-add_algo_phihash.sql
    2025-11-19-add_algo_meowpow.sql
)

for file in "${SQL_FILES[@]}"; do
    print_status "Importing $file..."
    print_info "Processing SQL migration file '$file'"
    if [[ "$file" == *.gz ]]; then
        print_info "File '$file' detected as gzip-compressed; using zcat"
        sudo zcat "$file" | sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force --binary-mode
    else
        print_info "File '$file' detected as plain SQL; using direct mysql import"
        sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < "$file"
    fi
done

#cd $HOME/Yiimpoolv1/yiimp_single/yiimp_confs
#print_status "Enabling algorithms..."
# sudo mysql -u root -p"${DBRootPassword}" "${YiiMPDBName}" --force < "2025-01-29-enable-all-algos.sql"
print_success "Database import completed successfully"

print_header "MariaDB Optimization"
print_status "Applying performance tweaks..."

config_changes=(
    '[mysqld]'
    'max_connections=800'
    'thread_cache_size=512'
    'tmp_table_size=128M'
    'max_heap_table_size=128M'
    'wait_timeout=300'
    'max_allowed_packet=64M'
)

if [[ ("$wireguard" == "true") ]]; then
    config_changes+=("bind-address=$DBInternalIP")
    print_info "Setting bind address to $DBInternalIP for WireGuard"
    print_info "Added 'bind-address=$DBInternalIP' to MariaDB configuration changes"
fi

print_status "Updating MariaDB configuration..."
config_string=$(printf "%s\n" "${config_changes[@]}")
print_info "Appending the following to /etc/mysql/my.cnf:"
print_info "$config_string"
sudo bash -c "echo \"$config_string\" >> /etc/mysql/my.cnf"

print_status "Restarting MariaDB service..."
print_info "Restarting MariaDB (mysql service) after configuration update"
restart_service mysql
print_success "Performance optimizations applied"

print_header "phpMyAdmin Setup"
print_status "Creating phpMyAdmin user..."

print_info "Creating phpMyAdmin user '${PHPMyAdminUser}' with full privileges"
sudo mysql -u root -p"${DBRootPassword}" -e "CREATE USER '${PHPMyAdminUser}'@'%' IDENTIFIED BY '${PHPMyAdminPassword}';"
sudo mysql -u root -p"${DBRootPassword}" -e "GRANT ALL PRIVILEGES ON *.* TO '${PHPMyAdminUser}'@'%' WITH GRANT OPTION;"
sudo mysql -u root -p"${DBRootPassword}" -e "FLUSH PRIVILEGES;"

print_status "Restarting MariaDB service..."
print_info "Restarting MariaDB (mysql service) after phpMyAdmin user creation"
restart_service mysql
print_success "phpMyAdmin user created successfully"

print_divider

print_warning "Please save these credentials in a secure location:"
print_header "Database Setup Summary"
print_info "MariaDB Version: $MARIADB_VERSION"
print_info "Configuration: /etc/mysql/my.cnf"
print_info "Credentials File: $STORAGE_ROOT/yiimp/.my.cnf"
print_warning "Please save these credentials in a secure location:"

print_divider

set +eu +o pipefail
cd $HOME/Yiimpoolv1/yiimp_single
