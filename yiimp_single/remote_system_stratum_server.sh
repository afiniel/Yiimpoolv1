#!/usr/bin/env bash

##################################################################################
# This is the entry point for configuring the system.
# Source https://mailinabox.email/ https://github.com/mail-in-a-box/mailinabox
# Updated by Afiniel for yiimpool use...
##################################################################################

export TERM=xterm

source /etc/functions.sh
source /etc/yiimpool.conf

if [[ ! -e "$STORAGE_ROOT/yiimp/" ]]; then
    sudo mkdir -p "$STORAGE_ROOT/yiimp/"
fi
sudo cp -r /tmp/.yiimp.conf "$STORAGE_ROOT/yiimp/"
source "$STORAGE_ROOT/yiimp/.yiimp.conf"

# source $HOME/Yiimpoolv1/yiimp_single/.wireguard.install.cnf

set -eu -o pipefail

function print_error {
    read -r line file <<< "$(caller)"
    echo "An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" >&2
}
trap print_error ERR

term_art
print_header "Remote Stratum System Configuration"

# Set timezone to UTC
print_status "Setting timezone to UTC..."
if [ ! -f /etc/timezone ]; then
    sudo bash -c 'echo "Etc/UTC" > /etc/timezone'
    restart_service rsyslog
fi

hide_output sudo apt-get install -y software-properties-common build-essential

# CertBot

if [[ "$DISTRO" == "22" || "$DISTRO" == "23" || "$DISTRO" == "24" || "$DISTRO" == "25" ]]; then
    print_status "Installing CertBot (snap)..."
    hide_output sudo apt install -y snapd
    hide_output sudo snap install core
    hide_output sudo snap refresh core
    hide_output sudo snap install --classic certbot
    sudo ln -s /snap/bin/certbot /usr/bin/certbot
    print_success "CertBot installed."

elif [[ "$DISTRO" == "12" || "$DISTRO" == "11" || "$DISTRO" == "13" ]]; then
    print_status "Installing CertBot..."
    hide_output sudo apt install -y certbot
    print_success "CertBot installed."
fi

#if [[ "$DISTRO" == "20" || "$DISTRO" == "22" || "$DISTRO" == "23" || "$DISTRO" == "24" ]]; then
#    echo
#    echo -e "$MAGENTA Detected$GREEN Distro $DISTRO $RED installing requirements.. ${NC}"
#    hide_output sudo apt install -y snapd
#    hide_output sudo snap install bitcoin-core
#    echo -e "$GREEN Completed${NC}"
#fi

print_status "Installing MariaDB..."
hide_output sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8

case "$DISTRO" in
    "22")   # Ubuntu 22.04
        sudo add-apt-repository -y 'deb [arch=amd64,arm64,ppc64el,s390x] https://mirror.mariadb.org/repo/10.6/ubuntu jammy main' >/dev/null 2>&1
        ;;
    "23")   # Ubuntu 23.04
        sudo add-apt-repository -y 'deb [arch=amd64,arm64,ppc64el,s390x] https://mirror.mariadb.org/repo/11.6/ubuntu lunar main' >/dev/null 2>&1
        ;;
    "24")   # Ubuntu 24.04
        sudo add-apt-repository -y 'deb [arch=amd64,arm64,ppc64el,s390x] https://mirror.mariadb.org/repo/11.6/ubuntu noble main' >/dev/null 2>&1
        ;;
    "12")   # Debian 12
        sudo add-apt-repository -y 'deb [arch=amd64,arm64,ppc64el,s390x] https://mirror.mariadb.org/repo/11.6/debian bookworm main' >/dev/null 2>&1
        ;;
    "11")   # Debian 11
        sudo add-apt-repository -y 'deb [arch=amd64,arm64,ppc64el,s390x] https://mirror.mariadb.org/repo/10.6/debian bullseye main' >/dev/null 2>&1
        ;;
    *)
        echo "Unsupported distro version: $DISTRO"
        exit 1
        ;;
esac
print_success "MariaDB repository configured."
hide_output sudo apt-get update
prepare_apt_for_install

if [ ! -f /boot/grub/menu.lst ]; then
    apt_get_quiet upgrade
else
    sudo rm /boot/grub/menu.lst
    sudo update-grub-legacy-ec2 -y
    apt_get_quiet upgrade
fi

apt_get_quiet dist-upgrade
apt_get_quiet autoremove

prepare_apt_for_install

print_status "Installing base system packages..."
hide_output sudo apt install -y python3 python3-dev python3-pip \
    wget curl git sudo coreutils bc \
    haveged pollinate unzip \
    unattended-upgrades cron ntpdate fail2ban screen rsyslog lolcat nginx
print_success "Base system packages installed."

print_status "Initializing system random number generator..."
hide_output dd if=/dev/random of=/dev/urandom bs=1 count=32 2>/dev/null
hide_output sudo pollinate -q -r
print_success "Random number generator initialized."

print_status "Initializing UFW Firewall..."
set +eu +o pipefail
if [ -z "${DISABLE_FIREWALL:-}" ]; then
    hide_output sudo apt-get install -y ufw
    print_status "Allowing incoming connections to SSH, HTTP, and HTTPS..."
    ufw_allow ssh
    sleep 0.5
    print_success "SSH port: OPEN"
    sleep 0.5
    ufw_allow http
    print_success "HTTP port: OPEN"
    sleep 0.5
    ufw_allow https
    print_success "HTTPS port: OPEN"

    SSH_PORT=$(sshd -T 2>/dev/null | grep "^port " | sed "s/port //")
    if [ ! -z "$SSH_PORT" ] && [ "$SSH_PORT" != "22" ]; then
        print_status "Opening alternate SSH port: $SSH_PORT"
        ufw_allow $SSH_PORT
        sleep 0.5
        print_success "Alternate SSH port $SSH_PORT: OPEN"
        ufw_allow http
        sleep 0.5
        ufw_allow https
        sleep 0.5
    fi

    hide_output sudo ufw --force enable
    print_success "UFW Firewall enabled."
fi
set -eu -o pipefail

print_status "Installing YiiMP required system packages..."
if [ -f /usr/sbin/apache2 ]; then
    print_status "Removing Apache..."
    hide_output sudo apt-get -y purge apache2 apache2-*
    hide_output sudo apt-get -y --purge autoremove
fi

hide_output sudo apt-get update

print_status "Installing PHP 8.1..."
sleep 3

if [[ "$DISTRO" == "12" ]]; then
    hide_output sudo apt install -y python3-launchpadlib
fi

if [[ "$DISTRO" == "22" || "$DISTRO" == "23" || "$DISTRO" == "24" || "$DISTRO" == "25" ]]; then
    if ! grep -rq "ondrej/php" /etc/apt/sources.list.d/ 2>/dev/null; then
        hide_output sudo add-apt-repository -y ppa:ondrej/php
    fi
elif [[ "$DISTRO" == "13" || "$DISTRO" == "12" || "$DISTRO" == "11" ]]; then
    if [ ! -f /etc/apt/sources.list.d/ondrej-php.list ]; then
        hide_output sudo apt-get install -y apt-transport-https lsb-release ca-certificates
        wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add -
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
        hide_output sudo apt-get update
    fi
fi

hide_output sudo apt-get update

if [[ "$DISTRO" == "22" || "$DISTRO" == "23" || "$DISTRO" == "24" || "$DISTRO" == "25" ]]; then

    hide_output sudo apt install -y php8.1-fpm php8.1-opcache php8.1 php8.1-common php8.1-gd
    hide_output sudo apt install -y php8.1-mysql php8.1-imap php8.1-cli php8.1-cgi
    hide_output sudo apt install -y php-pear php-auth-sasl mcrypt imagemagick libruby
    hide_output sudo apt install -y php8.1-curl php8.1-intl php8.1-pspell php8.1-sqlite3
    hide_output sudo apt install -y php8.1-tidy php8.1-xmlrpc php8.1-xsl memcached php-memcache
    hide_output sudo apt install -y php-imagick php-gettext php8.1-zip php8.1-mbstring
    hide_output sudo apt install -y fail2ban ntpdate python3 python3-dev python3-pip
    hide_output sudo apt install -y curl git sudo coreutils pollinate unzip unattended-upgrades cron
    hide_output sudo apt install -y pwgen libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev
    hide_output sudo apt install -y libkrb5-dev libldap2-dev libidn11-dev gnutls-dev librtmp-dev
    hide_output sudo apt install -y build-essential libtool autotools-dev automake pkg-config libevent-dev bsdmainutils libssl-dev
    hide_output sudo apt install -y automake cmake gnupg2 ca-certificates lsb-release nginx certbot libsodium-dev
    hide_output sudo apt install -y libnghttp2-dev librtmp-dev libssh2-1 libssh2-1-dev libldap2-dev libidn11-dev libpsl-dev libkrb5-dev php8.1-memcache php8.1-memcached memcached
    hide_output sudo apt install -y php8.1-mysql
    hide_output sudo apt install -y libssh-dev libbrotli-dev php8.1-curl

elif [[ "$DISTRO" == "12" || "$DISTRO" == "11" ]]; then
    # Install packages specific to Debian 12
    hide_output sudo apt install -y php8.1-fpm php8.1-opcache php8.1 php8.1-common php8.1-gd
    hide_output sudo apt install -y php8.1-mysql php8.1-imap php8.1-cli php8.1-cgi
    hide_output sudo apt install -y php-pear php-auth-sasl mcrypt imagemagick libruby
    hide_output sudo apt install -y php8.1-curl php8.1-intl php8.1-pspell php8.1-recode php8.1-sqlite3
    hide_output sudo apt install -y php8.1-tidy php8.1-xmlrpc php8.1-xsl memcached php-memcache
    hide_output sudo apt install -y php-imagick php-gettext php8.1-zip php8.1-mbstring
    hide_output sudo apt install -y fail2ban ntpdate python3 python3-dev python3-pip
    hide_output sudo apt install -y curl git sudo coreutils pollinate unzip unattended-upgrades cron
    hide_output sudo apt install -y pwgen libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev
    hide_output sudo apt install -y libkrb5-dev libldap2-dev libidn11-dev gnutls-dev librtmp-dev
    hide_output sudo apt install -y build-essential libtool autotools-dev automake pkg-config libevent-dev bsdmainutils libssl-dev
    hide_output sudo apt install -y automake cmake gnupg2 ca-certificates lsb-release nginx certbot libsodium-dev
    hide_output sudo apt install -y libnghttp2-dev librtmp-dev libssh2-1 libssh2-1-dev libldap2-dev libidn11-dev libpsl-dev libkrb5-dev php8.1-memcache php8.1-memcached memcached
    hide_output sudo apt install -y php8.1-mysql
    hide_output sudo apt install -y libssh-dev libbrotli-dev php8.1-curl

fi

if [[ ("$DISTRO" == "20" ) || "$DISTRO" == "22" || "$DISTRO" == "23" || "$DISTRO" == "24" ]]; then

	hide_output sudo apt install -y php8.1-fpm php8.1-opcache php8.1 php8.1-common php8.1-gd php8.1-mysql php8.1-imap php8.1-cli
	hide_output sudo apt install -y php8.1-cgi php8.1-curl php8.1-intl php8.1-pspell
	hide_output sudo apt install -y php8.1-sqlite3 php8.1-tidy php8.1-xmlrpc php8.1-xsl php8.1-zip
	hide_output sudo apt install -y php8.1-mbstring php8.1-memcache php8.1-memcached certbot
	hide_output sudo apt install -y libssh-dev libbrotli-dev
	sleep 2
	sudo systemctl start php8.1-fpm
	sudo systemctl status php8.1-fpm | sed -n "1,3p"

    elif [[ "$DISTRO" == "12" || "$DISTRO" == "11" ]]; then

    hide_output sudo apt install -y php8.1-fpm php8.1-opcache php8.1 php8.1-common php8.1-gd php8.1-mysql php8.1-imap php8.1-cli
    hide_output sudo apt install -y php8.1-cgi php8.1-curl php8.1-intl php8.1-pspell
    hide_output sudo apt install -y php8.1-sqlite3 php8.1-tidy php8.1-xmlrpc php8.1-xsl php8.1-zip
    hide_output sudo apt install -y php8.1-mbstring php8.1-memcache php8.1-memcached certbot
    hide_output sudo apt install -y libssh-dev libbrotli-dev
    sleep 2
    sudo systemctl start php8.1-fpm
    sudo systemctl status php8.1-fpm | sed -n "1,3p"
fi

print_status "Setting PHP 8.1 as the system default..."
sudo update-alternatives --set php /usr/bin/php8.1
print_success "PHP 8.1 set as default."

print_status "Cloning YiiMP repository..."
hide_output sudo git clone "${YiiMPRepo}" "$STORAGE_ROOT/yiimp/yiimp_setup/yiimp"
print_success "YiiMP repository cloned."

print_status "Restarting nginx..."
hide_output sudo service nginx restart
sleep 0.5

print_success "Remote stratum system configuration complete."

set +eu +o pipefail
exit 0
