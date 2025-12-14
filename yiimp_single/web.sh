#!/usr/bin/env bash

#####################################################
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by afiniel for crypto use...
#####################################################

# Load configuration files
source /etc/functions.sh
source /etc/yiimpool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
source $HOME/Yiimpoolv1/yiimp_single/.wireguard.install.cnf

set -eu -o pipefail

function print_error {
  read line file <<<$(caller)
  echo "An error occurred in line $line of file $file:" >&2
  sed "${line}q;d" "$file" >&2
}
trap print_error ERR
term_art

print_header "YiiMP Web Configuration"

# Load WireGuard configuration if enabled
if [[ ("$wireguard" == "true") ]]; then
    source $STORAGE_ROOT/yiimp/.wireguard.conf
fi

print_header "Web File Structure Setup"
print_status "Creating directory structure..."

cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
sudo cp -r $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/web $STORAGE_ROOT/yiimp/site/

print_status "Installing Yiimp web files..."
cd $STORAGE_ROOT/yiimp/yiimp_setup/
sudo cp -r $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/bin/. /bin/

print_status "Creating required directories..."
sudo mkdir -p /var/www/${DomainName}/html
sudo mkdir -p /etc/yiimp
sudo mkdir -p $STORAGE_ROOT/yiimp/site/backup/

print_status "Updating YiiMP configuration..."
sudo sed -i "s|ROOTDIR=/data/yiimp|ROOTDIR=${STORAGE_ROOT}/yiimp/site|g" /bin/yiimp

print_header "NGINX Configuration"
if [[ "${UsingSubDomain,,}" == "yes" ]]; then
    print_status "Configuring subdomain setup..."
    cd $HOME/Yiimpoolv1/yiimp_single
    source nginx_subdomain_nonssl.sh
    if [[ "${InstallSSL,,}" == "yes" ]]; then
        print_status "Configuring SSL for subdomain..."
        cd $HOME/Yiimpoolv1/yiimp_single
        source nginx_subdomain_ssl.sh
    fi
else
    print_status "Configuring main domain setup..."
    cd $HOME/Yiimpoolv1/yiimp_single
    source nginx_domain_nonssl.sh
    if [[ "${InstallSSL,,}" == "yes" ]]; then
        print_status "Configuring SSL for main domain..."
        cd $HOME/Yiimpoolv1/yiimp_single
        source nginx_domain_ssl.sh
    fi
fi

print_header "YiiMP Configuration"
print_status "Creating configuration files..."
cd $HOME/Yiimpoolv1/yiimp_single
source yiimp_confs/keys.sh
source yiimp_confs/yiimpserverconfig.sh
source yiimp_confs/main.sh
source yiimp_confs/loop2.sh
source yiimp_confs/blocks.sh

print_header "Permission Setup"
print_status "Setting folder permissions..."
whoami=$(whoami)
sudo usermod -aG www-data $whoami
sudo usermod -a -G www-data $whoami
sudo usermod -a -G crypto-data $whoami
sudo usermod -a -G crypto-data www-data

print_status "Setting directory permissions..."
sudo find $STORAGE_ROOT/yiimp/site/ -type d -exec chmod 775 {} +
sudo find $STORAGE_ROOT/yiimp/site/ -type f -exec chmod 664 {} +

sudo chgrp www-data $STORAGE_ROOT -R
sudo chmod g+w $STORAGE_ROOT -R

print_header "YiiMP Customization"
print_status "Applying YiimPool customizations..."

sudo sed -i 's/YII MINING POOLS/'${DomainName}' Mining Pool/g' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/site/index.php
sudo sed -i 's/domain/'${DomainName}'/g' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/site/index.php
sudo sed -i 's/Notes/AddNodes/g' $STORAGE_ROOT/yiimp/site/web/yaamp/models/db_coinsModel.php

print_status "Creating configuration symlinks..."
sudo ln -s ${STORAGE_ROOT}/yiimp/site/configuration/serverconfig.php /etc/yiimp/serverconfig.php

print_status "Updating configuration paths..."
sudo sed -i "s|/etc/yiimp/serverconfig.php|/etc/yiimp/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/index.php
sudo sed -i "s|/etc/yiimp/serverconfig.php|/home/crypto-data/yiimp/site/configuration/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/runconsole.php
sudo sed -i "s|/etc/yiimp/serverconfig.php|/etc/yiimp/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/run.php
sudo sed -i "s|/etc/yiimp/serverconfig.php|/etc/yiimp/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/yaamp/yiic.php
sudo sed -i "s|/etc/yiimp/serverconfig.php|/etc/yiimp/serverconfig.php|g" $STORAGE_ROOT/yiimp/site/web/yaamp/modules/thread/CronjobController.php

sudo sed -i "s|require_once('serverconfig.php')|require_once('/etc/yiimp/serverconfig.php')|g" $STORAGE_ROOT/yiimp/site/web/yaamp/yiic.php

sudo sed -i "s|/root/backup|${STORAGE_ROOT}/yiimp/site/backup|g" $STORAGE_ROOT/yiimp/site/web/yaamp/core/backend/system.php
sudo sed -i 's/service $webserver start/sudo service $webserver start/g' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/thread/CronjobController.php
sudo sed -i 's/service nginx stop/sudo service nginx stop/g' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/thread/CronjobController.php

if [[ ("$wireguard" == "true") ]]; then
    print_status "Configuring WireGuard internal network..."
    internalrpcip=$DBInternalIP
    internalrpcip="${DBInternalIP::-1}"
    internalrpcip="${internalrpcip::-1}"
    internalrpcip=$internalrpcip.0/26
    sudo sed -i '/# onlynet=ipv4/i\        echo "rpcallowip='${internalrpcip}'\\n";' $STORAGE_ROOT/yiimp/site/web/yaamp/modules/site/coin_form.php
fi

print_header "Keys Configuration"
print_status "Setting up unified keys configuration..."
sudo ln -s /home/crypto-data/yiimp/site/configuration/keys.php /etc/yiimp/keys.php

print_status "Updating exchange configuration paths..."
sudo find $STORAGE_ROOT/yiimp/site/web/yaamp/core/exchange/ -type f -name "*.php" -exec sed -i 's|require_once.*keys.php.*|if (!defined('\''EXCH_POLONIEX_KEY'\'')) {\n    require_once('\''/etc/yiimp/keys.php'\'');\n}|g' {} +

print_status "Updating trading configuration paths..."
sudo find $STORAGE_ROOT/yiimp/site/web/yaamp/core/trading/ -type f -name "*.php" -exec sed -i 's|require_once.*keys.php.*|if (!defined('\''EXCH_POLONIEX_KEY'\'')) {\n    require_once('\''/etc/yiimp/keys.php'\'');\n}|g' {} +

print_success "YiiMP web configuration completed successfully"

print_header "Configuration Summary"
print_info "Domain: ${DomainName}"
print_info "Web Root: /var/www/${DomainName}/html"
print_info "YiiMP Root: ${STORAGE_ROOT}/yiimp/site"
print_info "Configuration: /etc/yiimp"
print_info "Backup Directory: ${STORAGE_ROOT}/yiimp/site/backup"

print_divider

set +eu +o pipefail

cd $HOME/Yiimpoolv1/yiimp_single