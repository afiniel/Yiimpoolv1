# Yiimpool Installation Guide for Android/Termux

This guide provides detailed instructions for installing Yiimpool on Android devices using Termux.

## Prerequisites

### Required Apps
1. **Termux** - Main terminal emulator
   - Download from [F-Droid](https://f-droid.org/packages/com.termux/) (recommended)
   - Or Google Play Store (limited updates)

2. **Termux:Boot** (Optional but recommended)
   - Enables automatic service startup
   - Download from same source as Termux

3. **Termux:API** (Optional)
   - Provides access to Android APIs
   - Useful for notifications and system integration

### Device Requirements
- Android 7.0 or higher
- Minimum 4GB RAM (8GB recommended)
- 2GB+ free storage space
- ARM64 or x86_64 architecture
- Stable internet connection

## Step-by-Step Installation

### 1. Setup Termux Environment

Open Termux and run the following commands:

```bash
# Update package lists
pkg update

# Upgrade existing packages
pkg upgrade

# Install essential tools
pkg install git curl wget
```

### 2. Download and Run Installer

```bash
# Download the installer
curl https://raw.githubusercontent.com/afiniel/Yiimpoolv1/master/install.sh -o install.sh

# Make it executable
chmod +x install.sh

# Run the installer
./install.sh
```

### 3. Follow Installation Prompts

The installer will automatically detect the Termux environment and:
- Install Termux-specific packages
- Configure services for non-root environment
- Set up directory structure
- Create service management scripts

### 4. Post-Installation Setup

After installation completes:

```bash
# Start all services
~/yiimp-services.sh start

# Check service status
~/yiimp-services.sh status

# View logs
tail -f ~/yiimp/logs/*.log
```

## Service Management

### Starting Services
```bash
~/yiimp-services.sh start
```

### Stopping Services
```bash
~/yiimp-services.sh stop
```

### Restarting Services
```bash
~/yiimp-services.sh restart
```

### Checking Status
```bash
~/yiimp-services.sh status
```

## Accessing Your Pool

Once services are running:
- **Web Interface**: http://localhost:8080
- **Admin Panel**: http://localhost:8080/site/AdminPanel
- **Database**: Connect via MariaDB client on port 3306

## Automatic Startup (Optional)

If you installed Termux:Boot:

1. Grant Termux:Boot permission to run on startup
2. The installer automatically creates a boot script
3. Services will start automatically when Android boots

## Troubleshooting

### Common Issues

**Services won't start**
```bash
# Check if ports are available
netstat -tlnp | grep :8080

# Kill conflicting processes
pkill nginx
pkill mysqld
```

**Database connection issues**
```bash
# Initialize MariaDB if needed
mysql_install_db --user=mysql --datadir="$PREFIX/var/lib/mysql"

# Start MariaDB manually
mysqld --user=mysql --datadir="$PREFIX/var/lib/mysql" &
```

**Web interface not accessible**
```bash
# Check Nginx configuration
nginx -t

# Restart Nginx
pkill nginx
nginx &
```

### Performance Issues

**High battery usage**
- Consider using a power bank or keeping device plugged in
- Monitor CPU usage with `top` command
- Reduce mining intensity if device overheats

**Memory issues**
- Monitor memory usage with `free -h`
- Close unnecessary Android apps
- Consider using swap file (limited benefit on Android)

## Configuration Files

### Main Configuration
- Termux config: `~/.termux/yiimp.conf`
- Nginx config: `$PREFIX/etc/nginx/nginx.conf`
- MariaDB config: `$PREFIX/etc/my.cnf`

### Service Scripts
- Main service script: `~/yiimp-services.sh`
- Boot script: `~/.termux/boot/yiimp-boot.sh`

## Backup and Restore

### Backup Important Data
```bash
# Backup database
mysqldump -u root -p --all-databases > ~/yiimp-backup.sql

# Backup configuration
tar -czf ~/yiimp-config-backup.tar.gz ~/.termux/yiimp.conf $PREFIX/etc/nginx/ $PREFIX/etc/my.cnf
```

### Restore Data
```bash
# Restore database
mysql -u root -p < ~/yiimp-backup.sql

# Restore configuration
tar -xzf ~/yiimp-config-backup.tar.gz -C /
```

## Limitations and Considerations

### Technical Limitations
- No systemd (services managed manually)
- No root access (security through isolation)
- Limited port binding (use ports 8080+)
- Some cryptocurrency daemons may not compile on ARM

### Performance Considerations
- Mobile hardware limitations
- Battery and thermal constraints
- Network stability dependent on mobile connection
- Storage speed limitations

### Security Considerations
- Termux runs in Android app sandbox
- No traditional Linux user permissions
- Network access controlled by Android
- Consider using VPN for additional security

## Advanced Configuration

### Custom Nginx Configuration
Edit `$PREFIX/etc/nginx/nginx.conf` to customize:
- Server ports
- SSL settings (if using custom certificates)
- Performance tuning

### Database Optimization
Edit `$PREFIX/etc/my.cnf` for:
- Memory usage optimization
- Connection limits
- Performance tuning for mobile hardware

### Monitoring and Logging
```bash
# Monitor system resources
top
free -h
df -h

# View service logs
tail -f ~/yiimp/logs/nginx.log
tail -f ~/yiimp/logs/mysql.log
```

## Getting Help

If you encounter issues:

1. Check the main [README.md](README.md) for general guidance
2. Review Termux documentation at [wiki.termux.com](https://wiki.termux.com)
3. Open an issue on GitHub with:
   - Android version
   - Device model
   - Termux version
   - Error messages
   - Steps to reproduce

## Contributing

Help improve Termux support by:
- Testing on different Android versions
- Reporting compatibility issues
- Suggesting performance optimizations
- Contributing code improvements

---

**Note**: This is experimental support. Some features available in the full Linux version may not work or may have limitations on Android/Termux.