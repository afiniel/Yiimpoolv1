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
define('"'"'YIIMP_LOGS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/log"''"'"');
define('"'"'YIIMP_HTDOCS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/web"''"'"');
define('"'"'YIIMP_BIN'"'"', '"'"'/bin'"'"');

define('"'"'YIIMP_DBHOST'"'"', '"'"''"localhost"''"'"');
define('"'"'YIIMP_DBNAME'"'"', '"'"''"${YiiMPDBName}"''"'"');
define('"'"'YIIMP_DBUSER'"'"', '"'"''"${YiiMPPanelName}"''"'"');
define('"'"'YIIMP_DBPASSWORD'"'"', '"'"''"${PanelUserDBPassword}"''"'"');

define('"'"'YIIMP_PRODUCTION'"'"', true);
define('"'"'YIIMP_RENTAL'"'"', false); // set to true to enable rental system

define('"'"'YIIMP_LIMIT_ESTIMATE'"'"', false);

define('"'"'YIIMP_FIAT_ALTERNATIVE'"'"', '"'"'USD'"'"'); // USD is main
define('"'"'YIIMP_FEES_SOLO'"'"', 0.5); // Set Pool Fee (solo)
define('"'"'YIIMP_FEES_MINING'"'"', 0.5); // Set Pool Fee (non solo)
define('"'"'YIIMP_FEES_EXCHANGE'"'"', 2); // Set Exchange Fee
define('"'"'YIIMP_FEES_RENTING'"'"', 2); // Set Renting Fee
define('"'"'YIIMP_TXFEE_RENTING_WD'"'"', 0.002); // Set Transaction Fee for Renting Withdraw

define('"'"'YIIMP_TXFEE_RENTING_WD'"'"', 0.002);
define('"'"'YIIMP_PAYMENTS_FREQ'"'"', 1*60*60); // set how often the pool will pay miners
define('"'"'YIIMP_PAYMENTS_MINI'"'"', 0.001); // set minimum payment for miners

define('"'"'YIIMP_ALLOW_EXCHANGE'"'"', false); // allow to exchange coins directly from site wallet
define('"'"'YIIMP_PUBLIC_EXPLORER'"'"', false); // allow public view of site block explorer
define('"'"'YIIMP_PUBLIC_BENCHMARK'"'"', false); // allow public view of site benchmark page


define('"'"'YAAMP_BTCADDRESS'"'"', '"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"');

define('"'"'YIIMP_SITE_URL'"'"', '"'"''"${DomainName}"''"'"');
define('"'"'YIIMP_STRATUM_URL'"'"', '"'"''"${StratumURL}"''"'"'); // change if your stratum server is on a different host
define('"'"'YIIMP_SITE_NAME'"'"', '"'"''"${DomainName}"''"'"'); // Change to your website name.

define('"'"'YIIMP_ADMIN_EMAIL'"'"', '"'"''"${SupportEmail}"''"'"');
define('"'"'YIIMP_ADMIN_IP'"'"', '"'"''"${PublicIP}"''"'"'); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"
define('"'"'YIIMP_ADMIN_USER'"'"', '"'"''"${AdminUser}"''"'"'); // Set Admin User Name
define('"'"'YIIMP_ADMIN_PASS'"'"', '"'"''"${AdminPassword}"''"'"'); // Set Admin User Password

define('"'"'YIIMP_ADMIN_LOGIN'"'"', true);
define('"'"'YIIMP_ADMIN_WEBCONSOLE'"'"', true);
define('"'"'YIIMP_CREATE_NEW_COINS'"'"', true);
define('"'"'YIIMP_NOTIFY_NEW_COINS'"'"', false);

define('"'"'YIIMP_DEFAULT_ALGO'"'"', '"'"'x11'"'"');
define('"'"'YIIMP_USE_NGINX'"'"', true);

// Exchange public keys (private keys are in a separate config file)


define('"'"'YAAMP_USE_NICEHASH_API'"'"', false);
// nicehash keys deposit account & amount to deposit at a time
define('"'"'NICEHASH_API_KEY'"'"','"'"'521c254d-8cc7-4319-83d2-ac6c604b5b49'"'"');
define('"'"'NICEHASH_API_ID'"'"','"'"'9205'"'"');
define('"'"'NICEHASH_DEPOSIT'"'"','"'"'3J9tapPoFCtouAZH7Th8HAPsD8aoykEHzk'"'"');
define('"'"'NICEHASH_DEPOSIT_AMOUNT'"'"','"'"'0.01'"'"');
$cold_wallet_table = array(
'"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"' => 0.10,

);
// Sample fixed pool fees
$configFixedPoolFees = array(
'"'"'zr5'"'"' => 2.0,
'"'"'scrypt'"'"' => 20.0,
'"'"'sha256'"'"' => 5.0,
);
// Sample fixed pool fees solo , With 1.5 default set.
$configFixedPoolFeesSolo = array(
'"'"'zr5'"'"' => 1.5,
'"'"'scrypt'"'"' => 1.5,
'"'"'sha256'"'"' => 1.5,
);
// Sample custom stratum ports
$configCustomPorts = array(
// '"'"'x11'"'"' => 7000,
);
// mBTC Coefs per algo (default is 1.0)
$configAlgoNormCoef = array(
// '"'"'x11'"'"' => 5.0,
);' | sudo -E tee $STORAGE_ROOT/yiimp/site/configuration/serverconfig.php >/dev/null 2>&1

else

	echo '<?php
ini_set('"'"'date.timezone'"'"', '"'"'UTC'"'"');
define('"'"'YIIMP_LOGS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/log"''"'"');
define('"'"'YIIMP_HTDOCS'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/web"''"'"');
define('"'"'YIIMP_BIN'"'"', '"'"'/bin'"'"');
define('"'"'YIIMP_DBHOST'"'"', '"'"''"${DBInternalIP}"''"'"');
define('"'"'YIIMP_DBNAME'"'"', '"'"''"${YiiMPDBName}"''"'"');
define('"'"'YIIMP_DBUSER'"'"', '"'"''"${YiiMPPanelName}"''"'"');
define('"'"'YIIMP_DBPASSWORD'"'"', '"'"''"${PanelUserDBPassword}"''"'"');

define('"'"'YIIMP_PRODUCTION'"'"', true);
define('"'"'YIIMP_RENTAL'"'"', false); // set to true to enable rental system

define('"'"'YIIMP_LIMIT_ESTIMATE'"'"', false);

define('"'"'YIIMP_FIAT_ALTERNATIVE'"'"', '"'"'USD'"'"'); // USD is main
define('"'"'YIIMP_FEES_SOLO'"'"', 0.5); // Set Pool Fee (solo)
define('"'"'YIIMP_FEES_MINING'"'"', 0.5); // Set Pool Fee (non solo)
define('"'"'YIIMP_FEES_EXCHANGE'"'"', 2); // Set Exchange Fee
define('"'"'YIIMP_FEES_RENTING'"'"', 2); // Set Renting Fee

define('"'"'YIIMP_TXFEE_RENTING_WD'"'"', 0.002);
define('"'"'YIIMP_PAYMENTS_FREQ'"'"', 1*60*60); // set how often the pool will pay miners
define('"'"'YIIMP_PAYMENTS_MINI'"'"', 0.001); // set minimum payment for miners

define('"'"'YIIMP_ALLOW_EXCHANGE'"'"', false); // allow to exchange coins directly from site wallet
define('"'"'YIIMP_PUBLIC_EXPLORER'"'"', false); // allow public view of site block explorer
define('"'"'YIIMP_PUBLIC_BENCHMARK'"'"', false); // allow public view of site benchmark page


define('"'"'YIIMP_BTCADDRESS'"'"', '"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"');

define('"'"'YIIMP_SITE_URL'"'"', '"'"''"${DomainName}"''"'"');
define('"'"'YIIMP_STRATUM_URL'"'"', '"'"''"${StratumURL}"''"'"'); // change if your stratum server is on a different host
define('"'"'YIIMP_SITE_NAME'"'"', '"'"''"${DomainName}"''"'"'); // Change to your website name.

define('"'"'YIIMP_ADMIN_EMAIL'"'"', '"'"''"${SupportEmail}"''"'"');
define('"'"'YIIMP_ADMIN_IP'"'"', '"'"''"${PublicIP}"''"'"'); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"
define('"'"'YIIMP_ADMIN_USER'"'"', '"'"''"${AdminUser}"''"'"'); // Set Admin User Name
define('"'"'YIIMP_ADMIN_PASS'"'"', '"'"''"${AdminPassword}"''"'"'); // Set Admin User Password

define('"'"'YIIMP_ADMIN_LOGIN'"'"', true);
define('"'"'YIIMP_ADMIN_WEBCONSOLE'"'"', true);
define('"'"'YIIMP_CREATE_NEW_COINS'"'"', true);
define('"'"'YIIMP_NOTIFY_NEW_COINS'"'"', false);

define('"'"'YIIMP_DEFAULT_ALGO'"'"', '"'"'x11'"'"');
define('"'"'YIIMP_USE_NGINX'"'"', true);

// Exchange public keys (private keys are in a separate config file)


define('"'"'YAAMP_USE_NICEHASH_API'"'"', false);
// nicehash keys deposit account & amount to deposit at a time
define('"'"'NICEHASH_API_KEY'"'"','"'"'521c254d-8cc7-4319-83d2-ac6c604b5b49'"'"');
define('"'"'NICEHASH_API_ID'"'"','"'"'9205'"'"');
define('"'"'NICEHASH_DEPOSIT'"'"','"'"'3J9tapPoFCtouAZH7Th8HAPsD8aoykEHzk'"'"');
define('"'"'NICEHASH_DEPOSIT_AMOUNT'"'"','"'"'0.01'"'"');
$cold_wallet_table = array(
'"'"'bc1qpnxtg3dvtglrvfllfk3gslt6h5zffkf069nh8r'"'"' => 0.10,

);
// Sample fixed pool fees
$configFixedPoolFees = array(
'"'"'zr5'"'"' => 2.0,
'"'"'scrypt'"'"' => 20.0,
'"'"'sha256'"'"' => 5.0,
);
// Sample fixed pool fees solo , With 1.5 default set.
$configFixedPoolFeesSolo = array(
'"'"'zr5'"'"' => 1.5,
'"'"'scrypt'"'"' => 1.5,
'"'"'sha256'"'"' => 1.5,
);
// Sample custom stratum ports
$configCustomPorts = array(
// '"'"'x11'"'"' => 7000,
);
// mBTC Coefs per algo (default is 1.0)
$configAlgoNormCoef = array(
// '"'"'x11'"'"' => 5.0,

);' | sudo -E tee $STORAGE_ROOT/yiimp/site/configuration/serverconfig.php >/dev/null 2>&1
fi
cd $HOME/Yiimpoolv1/yiimp_single