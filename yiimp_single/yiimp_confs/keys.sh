#!/usr/bin/env bash

#####################################################
# Created by Afiniel for Yiimpool use...
#####################################################

source /etc/functions.sh
source /etc/yiimpool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
source $HOME/Yiimpoolv1/yiimp_single/.wireguard.install.cnf

#Create keys file
echo '<?php
// Sample config file to put in /etc/yiimp/keys.php
define('"'"'YIIMP_MYSQLDUMP_USER'"'"', '"'"''"${YiiMPPanelName}"''"'"');
define('"'"'YIIMP_MYSQLDUMP_PASS'"'"', '"'"''"${PanelUserDBPassword}"''"'"');
define('"'"'YIIMP_MYSQLDUMP_PATH'"'"', '"'"''"${STORAGE_ROOT}/yiimp/site/backup"''"'"');

// Keys required to create/cancel orders and access your balances/deposit addresses

define('"'"'EXCH_ALTMARKETS_KEY'"'"', '"'"''"'"');

define('"'"'EXCH_BINANCE_KEY'"'"', '"'"''"'"');
define('"'"'EXCH_BINANCE_SECRET'"'"', '"'"''"'"');

define('"'"'EXCH_CEXIO_SECRET'"'"', '"'"''"'"');

define('"'"'EXCH_EXBITRON_KEY'"'"', '"'"''"'"');

define('"'"'EXCH_HITBTC_SECRET'"'"', '"'"''"'"');
define('"'"'EXCH_HITBTC_KEY'"'"', '"'"''"'"');

define('"'"'EXCH_KRAKEN_KEY'"'"', '"'"''"'"');
define('"'"'EXCH_KRAKEN_SECRET'"'"', '"'"''"'"');

define('"'"'EXCH_KUCOIN_SECRET'"'"', '"'"''"'"');

define('"'"'EXCH_POLONIEX_KEY'"'"', '"'"''"'"');
define('"'"'EXCH_POLONIEX_SECRET'"'"', '"'"''"'"');

define('"'"'EXCH_SAFETRADE_KEY'"'"', '"'"''"'"');
define('"'"'EXCH_SAFETRADE_SECRET'"'"', '"'"''"'"');

define('"'"'EXCH_TRADEOGRE_SECRET'"'"', '"'"''"'"');

define('"'"'EXCH_YOBIT_KEY'"'"', '"'"''"'"');
define('"'"'EXCH_YOBIT_SECRET'"'"', '"'"''"'"');

define('"'"'EXCH_NONKYC_KEY'"'"', '"'"''"'"');
define('"'"'EXCH_NONKYC_SECRET'"'"', '"'"''"'"');

// Automatic withdraw to Yaamp btc wallet if btc balance > 0.3
define('"'"'EXCH_AUTO_WITHDRAW'"'"', 0.3);

' | sudo -E tee $STORAGE_ROOT/yiimp/site/configuration/keys.php >/dev/null 2>&1
cd $HOME/Yiimpoolv1/yiimp_single
