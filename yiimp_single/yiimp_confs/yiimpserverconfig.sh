#!/usr/bin/env bash

#####################################################
# Created by Afiniel for Yiimpool use...
#####################################################

source /etc/functions.sh
source /etc/yiimpool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
source $HOME/Yiimpoolv1/yiimp_single/.wireguard.install.cnf

if [[ ("$wireguard" == "false") ]]; then

	echo '<?php

ini_set('"'"'date.timezone'"'"', '"'"'UTC'"'"');

// add defines with YIIMP_ scheme to get rid of YAAMP_ defines over time

define('"'"'YIIMP_MEMCACHE_HOST'"'"', '"'"'127.0.0.1'"'"');
define('"'"'YIIMP_MEMCACHE_PORT'"'"', 11211);

define('"'"'YIIMP_LOGS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/log"''"'"');
define('"'"'YIIMP_HTDOCS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/web"''"'"');
define('"'"'YIIMP_BIN'"'"', '"'"'/bin'"'"');

define('"'"'YIIMP_DBHOST'"'"', '"'"'localhost'"'"');
define('"'"'YIIMP_DBNAME'"'"', '"'"''"${YiiMPDBName}"''"'"');
define('"'"'YIIMP_DBUSER'"'"', '"'"''"${YiiMPPanelName}"''"'"');
define('"'"'YIIMP_DBPASSWORD'"'"', '"'"''"${PanelUserDBPassword}"''"'"');

define('"'"'YIIMP_SITE_URL'"'"', '"'"''"${DomainName}"''"'"');
define('"'"'YIIMP_STRATUM_URL'"'"', YIIMP_SITE_URL); // change if your stratum server is on a different host
define('"'"'YIIMP_SITE_NAME'"'"', '"'"''"${DomainName}"''"'"');

define('"'"'YIIMP_PRODUCTION'"'"', true);

define('"'"'YIIMP_LIMIT_ESTIMATE'"'"', false);

define('"'"'YIIMP_FEES_SOLO'"'"', 1);
define('"'"'YIIMP_FEES_MINING'"'"', 0.5);
define('"'"'YIIMP_FEES_EXCHANGE'"'"', 2);
define('"'"'YIIMP_FEES_RENTING'"'"', 2);
define('"'"'YIIMP_TXFEE_RENTING_WD'"'"', 0.002);
define('"'"'YIIMP_PAYMENTS_FREQ'"'"', 3*60*60);
define('"'"'YIIMP_PAYMENTS_MINI'"'"', 0.001);

define('"'"'YIIMP_ALLOW_EXCHANGE'"'"', false);

define('"'"'YIIMP_BTCADDRESS'"'"', '"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"');

define('"'"'YIIMP_ADMIN_EMAIL'"'"', '"'"''"${SupportEmail}"''"'"');
define('"'"'YIIMP_ADMIN_USER'"'"', '"'"''"${AdminUser}"''"'"');
define('"'"'YIIMP_ADMIN_PASS'"'"', '"'"''"${AdminPassword}"''"'"');
define('"'"'YIIMP_ADMIN_IP'"'"', '"'"''"${PublicIP}"''"'"'); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"
define('"'"'YIIMP_ADMIN_WEBCONSOLE'"'"', true);
define('"'"'YIIMP_CREATE_NEW_COINS'"'"', true);
define('"'"'YIIMP_NOTIFY_NEW_COINS'"'"', false);
define('"'"'YIIMP_DEFAULT_ALGO'"'"', '"'"'x11'"'"');

// old style '"'"'YAAMP_'"'"'

define('"'"'YAAMP_LOGS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/log"''"'"');
define('"'"'YAAMP_HTDOCS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/web"''"'"');
define('"'"'YAAMP_BIN'"'"', '"'"'/bin'"'"');

define('"'"'YAAMP_DBHOST'"'"', '"'"'localhost'"'"');
define('"'"'YAAMP_DBNAME'"'"', '"'"''"${YiiMPDBName}"''"'"');
define('"'"'YAAMP_DBUSER'"'"', '"'"''"${YiiMPPanelName}"''"'"');
define('"'"'YAAMP_DBPASSWORD'"'"', '"'"''"${PanelUserDBPassword}"''"'"');

define('"'"'YAAMP_SITE_URL'"'"', '"'"''"${DomainName}"''"'"');
define('"'"'YAAMP_STRATUM_URL'"'"', YAAMP_SITE_URL); // change if your stratum server is on a different host
define('"'"'YAAMP_SITE_NAME'"'"', '"'"''"${DomainName}"''"'"');

define('"'"'YAAMP_PRODUCTION'"'"', true);

define('"'"'YIIMP_PUBLIC_EXPLORER'"'"', true);
define('"'"'YIIMP_PUBLIC_BENCHMARK'"'"', false);

define('"'"'YAAMP_RENTAL'"'"', true);
define('"'"'YAAMP_LIMIT_ESTIMATE'"'"', false);

define('"'"'YAAMP_FEES_SOLO'"'"', 1);
define('"'"'YAAMP_FEES_MINING'"'"', 0.5);
define('"'"'YAAMP_FEES_EXCHANGE'"'"', 2);
define('"'"'YAAMP_FEES_RENTING'"'"', 2);
define('"'"'YAAMP_TXFEE_RENTING_WD'"'"', 0.002);
define('"'"'YAAMP_PAYMENTS_FREQ'"'"', 3*60*60);
define('"'"'YAAMP_PAYMENTS_MINI'"'"', 0.001);

define('"'"'YAAMP_ALLOW_EXCHANGE'"'"', false);
define('"'"'YIIMP_FIAT_ALTERNATIVE'"'"', '"'"'EUR'"'"'); // USD is main

define('"'"'YAAMP_USE_NICEHASH_API'"'"', false);

define('"'"'YAAMP_BTCADDRESS'"'"', '"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"');

define('"'"'YIIMP_ADMIN_LOGIN'"'"', false);
define('"'"'YAAMP_ADMIN_EMAIL'"'"', '"'"''"${SupportEmail}"''"'"');
define('"'"'YAAMP_ADMIN_USER'"'"', '"'"''"${AdminUser}"''"'"');
define('"'"'YAAMP_ADMIN_PASS'"'"', '"'"''"${AdminPassword}"''"'"');
define('"'"'YAAMP_ADMIN_IP'"'"', '"'"''"${PublicIP}"''"'"'); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"
define('"'"'YAAMP_ADMIN_WEBCONSOLE'"'"', true);
define('"'"'YAAMP_CREATE_NEW_COINS'"'"', true);
define('"'"'YAAMP_NOTIFY_NEW_COINS'"'"', false);
define('"'"'YAAMP_DEFAULT_ALGO'"'"', '"'"'x11'"'"');

/* Github access token used to scan coin repos for new releases */
define('"'"'GITHUB_ACCESSTOKEN'"'"', '"'"'<username>:<api-secret>'"'"');

/* mail server access data to send mails using external mailserver */
define('"'"'SMTP_HOST'"'"', '"'"'mail.example.com'"'"');
define('"'"'SMTP_PORT'"'"', 25);
define('"'"'SMTP_USEAUTH'"'"', true);
define('"'"'SMTP_USERNAME'"'"', '"'"'mailuser'"'"');
define('"'"'SMTP_PASSWORD'"'"', '"'"'mailpassword'"'"');
define('"'"'SMTP_DEFAULT_FROM'"'"', '"'"'mailuser@example.com'"'"');
define('"'"'SMTP_DEFAULT_HELO'"'"', '"'"'mypool-server.example.com'"'"');

define('"'"'YAAMP_USE_NGINX'"'"', true);


// nicehash keys deposit account & amount to deposit at a time
define('"'"'NICEHASH_API_KEY'"'"','"'"'521c254d-8cc7-4319-83d2-ac6c604b5b49'"'"');
define('"'"'NICEHASH_API_ID'"'"','"'"'9205'"'"');
define('"'"'NICEHASH_DEPOSIT'"'"','"'"'3J9tapPoFCtouAZH7Th8HAPsD8aoykEHzk'"'"');
define('"'"'NICEHASH_DEPOSIT_AMOUNT'"'"','"'"'0.01'"'"');

$cold_wallet_table = array(
	'"'"'1C23KmLeCaQSLLyKVykHEUse1R7jRDv9j9'"'"' => 0.10,
);

// Sample fixed pool fees
$configFixedPoolFees = array(
        '"'"'zr5'"'"' => 2.0,
        '"'"'scrypt'"'"' => 20.0,
        '"'"'sha256'"'"' => 5.0,
);

// Sample fixed pool fees solo
$configFixedPoolFeesSolo = array(
		'"'"'zr5'"'"' => 2.0,
        '"'"'scrypt'"'"' => 2.0,
        '"'"'sha256'"'"' => 5.0,
);

// Sample custom stratum ports
$configCustomPorts = array(
//	'"'"'x11'"'"' => 7000,
);

// mBTC Coefs per algo (default is 1.0)
$configAlgoNormCoef = array(
//	'"'"'x11'"'"' => 5.0,
);' | sudo -E tee $STORAGE_ROOT/yiimp/site/configuration/serverconfig.php >/dev/null 2>&1

else

	echo '<?php

ini_set('"'"'date.timezone'"'"', '"'"'UTC'"'"');

// add defines with YIIMP_ scheme to get rid of YAAMP_ defines over time

define('"'"'YIIMP_MEMCACHE_HOST'"'"', '"'"'127.0.0.1'"'"');
define('"'"'YIIMP_MEMCACHE_PORT'"'"', 11211);

define('"'"'YIIMP_LOGS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/log"''"'"');
define('"'"'YIIMP_HTDOCS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/web"''"'"');
define('"'"'YIIMP_BIN'"'"', '"'"'/bin'"'"');

define('"'"'YIIMP_DBHOST'"'"', '"'"''"${DBInternalIP}"''"'"');
define('"'"'YIIMP_DBNAME'"'"', '"'"''"${YiiMPDBName}"''"'"');
define('"'"'YIIMP_DBUSER'"'"', '"'"''"${YiiMPPanelName}"''"'"');
define('"'"'YIIMP_DBPASSWORD'"'"', '"'"''"${PanelUserDBPassword}"''"'"');

define('"'"'YIIMP_SITE_URL'"'"', '"'"''"${DomainName}"''"'"');
define('"'"'YIIMP_STRATUM_URL'"'"', YIIMP_SITE_URL); // change if your stratum server is on a different host
define('"'"'YIIMP_SITE_NAME'"'"', '"'"''"${DomainName}"''"'"');

define('"'"'YIIMP_PRODUCTION'"'"', true);

define('"'"'YIIMP_LIMIT_ESTIMATE'"'"', false);

define('"'"'YIIMP_FEES_SOLO'"'"', 1);
define('"'"'YIIMP_FEES_MINING'"'"', 0.5);
define('"'"'YIIMP_FEES_EXCHANGE'"'"', 2);
define('"'"'YIIMP_FEES_RENTING'"'"', 2);
define('"'"'YIIMP_TXFEE_RENTING_WD'"'"', 0.002);
define('"'"'YIIMP_PAYMENTS_FREQ'"'"', 3*60*60);
define('"'"'YIIMP_PAYMENTS_MINI'"'"', 0.001);

define('"'"'YIIMP_ALLOW_EXCHANGE'"'"', false);

define('"'"'YIIMP_BTCADDRESS'"'"', '"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"');

define('"'"'YIIMP_ADMIN_EMAIL'"'"', '"'"''"${SupportEmail}"''"'"');
define('"'"'YIIMP_ADMIN_USER'"'"', '"'"''"${AdminUser}"''"'"');
define('"'"'YIIMP_ADMIN_PASS'"'"', '"'"''"${AdminPassword}"''"'"');
define('"'"'YIIMP_ADMIN_IP'"'"', '"'"''"${PublicIP}"''"'"'); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"
define('"'"'YIIMP_ADMIN_WEBCONSOLE'"'"', true);
define('"'"'YIIMP_CREATE_NEW_COINS'"'"', true);
define('"'"'YIIMP_NOTIFY_NEW_COINS'"'"', false);
define('"'"'YIIMP_DEFAULT_ALGO'"'"', '"'"'x11'"'"');

// old style '"'"'YAAMP_'"'"'

define('"'"'YAAMP_LOGS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/log"''"'"');
define('"'"'YAAMP_HTDOCS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/web"''"'"');
define('"'"'YAAMP_BIN'"'"', '"'"'/bin'"'"');

define('"'"'YAAMP_DBHOST'"'"', '"'"''"${DBInternalIP}"''"'"');
define('"'"'YAAMP_DBNAME'"'"', '"'"''"${YiiMPDBName}"''"'"');
define('"'"'YAAMP_DBUSER'"'"', '"'"''"${YiiMPPanelName}"''"'"');
define('"'"'YAAMP_DBPASSWORD'"'"', '"'"''"${PanelUserDBPassword}"''"'"');

define('"'"'YAAMP_SITE_URL'"'"', '"'"''"${DomainName}"''"'"');
define('"'"'YAAMP_STRATUM_URL'"'"', YAAMP_SITE_URL); // change if your stratum server is on a different host
define('"'"'YAAMP_SITE_NAME'"'"', '"'"''"${DomainName}"''"'"');

define('"'"'YAAMP_PRODUCTION'"'"', true);

define('"'"'YIIMP_PUBLIC_EXPLORER'"'"', true);
define('"'"'YIIMP_PUBLIC_BENCHMARK'"'"', false);

define('"'"'YAAMP_RENTAL'"'"', true);
define('"'"'YAAMP_LIMIT_ESTIMATE'"'"', false);

define('"'"'YAAMP_FEES_SOLO'"'"', 1);
define('"'"'YAAMP_FEES_MINING'"'"', 0.5);
define('"'"'YAAMP_FEES_EXCHANGE'"'"', 2);
define('"'"'YAAMP_FEES_RENTING'"'"', 2);
define('"'"'YAAMP_TXFEE_RENTING_WD'"'"', 0.002);
define('"'"'YAAMP_PAYMENTS_FREQ'"'"', 3*60*60);
define('"'"'YAAMP_PAYMENTS_MINI'"'"', 0.001);

define('"'"'YAAMP_ALLOW_EXCHANGE'"'"', false);
define('"'"'YIIMP_FIAT_ALTERNATIVE'"'"', '"'"'EUR'"'"'); // USD is main

define('"'"'YAAMP_USE_NICEHASH_API'"'"', false);

define('"'"'YAAMP_BTCADDRESS'"'"', '"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"');

define('"'"'YIIMP_ADMIN_LOGIN'"'"', false);
define('"'"'YAAMP_ADMIN_EMAIL'"'"', '"'"''"${SupportEmail}"''"'"');
define('"'"'YAAMP_ADMIN_USER'"'"', '"'"''"${AdminUser}"''"'"');
define('"'"'YAAMP_ADMIN_PASS'"'"', '"'"''"${AdminPassword}"''"'"');
define('"'"'YAAMP_ADMIN_IP'"'"', '"'"''"${PublicIP}"''"'"'); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"
define('"'"'YAAMP_ADMIN_WEBCONSOLE'"'"', true);
define('"'"'YAAMP_CREATE_NEW_COINS'"'"', true);
define('"'"'YAAMP_NOTIFY_NEW_COINS'"'"', false);
define('"'"'YAAMP_DEFAULT_ALGO'"'"', '"'"'x11'"'"');

/* Github access token used to scan coin repos for new releases */
define('"'"'GITHUB_ACCESSTOKEN'"'"', '"'"'<username>:<api-secret>'"'"');

/* mail server access data to send mails using external mailserver */
define('"'"'SMTP_HOST'"'"', '"'"'mail.example.com'"'"');
define('"'"'SMTP_PORT'"'"', 25);
define('"'"'SMTP_USEAUTH'"'"', true);
define('"'"'SMTP_USERNAME'"'"', '"'"'mailuser'"'"');
define('"'"'SMTP_PASSWORD'"'"', '"'"'mailpassword'"'"');
define('"'"'SMTP_DEFAULT_FROM'"'"', '"'"'mailuser@example.com'"'"');
define('"'"'SMTP_DEFAULT_HELO'"'"', '"'"'mypool-server.example.com'"'"');

define('"'"'YAAMP_USE_NGINX'"'"', true);


// nicehash keys deposit account & amount to deposit at a time
define('"'"'NICEHASH_API_KEY'"'"','"'"'521c254d-8cc7-4319-83d2-ac6c604b5b49'"'"');
define('"'"'NICEHASH_API_ID'"'"','"'"'9205'"'"');
define('"'"'NICEHASH_DEPOSIT'"'"','"'"'3J9tapPoFCtouAZH7Th8HAPsD8aoykEHzk'"'"');
define('"'"'NICEHASH_DEPOSIT_AMOUNT'"'"','"'"'0.01'"'"');

$cold_wallet_table = array(
	'"'"'1C23KmLeCaQSLLyKVykHEUse1R7jRDv9j9'"'"' => 0.10,
);

// Sample fixed pool fees
$configFixedPoolFees = array(
        '"'"'zr5'"'"' => 2.0,
        '"'"'scrypt'"'"' => 20.0,
        '"'"'sha256'"'"' => 5.0,
);

// Sample fixed pool fees solo
$configFixedPoolFeesSolo = array(
		'"'"'zr5'"'"' => 2.0,
        '"'"'scrypt'"'"' => 2.0,
        '"'"'sha256'"'"' => 5.0,
);

// Sample custom stratum ports
$configCustomPorts = array(
//	'"'"'x11'"'"' => 7000,
);

// mBTC Coefs per algo (default is 1.0)
$configAlgoNormCoef = array(
//	'"'"'x11'"'"' => 5.0,
);' | sudo -E tee $STORAGE_ROOT/yiimp/site/configuration/serverconfig.php >/dev/null 2>&1
fi
cd $HOME/Yiimpoolv1/yiimp_single
