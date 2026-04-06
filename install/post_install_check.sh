#!/usr/bin/env bash

##################################################################################
# Yiimpool post-install verification script                                       #
# Runs a series of health checks to validate a fresh install.                     #
##################################################################################

set -euo pipefail

# Prefer project functions for consistent output if available
if [ -r /etc/functions.sh ]; then
    # shellcheck disable=SC1091
    source /etc/functions.sh
    have_functions=1
else
    have_functions=0
fi

print() {
    if [ "$have_functions" = 1 ]; then
        case "$1" in
            header) shift; print_header "$*" ;;
            status) shift; print_status "$*" ;;
            success) shift; print_success "$*" ;;
            warning) shift; print_warning "$*" ;;
            error) shift; print_error "$*" ;;
            info) shift; print_info "$*" ;;
            *) shift; echo "$*" ;;
        esac
    else
        shift; echo "$*"
    fi
}

trap 'status=$?; cmd=$BASH_COMMAND; print error "status=$status cmd=$cmd"' ERR

# Load installer configs if present
if [ -r /etc/yiimpool.conf ]; then
    # shellcheck disable=SC1091
    source /etc/yiimpool.conf
fi
if [ -r /etc/yiimpoolversion.conf ]; then
    # shellcheck disable=SC1091
    source /etc/yiimpoolversion.conf
fi

STORAGE_ROOT=${STORAGE_ROOT:-/home/crypto-data}
DOMAIN=${DomainName:-${PRIMARY_HOSTNAME:-"localhost"}}

proto=http
if [ -r "$STORAGE_ROOT/yiimp/.yiimp.conf" ]; then
    # shellcheck disable=SC1091
    source "$STORAGE_ROOT/yiimp/.yiimp.conf"
    if [[ "${InstallSSL:-no}" == "yes" ]]; then
        proto=https
    fi
fi

print header "YiimPool post-install checks"

# 1) System services
print status "Checking core services"
services=( nginx mariadb mysql fail2ban supervisor )
for svc in "${services[@]}"; do
    if systemctl list-units --type=service --all 2>/dev/null | grep -q "^${svc}\.service"; then
        if systemctl is-active --quiet "$svc"; then
            print success "$svc is active"
        else
            print warning "$svc not active"
        fi
    fi
done
# Dynamically detect any php-fpm unit (avoid pipefail aborts)
set +o pipefail
php_unit=$(systemctl list-units --type=service --all 2>/dev/null | awk '/php.*fpm\.service/ {print $1; exit}' || true)
set -o pipefail
if [ -n "$php_unit" ]; then
    if systemctl is-active --quiet "$php_unit"; then
        print success "$php_unit is active"
    else
        print warning "$php_unit not active"
    fi
else
    print warning "No php-fpm service detected"
fi

# 2) Screens
print status "Checking screen sessions"
if command -v screen >/dev/null 2>&1; then
    # screen returns non-zero when there are no sessions; tolerate that
    screen -list || true
else
    print warning "screen not installed"
fi

# 3) Firewall / ports
print status "Checking firewall and open ports"
if command -v ufw >/dev/null 2>&1; then
    ufw status | cat
else
    print warning "ufw not installed"
fi

# 4) URLs
print status "Checking web endpoints (${proto}://${DOMAIN})"
# Probe admin login and some legacy routes for compatibility
for path in "/" "/admin/login" "/site/AdminPanel" "/site/admin" "/phpmyadmin"; do
    code=$(curl -k -s -o /dev/null -w "%{http_code}" "${proto}://${DOMAIN}${path}" || true)
    print info "GET ${path} -> ${code}"
done

# 5) Database connectivity
print status "Checking database connectivity"
if [ -r "$HOME/.my.cnf" ]; then
    if mysql -e "SELECT 1;" >/dev/null 2>&1; then
        print success "MySQL client can connect with ~/.my.cnf"
    else
        print warning "MySQL client connection failed"
    fi
else
    print warning "~/.my.cnf not found"
fi

# 6) Required files
print status "Checking required files"
req_files=(
  "$STORAGE_ROOT/yiimp/.yiimp.conf"
  "/etc/yiimp/serverconfig.php"
  "/etc/yiimp/keys.php"
)
for f in "${req_files[@]}"; do
    if [ -e "$f" ]; then
        print success "Found: $f"
    else
        print warning "Missing: $f"
    fi
done

# 7) Stratum
print status "Checking stratum directory"
if [ -d "$STORAGE_ROOT/yiimp/site/stratum" ]; then
    print success "Stratum directory present"
else
    print warning "Stratum directory missing"
fi

# 8) Recent logs
print status "Recent YiiMP logs"
log_dir="$STORAGE_ROOT/yiimp/site/log"
if [ -d "$log_dir" ]; then
    for lf in "$log_dir"/*; do
        [ -f "$lf" ] || continue
        print info "==> $(basename "$lf") (last 20 lines)"
        tail -n 20 "$lf" | cat
    done
else
    print warning "Log directory not found: $log_dir"
fi

print success "Checks completed"
exit 0


