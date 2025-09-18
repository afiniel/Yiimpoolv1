#!/bin/bash

##################################################################################
# Termux-specific setup script for Yiimpool
# This script handles the unique requirements of running Yiimpool on Android/Termux
##################################################################################

# Source functions from appropriate location
if [[ -f "$PREFIX/etc/functions.sh" ]]; then
    source "$PREFIX/etc/functions.sh"
elif [[ -f "/etc/functions.sh" ]]; then
    source /etc/functions.sh
else
    echo "Warning: functions.sh not found, some features may not work"
fi

print_header "Termux Setup for Yiimpool"
print_info "Configuring Yiimpool for Android/Termux environment..."

# Update Termux packages
print_status "Updating Termux packages..."
pkg update -y
pkg upgrade -y

# Install essential Termux packages
print_status "Installing essential Termux packages..."
pkg install -y termux-services
pkg install -y nginx
pkg install -y php
pkg install -y php-fpm
pkg install -y mariadb
pkg install -y git
pkg install -y wget
pkg install -y curl
pkg install -y unzip

# Install development tools
print_status "Installing development tools..."
pkg install -y clang
pkg install -y make
pkg install -y cmake
pkg install -y autoconf
pkg install -y automake
pkg install -y libtool
pkg install -y pkg-config

# Install crypto dependencies
print_status "Installing cryptocurrency compilation dependencies..."
pkg install -y openssl-dev
pkg install -y libevent-dev
pkg install -y boost-dev
pkg install -y zlib-dev
pkg install -y libzmq-dev
pkg install -y protobuf-dev
pkg install -y libgmp-dev
pkg install -y libsodium-dev
pkg install -y libcurl-dev

# Setup Termux services
print_status "Setting up Termux services..."
if [ ! -d "$HOME/.termux" ]; then
    mkdir -p "$HOME/.termux"
fi

# Create service directories
mkdir -p "$PREFIX/var/service"
mkdir -p "$PREFIX/etc/sv"

# Setup MariaDB for Termux
print_status "Configuring MariaDB for Termux..."
if [ ! -d "$PREFIX/var/lib/mysql" ]; then
    mysql_install_db --user=mysql --datadir="$PREFIX/var/lib/mysql"
fi

# Setup Nginx for Termux
print_status "Configuring Nginx for Termux..."
if [ ! -f "$PREFIX/etc/nginx/nginx.conf.backup" ]; then
    cp "$PREFIX/etc/nginx/nginx.conf" "$PREFIX/etc/nginx/nginx.conf.backup"
fi

# Create Yiimpool directory structure for Termux
print_status "Creating Yiimpool directory structure..."
TERMUX_YIIMP_ROOT="$HOME/yiimp"
mkdir -p "$TERMUX_YIIMP_ROOT"/{site,stratum,daemon_builder,backups,logs}
mkdir -p "$TERMUX_YIIMP_ROOT/site"/{web,configuration,crons,log}

# Set appropriate permissions (Termux doesn't have traditional user/group system)
print_status "Setting directory permissions..."
chmod -R 755 "$TERMUX_YIIMP_ROOT"

# Create Termux-specific configuration file
print_status "Creating Termux configuration..."
cat > "$HOME/.termux/yiimp.conf" << EOF
# Yiimpool Termux Configuration
TERMUX_YIIMP_ROOT="$TERMUX_YIIMP_ROOT"
TERMUX_PREFIX="$PREFIX"
TERMUX_HOME="$HOME"

# Service ports (use high ports to avoid permission issues)
NGINX_PORT=8080
MYSQL_PORT=3306
STRATUM_PORT=3333

# Termux-specific paths
NGINX_CONF="$PREFIX/etc/nginx"
MYSQL_CONF="$PREFIX/etc/my.cnf"
PHP_CONF="$PREFIX/etc/php"
EOF

# Create service management script for Termux
print_status "Creating service management script..."
cat > "$HOME/yiimp-services.sh" << 'EOF'
#!/bin/bash

# Yiimpool Service Management for Termux

case "$1" in
    start)
        echo "Starting Yiimpool services..."
        # Start MariaDB
        if ! pgrep mysqld > /dev/null; then
            mysqld --user=mysql --datadir="$PREFIX/var/lib/mysql" &
            echo "MariaDB started"
        fi
        
        # Start Nginx
        if ! pgrep nginx > /dev/null; then
            nginx &
            echo "Nginx started"
        fi
        
        # Start PHP-FPM
        if ! pgrep php-fpm > /dev/null; then
            php-fpm &
            echo "PHP-FPM started"
        fi
        
        echo "All services started"
        ;;
    stop)
        echo "Stopping Yiimpool services..."
        pkill nginx
        pkill php-fpm
        pkill mysqld
        echo "All services stopped"
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    status)
        echo "Service Status:"
        echo -n "MariaDB: "
        if pgrep mysqld > /dev/null; then echo "Running"; else echo "Stopped"; fi
        echo -n "Nginx: "
        if pgrep nginx > /dev/null; then echo "Running"; else echo "Stopped"; fi
        echo -n "PHP-FPM: "
        if pgrep php-fpm > /dev/null; then echo "Running"; else echo "Stopped"; fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
EOF

chmod +x "$HOME/yiimp-services.sh"

# Create Termux startup script
print_status "Creating Termux startup script..."
cat > "$HOME/.termux/boot/yiimp-boot.sh" << 'EOF'
#!/bin/bash
# Auto-start Yiimpool services on Termux boot
# Requires Termux:Boot addon

sleep 10  # Wait for Termux to fully initialize
$HOME/yiimp-services.sh start
EOF

mkdir -p "$HOME/.termux/boot"
chmod +x "$HOME/.termux/boot/yiimp-boot.sh"

# Create helpful aliases
print_status "Creating helpful aliases..."
cat >> "$HOME/.bashrc" << 'EOF'

# Yiimpool aliases for Termux
alias yiimp-start='$HOME/yiimp-services.sh start'
alias yiimp-stop='$HOME/yiimp-services.sh stop'
alias yiimp-restart='$HOME/yiimp-services.sh restart'
alias yiimp-status='$HOME/yiimp-services.sh status'
alias yiimp-logs='tail -f $HOME/yiimp/logs/*.log'
EOF

print_success "Termux setup completed successfully!"

print_info "Important Notes for Termux:"
echo -e "${YELLOW}1. Services are managed via $HOME/yiimp-services.sh${NC}"
echo -e "${YELLOW}2. Web interface will be available at http://localhost:8080${NC}"
echo -e "${YELLOW}3. Install Termux:Boot addon for auto-start functionality${NC}"
echo -e "${YELLOW}4. Use high ports (8080+) to avoid permission issues${NC}"
echo -e "${YELLOW}5. Some features may be limited compared to full Linux${NC}"

print_divider