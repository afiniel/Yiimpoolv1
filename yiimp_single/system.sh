#!/usr/bin/env bash

##################################################################################
# This is the entry point for configuring the system.
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by Afiniel for yiimpool use...
##################################################################################

clear
source /etc/functions.sh
source /etc/yiimpool.conf

# Guard: .yiimp.conf is created later in the install — only source if it exists
if [ -f "$STORAGE_ROOT/yiimp/.yiimp.conf" ]; then
    source "$STORAGE_ROOT/yiimp/.yiimp.conf"
fi

set -eu -o pipefail

function print_error {
    read line file <<<$(caller)
    echo "An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" >&2
}
trap print_error ERR

term_art
print_header "System Configuration"
print_info "Starting system configuration..."

# Set timezone to UTC
print_header "Setting TimeZone"
if [ "$(cat /etc/timezone 2>/dev/null)" != "UTC" ]; then
    print_status "Setting timezone to UTC"
    sudo timedatectl set-timezone UTC
    restart_service rsyslog
fi
print_success "Timezone set to UTC"

hide_output sudo apt install -y software-properties-common build-essential gnupg2

# CertBot
print_header "Installing CertBot"
if [[ "$DISTRO" == "22" || "$DISTRO" == "23" || "$DISTRO" == "24" || "$DISTRO" == "25" ]]; then
    print_status "Installing CertBot via Snap for Ubuntu $DISTRO"
    hide_output sudo apt install -y snapd
    hide_output sudo snap install core
    hide_output sudo snap refresh core
    hide_output sudo snap install --classic certbot
    # Only create symlink if it doesn't already exist
    if [ ! -e /usr/bin/certbot ]; then
        sudo ln -s /snap/bin/certbot /usr/bin/certbot
    fi
    print_success "CertBot installation complete"
elif [[ "$DISTRO" == "11" || "$DISTRO" == "12" || "$DISTRO" == "13" ]]; then
    print_status "Installing CertBot for Debian $DISTRO"
    hide_output sudo apt install -y certbot
    print_success "CertBot installation complete"
fi

print_header "Installing MariaDB"

# Create directory for keys if it doesn't exist
if [ ! -d /etc/apt/keyrings ]; then
    sudo mkdir -p /etc/apt/keyrings
fi

# Download and add the MariaDB signing key
if [ ! -f /etc/apt/keyrings/mariadb.gpg ]; then
    print_status "Downloading MariaDB signing key"
    sudo curl -fsSL https://mariadb.org/mariadb_release_signing_key.pgp | sudo gpg --dearmor -o /etc/apt/keyrings/mariadb.gpg
fi

REPO_LINE=""
case "$DISTRO" in
    "22")  # Ubuntu 22.04
        REPO_LINE="deb [signed-by=/etc/apt/keyrings/mariadb.gpg arch=amd64,arm64,ppc64el,s390x] https://mirror.mariadb.org/repo/11.8/ubuntu jammy main"
        ;;
    "23")  # Ubuntu 23.04
        REPO_LINE="deb [signed-by=/etc/apt/keyrings/mariadb.gpg arch=amd64,arm64,ppc64el,s390x] https://mirror.mariadb.org/repo/11.8/ubuntu mantic main"
        ;;
    "24")  # Ubuntu 24.04
        REPO_LINE="deb [signed-by=/etc/apt/keyrings/mariadb.gpg arch=amd64,arm64,ppc64el,s390x] https://mirror.mariadb.org/repo/11.8/ubuntu noble main"
        ;;
    "13")  # Debian 13
        REPO_LINE="deb [signed-by=/etc/apt/keyrings/mariadb.gpg arch=amd64,arm64,i386,ppc64el] https://mirror.mariadb.org/repo/11.8/debian trixie main"
        ;;
    "12")  # Debian 12
        REPO_LINE="deb [signed-by=/etc/apt/keyrings/mariadb.gpg arch=amd64,arm64,i386,ppc64el] https://mirror.mariadb.org/repo/11.8/debian bookworm main"
        ;;
    "11")  # Debian 11
        REPO_LINE="deb [signed-by=/etc/apt/keyrings/mariadb.gpg arch=amd64,arm64,i386,ppc64el] https://mirror.mariadb.org/repo/11.8/debian bullseye main"
        ;;
    "25")  # Ubuntu 25.04
        REPO_LINE="deb [signed-by=/etc/apt/keyrings/mariadb.gpg arch=amd64,arm64,ppc64el,s390x] https://mirror.mariadb.org/repo/11.8/ubuntu plucky main"
        ;;
    *)
        print_error "Unsupported Ubuntu/Debian version: $DISTRO"
        exit 1
        ;;
esac

# Write MariaDB repository to a dedicated sources list file
echo "$REPO_LINE" | sudo tee /etc/apt/sources.list.d/mariadb.list >/dev/null
print_success "MariaDB repository setup complete"


export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

print_header "Updating System"

hide_output sudo apt-get update
hide_output sudo -E apt-get upgrade -y
hide_output sudo -E apt-get dist-upgrade -y
hide_output sudo -E apt-get autoremove -y

print_success "System updated"

print_header "Installing Base System Packages"

hide_output sudo apt install -y python3 python3-dev python3-pip
hide_output sudo apt install -y coreutils bc
hide_output sudo apt install -y haveged pollinate unzip
hide_output sudo apt install -y unattended-upgrades cron ntp fail2ban screen rsyslog nginx haproxy supervisor

print_success "Base system packages installed"

print_header "Initializing System Random Number Generator"
# dd to /dev/urandom is a no-op on modern kernels (3.17+); pollinate handles seeding
hide_output sudo pollinate -q -r
print_success "Random number generator initialized"

print_header "Initializing UFW Firewall"
set +eu +o pipefail
if [ -z "${DISABLE_FIREWALL:-}" ]; then
    hide_output sudo apt-get install -y ufw

    print_status "Configuring firewall rules..."
    ufw_allow ssh
    print_success "SSH port opened"

    ufw_allow http
    print_success "HTTP port opened"

    ufw_allow https
    print_success "HTTPS port opened"

    SSH_PORT=$(sshd -T 2>/dev/null | grep "^port " | sed "s/port //")
    if [ -n "$SSH_PORT" ] && [ "$SSH_PORT" != "22" ]; then
        print_status "Opening alternate SSH port: $SSH_PORT"
        ufw_allow "$SSH_PORT"
        print_success "Alternate SSH port opened"
    fi

    hide_output sudo ufw --force enable
    print_success "Firewall enabled and configured"
fi
set -eu -o pipefail

print_header "Installing YiiMP Required Packages"
if [ -f /usr/sbin/apache2 ]; then
    print_status "Removing Apache..."
    hide_output sudo apt-get -y purge apache2 apache2-*
    hide_output sudo apt-get -y --purge autoremove
    print_success "Apache removed"
fi

print_header "Installing PHP 8.1"

if [[ "$DISTRO" == "11" || "$DISTRO" == "12" || "$DISTRO" == "13" ]]; then
    if [ ! -f /etc/apt/sources.list.d/php.list ]; then
        print_status "Adding PHP repository for Debian $DISTRO"
        hide_output sudo apt install -y apt-transport-https lsb-release ca-certificates
        curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/php.gpg
        echo "deb [signed-by=/etc/apt/keyrings/php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" | \
        sudo tee /etc/apt/sources.list.d/php.list
        hide_output sudo apt-get update
        print_success "PHP repository added"
    fi
    print_success "PHP repository added"
else
    # Check file content rather than filename — handles both .list (older Ubuntu)
    # and .sources (DEB822 format, Ubuntu 22.04+) without a fragile glob.
    if ! grep -rq "ondrej/php" /etc/apt/sources.list.d/ 2>/dev/null; then
        print_status "Adding PHP repository for Ubuntu $DISTRO"
        hide_output sudo add-apt-repository -y ppa:ondrej/php
        hide_output sudo apt-get update
    else
        print_status "PHP repository already exists for Ubuntu $DISTRO"
    fi
    print_success "PHP repository added"
fi

hide_output sudo apt-get update

# Verify php8.1 is actually in the cache — apt-get update exits 0 even when
# individual PPA repos 404, so the file check above can pass for a stale/broken
# PPA entry. Force a clean re-add if the package is still not visible.
if ! apt-cache show php8.1 &>/dev/null; then
    print_status "php8.1 not found in cache — re-adding PHP repository"
    sudo add-apt-repository -y --remove ppa:ondrej/php 2>/dev/null || true
    hide_output sudo add-apt-repository -y ppa:ondrej/php
    hide_output sudo apt-get update
    if ! apt-cache show php8.1 &>/dev/null; then
        print_error "PHP 8.1 is still not available after re-adding the PPA. Cannot continue."
        exit 1
    fi
    print_success "PHP repository added"
fi

print_status "Installing PHP packages..."

print_header "Installing PHP 8.1 packages"
hide_output sudo apt install -y php8.1-fpm php8.1-opcache php8.1 php8.1-common php8.1-gd
hide_output sudo apt install -y php8.1-mysql php8.1-imap php8.1-cli php8.1-cgi
hide_output sudo apt install -y php-pear php-auth-sasl mcrypt imagemagick libruby
hide_output sudo apt install -y php8.1-curl php8.1-intl php8.1-pspell php8.1-sqlite3
hide_output sudo apt install -y php8.1-tidy php8.1-xmlrpc php8.1-xsl memcached php-memcache
hide_output sudo apt install -y php-imagick php-gettext php8.1-zip php8.1-mbstring
hide_output sudo apt install -y fail2ban ntpdate python3 python3-dev python3-pip
hide_output sudo apt install -y coreutils pollinate unzip unattended-upgrades cron
hide_output sudo apt install -y pwgen libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev
hide_output sudo apt install -y libkrb5-dev libldap2-dev libidn11-dev gnutls-dev librtmp-dev
hide_output sudo apt install -y build-essential libtool autotools-dev automake pkg-config libevent-dev bsdmainutils libssl-dev
# Note: certbot is intentionally omitted here — already installed via snap above for Ubuntu
hide_output sudo apt install -y automake cmake gnupg2 ca-certificates lsb-release nginx libsodium-dev
hide_output sudo apt install -y libnghttp2-dev librtmp-dev libssh2-1 libssh2-1-dev libldap2-dev libidn11-dev libpsl-dev libkrb5-dev php8.1-memcache php8.1-memcached memcached
hide_output sudo apt install -y php8.1-mysql php8.1-mbstring
hide_output sudo apt install -y libssh-dev libbrotli-dev php8.1-curl

print_success "PHP 8.1 packages installed"

print_header "Installing phpMyAdmin"
_pma_dir=$(mktemp -d)
print_status "Downloading phpMyAdmin..."
hide_output sudo wget -q -P "$_pma_dir" https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
print_status "Extracting phpMyAdmin..."
hide_output sudo tar xzf "$_pma_dir/phpMyAdmin-latest-all-languages.tar.gz" -C "$_pma_dir"
sudo rm "$_pma_dir/phpMyAdmin-latest-all-languages.tar.gz"
# Remove existing installation so mv replaces rather than nests inside it
if [ -d /usr/share/phpmyadmin ]; then
    sudo rm -rf /usr/share/phpmyadmin
fi
sudo mv "$_pma_dir"/phpMyAdmin-*-all-languages /usr/share/phpmyadmin
sudo rm -rf "$_pma_dir"
sudo mkdir -p /usr/share/phpmyadmin/tmp
sudo chown -R www-data:www-data /usr/share/phpmyadmin/tmp
sudo chmod 755 /usr/share/phpmyadmin/tmp
print_success "phpMyAdmin installation complete"

print_header "Setting PHP Version"
# Register php8.1 first if not already registered, then set as default
if ! update-alternatives --list php 2>/dev/null | grep -q "/usr/bin/php8.1"; then
    sudo update-alternatives --install /usr/bin/php php /usr/bin/php8.1 81
fi
sudo update-alternatives --set php /usr/bin/php8.1
print_success "PHP version set to 8.1"

print_header "Cloning YiiMP Repository"

hide_output sudo git clone "${YiiMPRepo}" "$STORAGE_ROOT/yiimp/yiimp_setup/yiimp"

print_success "YiiMP repository cloned successfully"

print_header "starting services"

hide_output sudo systemctl start nginx
hide_output sudo systemctl start php8.1-fpm

print_success "services started"
# restart_service nginx

set +eu +o pipefail
cd "$HOME/Yiimpoolv1/yiimp_single"
