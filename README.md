# YiimPool — YiiMP Mining Pool Installer

<p align="center">
  <a href="https://discord.gg/vV3JvN5JFm">
    <img alt="Discord" src="https://img.shields.io/discord/904564600354254898?label=Discord">
  </a>
  <img alt="GitHub issues" src="https://img.shields.io/github/issues/afiniel/Yiimpoolv1">
  <img alt="GitHub release (latest by date)" src="https://img.shields.io/github/v/release/afiniel/Yiimpoolv1">
</p>

## Overview

YiimPool is a fully automated installer for the [YiiMP](https://github.com/Kudaraidee/yiimp) cryptocurrency mining pool software, targeting Ubuntu and Debian servers. It takes a clean system from zero to a fully operational mining pool — including database setup, web server configuration, stratum compilation, SSL certificates, and server hardening — with minimal manual intervention.

**Core capabilities:**

| Feature | Details |
|---------|---------|
| Automated install | Full end-to-end setup of all required components |
| Stratum server | Compiled from source with autoexchange support; auto-registered for reboot via `@reboot` crontab |
| Multi-server | Add remote stratum servers to an existing pool via SSH |
| WireGuard VPN | Optional encrypted tunnel for secure multi-server networking |
| DaemonBuilder | Compile coin daemons from source with autostart on reboot |
| SSL | Let's Encrypt (Certbot) or self-signed; auto-renewed |
| Domain support | Root domain and subdomain configurations |
| SSH hardening | Key-only login, `sshd_config` drop-in, cloud-init override, immediate restart |
| Upgrade tools | In-place YiiMP and stratum upgrades with config backup and restore |
| Health check | Disk, memory, swap, load, CPU, services, stratum sessions, DB sizes, SSL expiry |
| Admin interface | Web-based panel at `/admin/login`; phpMyAdmin included |

---

## System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| RAM | 4 GB | 8 GB+ |
| CPU | 2 cores | 4+ cores |
| Disk | 20 GB | 40 GB+ |
| Network | Static IP | Static IP + domain |

A clean domain or subdomain pointed to your server's IP address is required before installation.

---

## Supported Operating Systems

### Ubuntu
| Version | Status |
|---------|--------|
| Ubuntu 26.04 | ✅ Supported (Not full tested)|
| Ubuntu 25.04 | ✅ Supported |
| Ubuntu 24.04 LTS | ✅ Supported |
| Ubuntu 23.04 | ✅ Supported |
| Ubuntu 22.04 LTS | ✅ Supported |


### Debian
| Version | Status |
|---------|--------|
| Debian 13 (Trixie) | ✅ Supported |
| Debian 12 (Bookworm) | ✅ Supported |
| Debian 11 (Bullseye) | ✅ Supported |

> **Note:** Ubuntu 20.04 standard support ended April 2025 and is now ESM-only. Ubuntu 16.04 and 18.04 are fully end-of-life. These versions are no longer supported. Raspberry Pi OS is not supported.

---

## Installation

### Quick Install

```bash
curl https://raw.githubusercontent.com/afiniel/Yiimpoolv1/master/install.sh | bash
```

### Configuration Steps

The interactive installer will guide you through:

1. **Domain setup** — root domain or subdomain
2. **SSL certificate** — Let's Encrypt (automatic) or self-signed
3. **Database credentials** — auto-generated secure passwords
4. **Admin panel credentials** — username and password for the YiiMP admin panel
5. **Blocknotify password** — used for block notification between the pool and coin daemons
6. **Stratum configuration** — ports and settings for the stratum server
7. **WireGuard VPN** *(optional)* — secure private networking for multi-server setups

---

## Post-Installation

1. **Reboot** your server after installation completes
2. Wait **1–2 minutes** after your first login for all services to initialize
3. Run `motd` to view pool status and service health
4. Verify the installation:
   ```bash
   bash install/post_install_check.sh
   ```
5. Access your pool (replace `your-domain` with your actual domain):
   - **Pool:** `https://your-domain/`
   - **Admin:** `https://your-domain/admin/login`
   - **phpMyAdmin:** `https://your-domain/phpmyadmin`

---

## Adding a Remote Stratum Server

After your primary pool is running, you can add additional stratum servers from the main menu:

```
YiimPool Options → Add New Stratum Server
```

The installer will:
- Prompt for the remote server's IP address, credentials, and stratum URL
- Create a dedicated database user for the remote stratum
- Automatically deploy and configure all required software on the remote server via SSH
- Optionally set up WireGuard VPN between the servers

---

## Directory Structure

| Directory | Purpose |
|-----------|---------|
| `/home/crypto-data/yiimp/` | Main YiiMP directory |
| `/home/crypto-data/yiimp/site/web/` | Web front-end files |
| `/home/crypto-data/yiimp/starts/` | Screen management scripts |
| `/home/crypto-data/yiimp/site/backup/` | Database backups |
| `/home/crypto-data/yiimp/site/configuration/` | Core configuration files |
| `/home/crypto-data/yiimp/site/crons/` | Cron job scripts |
| `/home/crypto-data/yiimp/site/log/` | Log files |
| `/home/crypto-data/yiimp/site/stratum/` | Stratum server files |

---

## Management Commands

### `yiimpool` — Main Management Menu

After installation, the `yiimpool` command is available system-wide. It re-opens the interactive management menu from anywhere on the server:

```bash
yiimpool
```

From this menu you can:
- Run or re-run the full installer
- Access **Manage & Upgrade Options** (upgrade YiiMP, add a stratum server, run database tools)
- Launch the DaemonBuilder

> This command is installed to `/usr/bin/yiimpool` during setup and works regardless of your current working directory.

### Screen Management

```bash
screen -list              # List all running screens
screen -r main            # Attach to the main YiiMP screen
screen -r loop2           # Attach to the loop2 screen
screen -r blocks          # Attach to the blocks screen
screen -r debug           # Attach to the debug screen
Ctrl+A, D                 # Detach from current screen
```

### Service Control

```bash
screens start             # Start all pool services
screens stop              # Stop all pool services
screens restart           # Restart all pool services
yiimp                     # Display pool overview
motd                      # Display system and service status
```

### System Health Check

Run a full health report at any time:

```bash
bash ~/Yiimpoolv1/yiimp_upgrade/health_check.sh
```

Or from the management menu:

```
yiimpool → option 5 → System Health Check
```

The health check covers:

| Check | Details |
|-------|---------|
| Disk space | Usage % with color warnings (yellow >75 %, red >90 %) |
| Swap usage | Total / used / percent (yellow >50 %, red >80 %) |
| Memory | Total, used, free, buff/cache, available |
| Load average | 1 / 5 / 15-minute averages color-coded against CPU core count |
| CPU usage | Current % with top-5 process list |
| Critical services | nginx, MariaDB/MySQL (auto-detected), PHP-FPM (version auto-detected), cron, supervisor, fail2ban |
| Stratum sessions | Lists all active `screen` sessions for running stratums |
| Database sizes | Per-database MB usage sorted largest first |
| SSL certificate | Expiry in days; explicit "EXPIRED" message if already past |

---

## DaemonBuilder

The built-in coin daemon compiler is accessible via:

```bash
daemonbuilder
```

Features:
- Automated build dependency handling
- GCC version management for compatibility
- Support for multiple compile options and configurations
- Custom port configuration per coin via `addport`
- **Coin daemon autostart on reboot** — after a successful build, the daemon is automatically registered in crontab as:
  ```
  @reboot sleep 30 && <coind> -datadir=... -daemon ... >> /var/log/<coin>-daemon-boot.log 2>&1
  ```
  Existing entries for the same coin are deduplicated before the new one is added.
- **Stratum autostart on reboot** — running `addport` registers the stratum process via:
  ```
  @reboot sleep 30 && /usr/bin/stratum.<coin> start <coin> >> /var/log/stratum-<coin>-boot.log 2>&1
  ```
  Both the crontab entry and the immediate launch use the full `/usr/bin/` path, ensuring they work correctly at boot time when `PATH` is not yet populated.

---

## Security Notes

- All database passwords are randomly generated during installation
- UFW firewall is configured automatically (SSH, HTTP, HTTPS, stratum ports)
- Server hardening is applied (SSH key enforcement, fail2ban, etc.)
- Do not modify default file permissions under `/home/crypto-data/`
- Back up your configuration files and database regularly

### SSH Key Login Hardening

When you choose SSH key login during user creation, the following hardening is applied automatically:

| Setting | Value | Where |
|---------|-------|--------|
| Home directory permissions | `755` | Required by `StrictModes` |
| `.ssh/` directory permissions | `700` | Required by `StrictModes` |
| `authorized_keys` permissions | `600` | Required by `StrictModes` |
| `PubkeyAuthentication` | `yes` | sshd config |
| `KbdInteractiveAuthentication` | `no` | sshd config (prevents PAM password prompts) |
| `ChallengeResponseAuthentication` | `no` | sshd config |
| `PasswordAuthentication` | `no` | sshd config |

A drop-in file `/etc/ssh/sshd_config.d/10-yiimpool.conf` is written so the main config is never modified. Any `PasswordAuthentication yes` override left by cloud-init (`50-cloud-init.conf`) is patched automatically. The SSH service is restarted immediately so the new settings take effect without a reboot.

---

## What's New in v2.7.1

### Bug Fixes

- **Stratum upgrade — wrong GCC version** — `upgrade_stratum()` was setting GCC to version 9 before compiling. Changed to GCC 10 and G++ 10 to match the version required by the current yiimp stratum source.
- **Stratum upgrade — wrong build order** — secp256k1 was being compiled before algos/sha3/iniparser. Corrected to: `algos` → `sha3` → `iniparser` → `secp256k1` → `make buildonly`, matching the order required by the updated yiimp stratum Makefile.
- **Stratum upgrade — wrong final make target** — The final stratum build used `make -j$(nproc+1)` instead of `make buildonly`. Fixed to use `make buildonly` as required by the updated stratum source.
- **`update_stratum_conf.sh` — `log_message` not found** — When called via `bash` subshell from the upgrade flow, `log_message` was not in scope because it is defined in `upgrade/utils/functions.sh` (not `/etc/functions.sh`). Fixed by defining `log_message` locally inside the script so it is fully self-contained.

### New Features

- **`yiimp_upgrade/utils/update_stratum_conf.sh`** — New standalone script that applies all pool credentials to every `*.conf` file in the live stratum config directory. Uses the exact same six `sed` substitutions as `yiimp_single/stratum.sh` (blocknotify password, stratum URL, DB host, DB name, DB username, DB password) with full WireGuard-aware host selection. Called automatically by `upgrade_stratum()` after every config restore, and can be run independently at any time:
  ```bash
  bash ~/Yiimpoolv1/yiimp_upgrade/utils/update_stratum_conf.sh
  ```

### Improvements

- **Stratum upgrade — algos/sha3/iniparser parallelism removed** — `-j$(nproc+1)` flags removed from the `make -C algos`, `make -C sha3`, and `make -C iniparser` steps to match the plain serial build required by the updated stratum source.
- **Stratum upgrade — G++ now explicitly set** — `update-alternatives --set g++` is now called alongside `gcc` at both the start and end of the upgrade, ensuring the compiler pair is always consistent.


## Credits

- [Mail-in-a-Box](https://github.com/mail-in-a-box/mailinabox) — base framework and helper functions
- [cryptopool-builders](https://github.com/cryptopool-builders/Multi-Pool-Installer) — original multi-pool installer
- [Kudaraidee/yiimp](https://github.com/Kudaraidee/yiimp) — YiiMP source code

---

## Support

- Open an issue on [GitHub](https://github.com/afiniel/Yiimpoolv1/issues)
- Join the community on [Discord](https://discord.gg/vV3JvN5JFm)

---

## Donations

YiimPool is open-source and free to use. Donations are appreciated but entirely optional.

| Coin | Network | Address |
|------|---------|---------|
| BTC | Bitcoin | `3ELCjkScgaJbnqQiQvXb7Mwos1Y2x7hBFK` |
| ETH | Ethereum | `0xdA929d4f03e1009Fc031210DDE03bC40ea66D044` |
| LTC | Litecoin | `M8uerJZUgBn9KbTn8ng9MasM9nWFgsGftW` |
| DOGE | Dogecoin | `DKBddo8Qoh19PCFtopBkwTpcEU1aAqdM7S` |
| SOL | Solana | `4Akj4XQXEKX4iPEd9A4ogXEPNrAsLm4wdATePz1XnyCu` |
| BEP20 | Binance Smart Chain | `0xdA929d4f03e1009Fc031210DDE03bC40ea66D044` |
| MATIC | Polygon | `0xdA929d4f03e1009Fc031210DDE03bC40ea66D044` |
| TON | TON | `UQBzBvFrVjfo444hGHY2HBPNzL8nEIEzuQBF99PFh1UvyH7w` |
