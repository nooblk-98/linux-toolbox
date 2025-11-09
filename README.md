<div align="center">

# 🐧 Linux Toolbox

### *A Comprehensive Collection of Linux Server Management Scripts*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/nooblk-98/linux-toolbox/graphs/commit-activity)

*Simplify your Linux server administration with interactive, user-friendly scripts*

[Quick Start](#-quick-start) • [Features](#-features) • [Tools](#-tools-overview) • [Documentation](#-documentation)

</div>

---

## 🚀 Quick Start

Launch the interactive toolbox menu with a single command:

```bash
rm -f run.sh; bash <(curl -sSL "https://raw.githubusercontent.com/nooblk-98/linux-toolbox/main/run.sh")
```

**What happens?**
- 📥 Automatically clones/updates the latest version
- 🖥️ Shows real-time system resource monitoring
- 📋 Interactive menu with all available tools
- ✨ Color-coded, user-friendly interface

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 **User-Friendly**
- Interactive menus with color-coded output
- Real-time system resource monitoring
- Step-by-step guided configurations
- Input validation and error handling

</td>
<td width="50%">

### ⚡ **Powerful Automation**
- One-command installation scripts
- Automated backup solutions
- Service management and monitoring
- Batch operations support

</td>
</tr>
<tr>
<td width="50%">

### 🔒 **Security-Focused**
- SSH hardening with best practices
- Fail2ban automatic setup
- Firewall management (UFW)
- SSL/TLS certificate automation

</td>
<td width="50%">

### 🛠️ **Comprehensive Coverage**
- System administration tools
- Web server management
- Development environment setup
- Database installation & management

</td>
</tr>
</table>

---

## 📦 Tools Overview

### 🖥️ **System Administration**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `timezone.sh` | Configure system timezone | Interactive timezone selection, automatic sync |
| `auto-reboot.sh` | Schedule automatic reboots | Flexible scheduling, cron integration |
| `firewall-manager.sh` | UFW firewall management | Rule management, port opening, preset configs |
| `ssh-hardening.sh` | SSH security configuration | Disable root login, key-only auth, custom ports |
| `fail2ban-setup.sh` | Install and configure Fail2ban | Auto-ban malicious IPs, SSH protection |
| `user-manager.sh` | User account management | Create/delete users, sudo access, password reset |
| `backup-manager.sh` | Backup automation tool | Scheduled backups, compression, retention policies |

### 🌐 **Network Tools**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `bandwidth-test.sh` | Network speed testing | Upload/download speed tests, latency checks |
| `port-scanner.sh` | Simple port scanner | Scan open ports, service detection |
| `network-info.sh` | Network configuration display | IP addresses, interfaces, routing tables |
| `smb-mount-manager.sh` | SMB/CIFS mount management | Mount Windows shares, persistent mounts |

### 💻 **Development Tools**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `git-setup.sh` | Git configuration and SSH keys | Generate SSH keys, configure Git globally |
| `python-env.sh` | Python virtual environment manager | Create/manage venvs, package installation |
| `pm2-manager.sh` | PM2 process manager for Node.js | Start/stop/monitor Node apps, auto-restart |
| `github-runner-manager.sh` | GitHub Actions runner manager | Single runner per repository management |
| `github-runner-manage.sh` | Advanced GitHub runner controller | Multiple runners, service management |
| `github-runner-manager-all-in-one.sh` | **⭐ Complete runner solution** | All-in-one script for managing multiple self-hosted GitHub Actions runners |

### 🐳 **Docker Management**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `install.sh` | Install Docker & Docker Compose | Latest version, automatic setup |
| `cleanup.sh` | Remove unused resources | Clean containers, images, volumes, networks |
| `remove-container.sh` | Interactive container removal | Select and remove containers easily |

### 🌍 **Web Server Tools**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `certbot-install.sh` | Install Certbot and plugins | Nginx/Apache plugins, auto-installation |
| `certbot-obtain.sh` | Obtain and apply SSL certificates | Free Let's Encrypt SSL, automatic configuration |
| `certbot-renew.sh` | Renew SSL certificates | Multiple renewal methods, batch renewal |
| `certbot-add-domain.sh` | Add domains to existing certificates | Expand certificate coverage |
| `certbot-auto-renew.sh` | Toggle automatic SSL renewal | Set up auto-renewal cron jobs |
| `reverse-proxy.sh` | Configure reverse proxy | Nginx reverse proxy setup, load balancing |
| `wordpress-backup.sh` | WordPress site backup | Files + database dump, compression |
| `config-checker.sh` | Web server config validator | Detect and fix configuration issues |

### 🗄️ **Database Tools**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `mariadb-phpmyadmin.sh` | Install MariaDB 10 with phpMyAdmin | Complete database + web interface |
| `mysql-install.sh` | Install MySQL server | Secure installation, root password setup |

### 📊 **Monitoring**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `server-health.sh` | Complete server health check | CPU, memory, disk, services, uptime monitoring |

### 🟢 **Node.js & PHP**

| Script | Description | Key Features |
|--------|-------------|--------------|
| `nodejs/install.sh` | Install Node.js and npm | Version selection, NVM support |
| `php/install.sh` | Install PHP | Multiple version support |
| `php/extensions.sh` | Install PHP extensions | Common extensions, interactive selection |

---

## 🎯 Highlighted Features

### ⭐ GitHub Actions Runner Manager (All-in-One)

The crown jewel of this toolbox! Manage multiple self-hosted GitHub Actions runners on a single machine.

**Key Capabilities:**
- 🚀 **One-command installation** with automatic dependency setup
- 🔄 **Interactive & direct modes** for adding/removing runners
- 📊 **Real-time monitoring** with live status updates
- 🔁 **Auto-start on boot** - runners automatically start with the system
- 🐳 **Docker integration** - automatic Docker installation and configuration
- 🛡️ **Systemd service management** - each runner runs as an isolated service
- 📝 **Comprehensive logging** for troubleshooting

**Quick Usage:**
```bash
# Install the complete system
sudo ./github-runner-manager-all-in-one.sh install

# Add a runner interactively
sudo ./github-runner-manager-all-in-one.sh add

# Monitor all runners in real-time
./github-runner-manager-all-in-one.sh monitor

# View detailed status
./github-runner-manager-all-in-one.sh status
```

**Perfect for:**
- Running multiple repository runners on one server
- CI/CD pipeline automation
- Self-hosted GitHub Actions workflows
- Development and testing environments

📖 **Full Documentation:** [ALL_IN_ONE_README.md](tools/development/ALL_IN_ONE_README.md)

---

## 📖 Documentation

### Using the Interactive Menu

1. **Launch the toolbox:**
   ```bash
   bash <(curl -sSL "https://raw.githubusercontent.com/nooblk-98/linux-toolbox/main/run.sh")
   ```

2. **Navigate the menu:**
   - Categories are organized by function
   - System resources displayed at the top
   - Enter the number of your choice
   - Follow interactive prompts

3. **Direct script execution:**
   ```bash
   # Clone the repository
   git clone https://github.com/nooblk-98/linux-toolbox.git
   cd linux-toolbox/tools
   
   # Run any script directly
   sudo bash system/firewall-manager.sh
   sudo bash webserver/certbot-obtain.sh
   sudo bash development/github-runner-manager-all-in-one.sh install
   ```

### System Requirements

- **OS:** Ubuntu 18.04+, Debian 9+, CentOS 7+, or compatible Linux distributions
- **Privileges:** Root or sudo access required for most scripts
- **Dependencies:** Automatically installed when needed
- **Internet:** Required for initial setup and updates

### Best Practices

✅ **Always run** with `sudo` or as root when required  
✅ **Review output** for any errors or warnings  
✅ **Backup** critical configurations before making changes  
✅ **Test** in a safe environment before production use  
✅ **Keep updated** by re-running the quick start command  

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- 🐛 Report bugs
- 💡 Suggest new features
- 🔧 Submit pull requests
- 📖 Improve documentation

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Nooblk**
- GitHub: [@nooblk-98](https://github.com/nooblk-98)

---

## ⭐ Support

If you find this toolbox helpful, please consider giving it a star! ⭐

---

<div align="center">

**Made with ❤️ for the Linux community**

*Simplifying server administration, one script at a time*

</div>

