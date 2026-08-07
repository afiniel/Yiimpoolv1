#!/usr/bin/env bash

##########################################
# Created by Afiniel for Yiimpool use
#
# This script compiles and sets up the
# Stratum server for a YiiMP cryptocurrency
# mining pool on a remote server. It builds
# necessary components such as blocknotify,
# iniparser, and stratum, sets up the file
# structure, and updates configuration files
# with appropriate database and server
# information.
#
# Author: Afiniel
# Date: 2026-03-06
##########################################

export TERM=xterm

# Load configuration files
source /etc/functions.sh
source /etc/yiimpool.conf
source "$STORAGE_ROOT/yiimp/.yiimp.conf"
source "$HOME/Yiimpoolv1/yiimp_single/.wireguard.install.cnf"

# Display terminal art and initial messages
term_art

# Navigate to the setup directory
cd /home/crypto-data/yiimp/yiimp_setup

print_header "Compiler Setup"
print_status "Installing and configuring GCC & G++"
hide_output sudo apt-get update
hide_output sudo apt-get -y upgrade
apt_dist_upgrade

hide_output sudo apt install -y software-properties-common

if [[ ("${DISTRO}" == "22" || "${DISTRO}" == "23" || "${DISTRO}" == "24" || "${DISTRO}" == "25" || "${DISTRO}" == "26") ]]; then
    hide_output sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
fi
hide_output sudo apt-get update

print_status "Installing GCC versions 9 and 10"
hide_output sudo apt install -y gcc-9 g++-9 gcc-10 g++-10

print_status "Configuring GCC alternatives"
hide_output sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 50 --slave /usr/bin/g++ g++ /usr/bin/g++-9
hide_output sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 60 --slave /usr/bin/g++ g++ /usr/bin/g++-10

hide_output sudo update-alternatives --config gcc
hide_output sudo apt update
hide_output sudo apt upgrade -y

hide_output sudo update-alternatives --set gcc /usr/bin/gcc-9
print_success "GCC & G++ updated to version 9"

print_header "Dependencies Installation"
print_status "Installing required packages for cryptocurrency compilation"
hide_output sudo apt-get update
hide_output sudo apt-get -y upgrade
hide_output sudo apt-get -y install p7zip-full

hide_output sudo apt-get -y install libgmp-dev
hide_output sudo apt-get -y install libmysqlclient-dev
hide_output sudo apt-get -y install libcurl4-openssl-dev

print_status "Installing build dependencies"
hide_output sudo apt install -y build-essential libzmq5 libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils cmake libboost-all-dev zlib1g-dev \
    libseccomp-dev libcap-dev libminiupnpc-dev gettext libcanberra-gtk-module libqrencode-dev libzmq3-dev \
    libqt5gui5 libqt5core5a libqt5webkit5-dev libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler

print_status "Compiling blocknotify and iniparser"

# Compile blocknotify
cd /home/crypto-data/yiimp/yiimp_setup/yiimp/blocknotify
sudo sed -i "s/tu8tu5/$BlocknotifyPassword/" blocknotify.cpp
hide_output sudo make -j$(nproc)

print_status "Building stratum"
cd /home/crypto-data/yiimp/yiimp_setup/yiimp/stratum
hide_output sudo git submodule init
hide_output sudo git submodule update
hide_output sudo make -C algos
hide_output sudo make -C sha3
hide_output sudo make -C iniparser

print_status "Configuring and building secp256k1"
cd secp256k1
sudo chmod +x autogen.sh
hide_output sudo ./autogen.sh
hide_output sudo ./configure --enable-experimental --enable-module-ecdh --with-bignum=no --enable-endomorphism
hide_output sudo make -j$((`nproc`+1))

print_status "Building main stratum"
cd /home/crypto-data/yiimp/yiimp_setup/yiimp/stratum
hide_output sudo make -j$((`nproc`+1))

print_header "File Structure Setup"
print_status "Creating stratum directory structure"
cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp/stratum
sudo cp -a config.sample/. $STORAGE_ROOT/yiimp/site/stratum/config
sudo cp -r stratum run.sh $STORAGE_ROOT/yiimp/site/stratum

cd $STORAGE_ROOT/yiimp/yiimp_setup/yiimp
sudo cp blocknotify/blocknotify $STORAGE_ROOT/yiimp/site/stratum
sudo cp blocknotify/blocknotify /usr/bin

print_status "Creating stratum run scripts"
# Create run.sh for stratum config
sudo tee "$STORAGE_ROOT/yiimp/site/stratum/config/run.sh" > /dev/null <<'EOF'
#!/usr/bin/env bash
source /etc/yiimpool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
ulimit -n 10240
ulimit -u 10240
cd "$STORAGE_ROOT/yiimp/site/stratum"
while true; do
  ./stratum config/$1
  sleep 2
done
exec bash
EOF

sudo chmod +x "$STORAGE_ROOT/yiimp/site/stratum/config/run.sh"

sudo tee "$STORAGE_ROOT/yiimp/site/stratum/run.sh" > /dev/null <<'EOF'
#!/usr/bin/env bash
source /etc/yiimpool.conf
source $STORAGE_ROOT/yiimp/.yiimp.conf
cd "$STORAGE_ROOT/yiimp/site/stratum/config/" && ./run.sh $*
EOF

sudo chmod +x "$STORAGE_ROOT/yiimp/site/stratum/run.sh"

print_header "Stratum Database Configuration"
print_status "Updating stratum configuration with database credentials"
cd "$STORAGE_ROOT/yiimp/site/stratum/config"

sudo sed -i "s/password = tu8tu5/password = $BlocknotifyPassword/g" *.conf
sudo sed -i "s/server = yaamp.com/server = $StratumURL/g" *.conf
if [[ ("$wireguard" == "true") ]]; then
    print_info "Configuring for WireGuard: Using internal IP ${DBInternalIP}"
    sudo sed -i "s/host = yaampdb/host = $DBInternalIP/g" *.conf
else
    print_info "Configuring for local setup: Using localhost"
    sudo sed -i "s/host = yaampdb/host = localhost/g" *.conf
fi
sudo sed -i "s/database = yaamp/database = $YiiMPDBName/g" *.conf
sudo sed -i "s/username = root/username = $StratumDBUser/g" *.conf
sudo sed -i "s/password = patofpaq/password = $StratumUserDBPassword/g" *.conf

print_status "Setting directory permissions"
sudo setfacl -m u:"$USER":rwx "$STORAGE_ROOT/yiimp/site/stratum/"
sudo setfacl -m u:"$USER":rwx "$STORAGE_ROOT/yiimp/site/stratum/config"

# copy blocknotify to daemon servers
# set daemon user and password
DaemonUser=${DaemonUser}
DaemonPass="${DaemonPass}"
DaemonServer=${DaemonInternalIP}

# set script paths
script_blocknotify="${STORAGE_ROOT}/yiimp/site/stratum/blocknotify"

# Desired location of the scripts on the remote server.
remote_script_blocknotify_path="/tmp/blocknotify"

# set ssh Stratum
SSH_ASKPASS_SCRIPT=/tmp/ssh-askpass-script
cat > ${SSH_ASKPASS_SCRIPT} <<EOL
#!/usr/bin/env bash
echo '${DaemonPass}'
EOL
chmod u+x ${SSH_ASKPASS_SCRIPT}

# Set no display, necessary for ssh to play nice with setsid and SSH_ASKPASS.
export DISPLAY=:0

# Tell SSH to read in the output of the provided script as the password.
# We still have to use setsid to eliminate access to a terminal and thus avoid
# it ignoring this and asking for a password.
export SSH_ASKPASS=${SSH_ASKPASS_SCRIPT}

# LogLevel error is to suppress the hosts warning. The others are
# necessary if working with development servers with self-signed
# certificates.
SSH_OPTIONS="-oLogLevel=error"
SSH_OPTIONS="${SSH_OPTIONS} -oStrictHostKeyChecking=no"
SSH_OPTIONS="${SSH_OPTIONS} -oUserKnownHostsFile=/dev/null"

# Load in a base 64 encoded version of the script.
B64_blocknotify=$(base64 --wrap=0 "${script_blocknotify}")

# The command that will run remotely. This unpacks the
# base64-encoded script, makes it executable, and then
# executes it as a background task.
blocknotify="base64 -d - > ${remote_script_blocknotify_path} <<< ${B64_blocknotify};"
blocknotify="${blocknotify} chmod +x ${remote_script_blocknotify_path}; > /dev/null 2>&1 &"

# Execute scripts on remote server
setsid ssh ${SSH_OPTIONS} ${DaemonUser}@${DaemonServer} "${blocknotify}"

print_header "Installation Summary"
print_success "Remote stratum server build completed successfully"
print_info "Stratum URL: $StratumURL"
print_info "Installation Directory: $STORAGE_ROOT/yiimp/site/stratum"
print_info "Configuration Directory: $STORAGE_ROOT/yiimp/site/stratum/config"
print_info "Blocknotify Location: /usr/bin/blocknotify"

print_divider

hide_output sudo update-alternatives --set gcc /usr/bin/gcc-9
exit 0
