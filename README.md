# Yiimpool Yiimp Installer with DaemonBuilder

<p align="center">
  <img alt="Discord" src="https://img.shields.io/discord/904564600354254898?label=Discord">
  <img alt="GitHub issues" src="https://img.shields.io/github/issues/afiniel/yiimp_install_script">
  <img alt="GitHub release (latest by date)" src="https://img.shields.io/github/v/release/afiniel/yiimp_install_script">
</p>

## Description

This installer provides an automated way to set up a full Yiimp mining pool on Ubuntu and Debian systems. Key features include:

- Automated installation and configuration of all required components
- Built-in DaemonBuilder for compiling coin daemons
- Multiple SSL configuration options (Let's Encrypt or self-signed)
- Support for both domain and subdomain setups
- Enhanced security features and server hardening
- Automatic stratum setup with autoexchange capability
- Web-based admin interface
- Built-in upgrade tools
- Comprehensive screen management for monitoring
- PhpMyAdmin for database management

## System Requirements

### Standard Linux (Ubuntu/Debian)
- Fresh Ubuntu/Debian installation
- Minimum 8GB RAM (16GB recommended)
- 2+ CPU cores
- Clean domain or subdomain pointed to your VPS

### Android/Termux
- Android device with Termux app installed
- Minimum 4GB RAM (8GB recommended)
- ARM64 or x86_64 architecture
- Stable internet connection
- Termux:Boot addon (recommended for auto-start)

## Supported Operating Systems

### Ubuntu
⚠️ Installation Works (Limited Testing):
- Ubuntu 24.04 LTS
- Ubuntu 23.04
- Ubuntu 22.04 LTS
- Ubuntu 20.04 LTS
- Ubuntu 18.04 LTS

### Debian
⚠️ Installation Works (Limited Testing):
- Debian 11
- Debian 12 (Build Stratum not working)

### Android/Termux
🆕 **NEW**: Android Support via Termux:
- Termux on Android 7.0+
- ARM64 and x86_64 architectures supported
- Limited functionality compared to full Linux
- Requires manual service management

## Installation

### Quick Install (Linux)
```bash
curl https://raw.githubusercontent.com/afiniel/Yiimpoolv1/master/install.sh | bash
```

### Termux Android Install
1. Install Termux from F-Droid (recommended) or Google Play Store
2. Update Termux packages:
   ```bash
   pkg update && pkg upgrade
   ```
3. Install git and curl:
   ```bash
   pkg install git curl
   ```
4. Run the installer:
   ```bash
   curl https://raw.githubusercontent.com/afiniel/Yiimpoolv1/master/install.sh | bash
   ```

📱 **For detailed Termux installation instructions, see [TERMUX_INSTALL.md](TERMUX_INSTALL.md)**

### Configuration Steps
The installer will guide you through:
1. Domain setup (main domain or subdomain)
2. SSL certificate installation
3. Database credentials
4. Admin portal location
5. Email settings
6. Stratum configuration

## Post-Installation Steps

### Linux (Ubuntu/Debian)
1. **Required**: Reboot your server after installation
2. Wait 1-2 minutes after first login for services to initialize
3. Run `motd` to view pool status

### Android/Termux
1. Start services manually: `~/yiimp-services.sh start`
2. Check service status: `~/yiimp-services.sh status`
3. Access web interface at `http://localhost:8080`
4. Install Termux:Boot addon for automatic startup

## Directory Structure

The installer uses a secure directory structure:

| Directory | Purpose |
|-----------|---------|
| /home/crypto-data/yiimp | Main YiiMP directory |
| /home/crypto-data/yiimp/site/web | Web files |
| /home/crypto-data/yiimp/starts | Screen management scripts |
| /home/crypto-data/yiimp/site/backup | Database backups |
| /home/crypto-data/yiimp/site/configuration | Core configuration |
| /home/crypto-data/yiimp/site/crons | Cron job scripts |
| /home/crypto-data/yiimp/site/log | Log files |
| /home/crypto-data/yiimp/site/stratum | Stratum server files |

## Management Commands

### Linux Screen Management
```bash
screen -list         # View all screens
screen -r [name]     # Access screen (main|loop2|blocks|debug)
ctrl+a+d             # Detach from current screen
```

### Linux Service Control
```bash
screens start|stop|restart [service]   # Control specific services
yiimp                                  # View pool overview
motd                                   # Check system status
```

### Termux Service Management
```bash
~/yiimp-services.sh start     # Start all services
~/yiimp-services.sh stop      # Stop all services
~/yiimp-services.sh restart   # Restart all services
~/yiimp-services.sh status    # Check service status
yiimp-logs                    # View logs (alias)
```

## DaemonBuilder

Built-in coin daemon compiler accessible via the `daemonbuilder` command. Features:
- Automated dependency handling
- Support for multiple compile options
- Custom port configuration

## Security Best Practices
1. Keep your system updated regularly
2. Use strong passwords for all services
3. Do not modify default file permissions
4. Regularly backup your data

## Termux-Specific Considerations

### Limitations
- No systemd service management
- Limited SSL/TLS certificate options
- Uses high ports (8080+) to avoid permission issues
- Some cryptocurrency daemons may not compile on ARM
- No root access or traditional user management

### Advantages
- Runs on Android without root
- Portable mining pool setup
- Lower power consumption
- Can run on tablets and phones
- Good for testing and development

### Performance Tips
- Use a device with at least 4GB RAM
- Ensure adequate cooling for extended operation
- Use a stable power source
- Monitor battery usage and temperature

## Support

For assistance:
- Open an issue on GitHub
- Join our Discord server

## Donation wallets if you want to support me Thank you

Donations appreciated:

- BTC: 3ELCjkScgaJbnqQiQvXb7Mwos1Y2x7hBFK

- LTC: M8uerJZUgBn9KbTn8ng9MasM9nWFgsGftW

- DOGE: DHNhm8FqNAQ1VTNwmCHAp3wfQ6PcfzN1nu

- SOLANA: 4Akj4XQXEKX4iPEd9A4ogXEPNrAsLm4wdATePz1XnyCu

- BEP20: 0xdA929d4f03e1009Fc031210DDE03bC40ea66D044

- TON: UQBzBvFrVjfo444hGHY2HBPNzL8nEIEzuQBF99PFh1UvyH7w

