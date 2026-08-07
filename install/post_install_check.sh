#!/usr/bin/env bash

##################################################################################
# Yiimpool post-install verification script                                       #
# Validates a fresh install: services, web endpoints, database, and key files.   #
##################################################################################

set -uo pipefail

WARNINGS=0
ERRORS=0

# Prefer project functions for consistent output if available
if [ -r /etc/functions.sh ]; then
    # shellcheck disable=SC1091
    source /etc/functions.sh
    have_functions=1
else
    have_functions=0
fi

print_msg() {
    if [ "$have_functions" = 1 ]; then
        case "$1" in
            header)  shift; print_header "$*" ;;
            status)  shift; print_status "$*" ;;
            success) shift; print_success "$*" ;;
            warning) shift; print_warning "$*" ;;
            error)   shift; print_error "$*" ;;
            info)    shift; print_info "$*" ;;
            *)       shift; echo "$*" ;;
        esac
    else
        shift; echo "$*"
    fi
}

record_warning() {
    WARNINGS=$((WARNINGS + 1))
    print_msg warning "$*"
}

record_error() {
    ERRORS=$((ERRORS + 1))
    print_msg error "$*"
}

record_success() {
    print_msg success "$*"
}

service_exists() {
    local svc=$1
    systemctl list-units --type=service --all 2>/dev/null | grep -q "^${svc}\.service"
}

check_service_active() {
    local svc=$1
    local required=${2:-1}

    if ! service_exists "$svc"; then
        if [ "$required" = 1 ]; then
            record_warning "${svc} service unit not found"
        fi
        return 1
    fi

    if systemctl is-active --quiet "$svc"; then
        record_success "${svc} is active"
        return 0
    fi

    if [ "$required" = 1 ]; then
        record_error "${svc} is installed but not active"
    else
        record_warning "${svc} is installed but not active"
    fi
    return 1
}

detect_php_fpm_service() {
    local php_unit v
    php_unit=$(systemctl list-units --type=service --all 2>/dev/null | awk '/php[0-9.]+-fpm\.service/ {print $1; exit}' || true)
    if [ -n "$php_unit" ]; then
        echo "${php_unit%.service}"
        return 0
    fi
    for v in 8.1 8.2 8.3 8.4 8.5; do
        if service_exists "php${v}-fpm"; then
            echo "php${v}-fpm"
            return 0
        fi
    done
    return 1
}

check_file_exists() {
    local path=$1
    local required=${2:-1}

    if [ -e "$path" ]; then
        record_success "Found: $path"
        return 0
    fi

    if [ "$required" = 1 ]; then
        record_error "Missing: $path"
    else
        record_warning "Missing: $path"
    fi
    return 1
}

check_http_endpoint() {
    local path=$1
    local url="${proto}://${DOMAIN}${path}"
    local code

    if ! command -v curl >/dev/null 2>&1; then
        record_warning "curl not installed — skipping HTTP checks"
        return 1
    fi

    code=$(curl -k -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 20 "$url" 2>/dev/null || echo "000")
    print_msg info "GET ${path} -> ${code}"

    case "$code" in
        200|301|302|401|403)
            record_success "Reachable: ${path} (${code})"
            ;;
        000)
            record_error "Unreachable: ${path} (connection failed)"
            ;;
        *)
            record_warning "Unexpected response: ${path} (${code})"
            ;;
    esac
}

check_screen_session() {
    local name=$1
    if screen -ls 2>/dev/null | grep -qE "[[:space:].]+\.${name}[[:space:]]"; then
        record_success "Screen session '${name}' is running"
    else
        record_warning "Screen session '${name}' not running (may start after reboot via screens start)"
    fi
}

# Load installer configs if present
STORAGE_ROOT=/home/crypto-data
VERSION=""
DISTRO=""

if [ -r /etc/yiimpool.conf ]; then
    # shellcheck disable=SC1091
    source /etc/yiimpool.conf
fi
if [ -r /etc/yiimpoolversion.conf ]; then
    # shellcheck disable=SC1091
    source /etc/yiimpoolversion.conf
fi

STORAGE_ROOT=${STORAGE_ROOT:-/home/crypto-data}
DOMAIN=${DomainName:-${PRIMARY_HOSTNAME:-localhost}}
proto=http
InstallSSL=no
YiiMPDBName=""
DBRootPassword=""

if [ -r "$STORAGE_ROOT/yiimp/.yiimp.conf" ]; then
    # shellcheck disable=SC1091
    source "$STORAGE_ROOT/yiimp/.yiimp.conf"
    DOMAIN=${DomainName:-$DOMAIN}
    if [[ "${InstallSSL,,}" == "yes" ]]; then
        proto=https
    fi
fi

print_msg header "YiimPool post-install checks"

# Environment summary
print_msg status "Install environment"
if [ -n "${VERSION:-}" ]; then
    print_msg info "YiimPool version: ${VERSION}"
else
    record_warning "YiimPool version not found (/etc/yiimpoolversion.conf)"
fi
print_msg info "Hostname: $(hostname -f 2>/dev/null || hostname)"
print_msg info "Domain: ${DOMAIN} (${proto})"
print_msg info "Storage root: ${STORAGE_ROOT}"

if command -v lsb_release >/dev/null 2>&1; then
    print_msg info "OS: $(lsb_release -ds 2>/dev/null) ($(lsb_release -rs 2>/dev/null))"
elif [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    print_msg info "OS: ${PRETTY_NAME:-$NAME}"
fi

if [ -r /etc/yiimpool.conf ] && grep -q '^DISTRO=' /etc/yiimpool.conf 2>/dev/null; then
    # shellcheck disable=SC1091
    DISTRO=$(grep '^DISTRO=' /etc/yiimpool.conf | cut -d= -f2 | tr -d '"')
    print_msg info "Distro code: ${DISTRO}"
fi

# 1) Core services
print_msg status "Checking core services"
check_service_active nginx 1

if service_exists mariadb; then
    check_service_active mariadb 1
elif service_exists mysql; then
    check_service_active mysql 1
else
    record_error "Neither mariadb nor mysql service unit found"
fi

php_fpm_svc=""
if php_fpm_svc=$(detect_php_fpm_service); then
    check_service_active "$php_fpm_svc" 1
else
    record_error "No php-fpm service detected"
fi

cron_svc=""
cron_svc=$(systemctl list-units --type=service --all 2>/dev/null | grep -oE '^(cron|crond)\.service' | head -1 | sed 's/\.service//' || true)
if [ -n "$cron_svc" ]; then
    check_service_active "$cron_svc" 1
else
    record_warning "cron service unit not found"
fi

check_service_active fail2ban 0
check_service_active supervisor 0

# 2) Nginx configuration
print_msg status "Checking nginx configuration"
if command -v nginx >/dev/null 2>&1; then
    if sudo nginx -t >/dev/null 2>&1; then
        record_success "nginx configuration is valid"
    else
        record_error "nginx -t failed"
        sudo nginx -t 2>&1 | while read -r line; do print_msg info "$line"; done || true
    fi
else
    record_error "nginx binary not found"
fi

# 3) PHP CLI version
print_msg status "Checking PHP"
if command -v php >/dev/null 2>&1; then
    php_ver=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || php -v | awk '/^PHP/ {print $2}' | cut -d- -f1)
    if [[ "$php_ver" == 8.1* ]]; then
        record_success "PHP ${php_ver} (expected 8.1.x)"
    else
        record_warning "PHP ${php_ver} active (installer expects 8.1.x)"
    fi
else
    record_error "php CLI not found"
fi

# 4) Screen sessions
print_msg status "Checking YiiMP screen sessions"
if command -v screen >/dev/null 2>&1; then
    for session in main loop2 blocks debug; do
        check_screen_session "$session"
    done
    print_msg info "All sessions:"
    screen -ls 2>/dev/null | sed 's/^/  /' || record_warning "No screen sessions listed"
else
    record_error "screen not installed"
fi

# 5) Firewall
print_msg status "Checking firewall"
if command -v ufw >/dev/null 2>&1; then
    ufw status 2>/dev/null | sed 's/^/  /' || true
    if ufw status 2>/dev/null | grep -q "Status: active"; then
        record_success "UFW is active"
    else
        record_warning "UFW is not active"
    fi
else
    record_warning "ufw not installed"
fi

# 6) Web endpoints
print_msg status "Checking web endpoints (${proto}://${DOMAIN})"
for path in "/" "/admin/login" "/phpmyadmin"; do
    check_http_endpoint "$path"
done

# 7) Database connectivity
print_msg status "Checking database connectivity"
my_cnf="${STORAGE_ROOT}/yiimp/.my.cnf"

if [ -n "${DBRootPassword:-}" ]; then
    if mariadb -u root -p"${DBRootPassword}" -e "SELECT 1;" >/dev/null 2>&1; then
        record_success "MariaDB root login succeeded"
        if [ -n "${YiiMPDBName:-}" ]; then
            table_count=$(mariadb -u root -p"${DBRootPassword}" -N -e \
                "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${YiiMPDBName}';" 2>/dev/null || echo "0")
            if [ "${table_count:-0}" -gt 0 ]; then
                record_success "Database '${YiiMPDBName}' has ${table_count} tables"
            else
                record_error "Database '${YiiMPDBName}' exists but has no tables"
            fi
        else
            record_warning "YiiMPDBName not set in .yiimp.conf"
        fi
    else
        record_error "MariaDB root login failed (check DBRootPassword in .yiimp.conf)"
    fi
elif [ -r "$my_cnf" ]; then
    if mariadb --defaults-extra-file="$my_cnf" --defaults-group-suffix=mysql -e "SELECT 1;" >/dev/null 2>&1; then
        record_success "MariaDB client can connect using ${my_cnf} [mysql]"
    else
        record_error "MariaDB client connection failed using ${my_cnf}"
    fi
else
    record_error "No database credentials found (.yiimp.conf DBRootPassword or ${my_cnf})"
fi

# 8) Required files and symlinks
print_msg status "Checking required files"
check_file_exists "$STORAGE_ROOT/yiimp/.yiimp.conf" 1
check_file_exists "$my_cnf" 1
check_file_exists "/etc/yiimp/serverconfig.php" 1
check_file_exists "/etc/yiimp/keys.php" 1
check_file_exists "$STORAGE_ROOT/yiimp/site/configuration/serverconfig.php" 1
check_file_exists "$STORAGE_ROOT/yiimp/site/web/index.php" 1

# 9) Management commands
print_msg status "Checking management commands"
for cmd in yiimpool motd screens stratum; do
    if [ -x "/usr/bin/${cmd}" ]; then
        record_success "/usr/bin/${cmd} is installed"
    else
        record_warning "/usr/bin/${cmd} not found or not executable"
    fi
done

# 10) Stratum
print_msg status "Checking stratum"
check_file_exists "$STORAGE_ROOT/yiimp/site/stratum" 1
stratum_conf_count=0
if [ -d "$STORAGE_ROOT/yiimp/site/stratum/config" ]; then
    stratum_conf_count=$(find "$STORAGE_ROOT/yiimp/site/stratum/config" -maxdepth 1 -name '*.conf' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${stratum_conf_count:-0}" -gt 0 ]; then
        record_success "Found ${stratum_conf_count} stratum config file(s)"
    else
        record_warning "No stratum *.conf files in config directory yet"
    fi
else
    record_warning "Stratum config directory missing"
fi

# 11) SSL (when enabled)
if [[ "${InstallSSL,,}" == "yes" ]]; then
    print_msg status "Checking SSL certificate"
    cert_file=""
    for candidate in \
        "${STORAGE_ROOT}/ssl/ssl_certificate.pem" \
        "${STORAGE_ROOT}/ssl/fullchain.pem" \
        "/etc/letsencrypt/live/${DomainName}/fullchain.pem" \
        "/etc/letsencrypt/live/${DomainName}/cert.pem"; do
        if [ -f "$candidate" ]; then
            cert_file=$candidate
            break
        fi
    done

    if [ -n "$cert_file" ]; then
        record_success "SSL certificate found: ${cert_file}"
        if command -v openssl >/dev/null 2>&1; then
            expiry=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2 || true)
            if [ -n "$expiry" ]; then
                expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
                now_epoch=$(date +%s)
                days_left=$(( (expiry_epoch - now_epoch) / 86400 ))
                if [ "$days_left" -lt 0 ]; then
                    record_error "SSL certificate expired $(( -days_left )) days ago"
                elif [ "$days_left" -lt 30 ]; then
                    record_warning "SSL certificate expires in ${days_left} days"
                else
                    record_success "SSL certificate valid for ${days_left} days"
                fi
            fi
        fi
    else
        record_error "InstallSSL=yes but no certificate file found"
    fi

    if command -v certbot >/dev/null 2>&1; then
        record_success "certbot is installed"
    else
        record_warning "certbot not found (SSL renewal may fail)"
    fi
fi

# 12) Recent logs (debug only — avoid dumping every log on post-install)
print_msg status "Recent debug log"
log_file="${STORAGE_ROOT}/yiimp/site/log/debug.log"
if [ -f "$log_file" ]; then
    print_msg info "==> debug.log (last 20 lines)"
    tail -n 20 "$log_file" | sed 's/^/  /'
else
    record_warning "Debug log not found yet: ${log_file}"
fi

# Summary
print_msg header "Post-install summary"
print_msg info "Errors:   ${ERRORS}"
print_msg info "Warnings: ${WARNINGS}"

if [ "$ERRORS" -gt 0 ]; then
    print_msg error "Post-install checks finished with ${ERRORS} error(s) — review output above"
    exit 1
fi

if [ "$WARNINGS" -gt 0 ]; then
    print_msg warning "Post-install checks finished with ${WARNINGS} warning(s)"
else
    print_msg success "All post-install checks passed"
fi

exit 0
