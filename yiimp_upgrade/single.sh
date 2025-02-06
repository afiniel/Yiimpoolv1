#!/bin/env bash

#
# This is for upgrading stratum.
#
# Author: afiniel
#
# 2025-02-06
#

source /etc/functions.sh
source /etc/yiimpool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf

YIIMP_DIR="$STORAGE_ROOT/yiimp/yiimp_setup/yiimp"
if [[ -d "$YIIMP_DIR" ]]; then
    sudo rm -rf "$YIIMP_DIR"
fi

echo -e "$GREEN Cloning fresh YiiMP repository... $NC"
if !  sudo git clone "${YiiMPRepo}" "$YIIMP_DIR"; then
    echo -e "$RED Failed to clone YiiMP repository. Exiting... $NC"
    exit 1
fi

echo -e "$GREEN Setting gcc to version 9... $NC"
hide_outputsudo update-alternatives --set gcc /usr/bin/gcc-9

echo
echo -e "$YELLOW => Upgrading stratum <= ${NC}"
echo
cd $YIIMP_DIR/stratum
sudo git submodule init
sudo git submodule update
cd secp256k1 && sudo chmod +x autogen.sh &&  sudo ./autogen.sh &&  sudo ./configure --enable-experimental --enable-module-ecdh --with-bignum=no --enable-endomorphism &&  sudo make -j$((`nproc`+1))
cd $YIIMP_DIR/stratum

echo -e "$GREEN Building stratum... $NC" 

if ! sudo sudo make -C algos -j$(($(nproc)+1)); then
    echo -e "$RED Failed to build stratum. Please check the build output above for errors. Exiting... $NC"
    exit 1
fi
echo -e "$GREEN algos built successfully! $NC"

if ! sudo sudo make -C sha3 -j$(($(nproc)+1)); then
    echo -e "$RED Failed to build sha3. Please check the build output above for errors. Exiting... $NC"
    exit 1
fi
echo -e "$GREEN sha3 built successfully! $NC"

if ! sudo sudo make -C iniparser -j$(($(nproc)+1)); then
    echo -e "$RED Failed to build iniparser. Please check the build output above for errors. Exiting... $NC"
    exit 1
fi
echo -e "$GREEN iniparser built successfully! $NC"

if ! sudo sudo make -j$(($(nproc)+1)); then
    echo -e "$RED Failed to build stratum. Please check the build output above for errors. Exiting... $NC"
    exit 1
fi
echo -e "$GREEN stratum built successfully! $NC"

echo -e "$GREEN Installing stratum... $NC"
if ! sudo mv stratum "$STORAGE_ROOT/yiimp/site/stratum"; then
    echo -e "$RED Failed to install stratum. Exiting... $NC"
    exit 1
fi

echo -e "$GREEN Stratum upgrade completed successfully! $NC"
cd
