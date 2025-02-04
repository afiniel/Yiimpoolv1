#!/usr/bin/env bash

#####################################################
# Created by Afiniel for Yiimpool use...
#####################################################

# Source necessary configuration files
source /etc/functions.sh
source /etc/yiimpool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
source "$HOME/Yiimpoolv1/yiimp_single/.wireguard.install.cnf"

# Enable strict mode and error handling
set -euo pipefail

# Function to print error trace on error
function print_error {
	read -r line file <<< "$(caller)"
	echo "An error occurred in line $line of file $file:" >&2
	sed "${line}q;d" "$file" >&2
}
trap print_error ERR

# Source wireguard configuration if enabled
if [[ ("$wireguard" == "true") ]]; then
	source "$STORAGE_ROOT/yiimp/.wireguard.conf"
fi

# Generate NGINX configuration for the domain
echo -e "$CYAN => Generating Certbot Request for$GREEN ${DomainName} ${NC}"
sudo mkdir -p /var/www/_letsencrypt
sudo chown www-data /var/www/_letsencrypt
hide_output sudo certbot certonly --webroot -d "${DomainName}" --register-unsafely-without-email -w /var/www/_letsencrypt -n --agree-tos --force-renewal

# Check if Certbot installation was successful
if sudo [ -f "/etc/letsencrypt/live/${DomainName}/fullchain.pem" ]; then
	# Configure Certbot to reload NGINX after successful renewal
	sudo mkdir -p /etc/letsencrypt/renewal-hooks/post/
	echo '#!/bin/bash\nnginx -t && systemctl reload nginx' | sudo -E tee /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh >/dev/null 2>&1
	sudo chmod a+x /etc/letsencrypt/renewal-hooks/post/nginx-reload.sh
	
	# Remove the old NGINX configuration file with self-signed SSL and replace with new configuration
	sudo rm "/etc/nginx/sites-available/${DomainName}.conf"
	echo '#####################################################
# Source Generated by nginxconfig.io
# Updated by afiniel for crypto use...
#####################################################
# NGINX Simple DDoS Defense
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;
limit_conn conn_limit_per_ip 80;
limit_req zone=req_limit_per_ip burst=80 nodelay;
limit_req_zone $binary_remote_addr zone=req_limit_per_ip:40m rate=5r/s;
server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;
	server_name '"${DomainName}"';
	set $base "/var/www/'"${DomainName}"'/html";
	root $base/web;
	# SSL
	ssl_certificate /etc/letsencrypt/live/'"${DomainName}"'/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/'"${DomainName}"'/privkey.pem;
	ssl_trusted_certificate /etc/letsencrypt/live/'"${DomainName}"'/chain.pem;
	# security
	include yiimpool/security.conf;
	# logging
	access_log '"${STORAGE_ROOT}"'/yiimp/site/log/'"${DomainName}"'.app.access.log;
	error_log '"${STORAGE_ROOT}"'/yiimp/site/log/'"${DomainName}"'.app.error.log warn;
	# index.php
	index index.php;
	# index.php fallback
	location / {
		try_files $uri $uri/ /index.php?$args;
	}
	location @rewrite {
		rewrite ^/(.*)$ /index.php?r=$1;
	}
	# handle .php
	location ~ \.php$ {
		include yiimpool/php_fastcgi.conf;
	}
	# additional config
	include yiimpool/general.conf;
	include phpmyadmin.conf;
}
# HTTP redirect
server {
	listen 80;
	listen [::]:80;
	server_name .'"${DomainName}"';
	include yiimpool/letsencrypt.conf;
	location / {
		return 301 https://'"${DomainName}"'$request_uri;
	}
}
' | sudo -E tee "/etc/nginx/sites-available/${DomainName}.conf" >/dev/null 2>&1

	# Restart NGINX and PHP-FPM services
	restart_service nginx >/dev/null 2>&1
	restart_service php8.1-fpm >/dev/null 2>&1
else
	echo -e "Certbot generation failed, after the installer is finished check /var/log/letsencrypt (must be root to view) on why it failed."
fi

# Disable strict mode to avoid unintended errors in subsequent commands
set +euo pipefail

cd $HOME/Yiimpoolv1/yiimp_single
