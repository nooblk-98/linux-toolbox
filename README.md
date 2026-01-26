<div align="center">
  <img src="./images/logo.svg" width="360" alt="linux-toolbox logo" />

# Linux Toolbox

**Interactive Linux server management scripts with a fast terminal menu.**

![Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)
![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)
![Scripts](https://img.shields.io/badge/Scripts-23-brightgreen.svg)

</div>

---

## What is included

- Interactive menu runner (`run.sh`) with live system info.
- Curated scripts for networking, security, web servers, Docker, and system admin.
- Installer helpers for Node.js, PHP, and common web stacks.
- Simple maintenance utilities (swap, users, firewall, ports, bandwidth).

---

## Features

### Security and hardening
- SSH hardening with safe defaults.
- Firewall management helper.
- Fail2ban setup automation.

### Ops experience
- Interactive menu with auto-discovered categories.
- Clear prompts and colorized output.
- Works as single scripts or via the menu.

### Stacks covered
- Docker + cleanup utilities.
- Nginx, Apache, and reverse proxy setup.
- Certbot SSL manager.
- Node.js + PM2 process management.
- PHP installer and extensions.

---

## Quick Start

### Option 1: Run the menu (recommended)
```bash
rm -f run.sh; bash <(curl -sSL "https://raw.githubusercontent.com/nooblk-98/linux-toolbox/main/run.sh")
```

### Option 2: Clone and run a script directly
```bash
git clone https://github.com/nooblk-98/linux-toolbox.git
cd linux-toolbox

# Example: install Nginx
sudo bash tools/webserver/install-nginx.sh
```

---

## Script Categories

### Development (5 scripts)
| Script | Description |
|--------|-------------|
| `git-setup.sh` | Configure Git user/email and optionally generate SSH keys |
| `github-runner-manager-all-in-one.sh` | Manage multiple self-hosted GitHub Actions runners |
| `install-php.sh` | Install PHP with selectable versions |
| `install-php-extensions.sh` | Install common PHP extensions |
| `pm2-manager.sh` | Manage PM2 processes (start/stop/logs/monitor) |

---

### Docker (3 scripts)
| Script | Description |
|--------|-------------|
| `install.sh` | Install Docker and Docker Compose |
| `cleanup-docker.sh` | Remove unused Docker resources |
| `remove-containers.sh` | Interactive container removal |

---

### Networking (4 scripts)
| Script | Description |
|--------|-------------|
| `test-bandwidth.sh` | Run a bandwidth speed test |
| `scan-ports.sh` | Quick port scanner |
| `show-network-info.sh` | Display local network information |
| `manage-smb-mounts.sh` | SMB/CIFS mount manager |

---

### Node.js (1 script)
| Script | Description |
|--------|-------------|
| `install.sh` | Install Node.js using NVM |

---

### Security (3 scripts)
| Script | Description |
|--------|-------------|
| `ssh-hardening.sh` | Harden SSH configuration |
| `firewall-manager.sh` | Manage UFW firewall rules |
| `fail2ban-setup.sh` | Install and configure Fail2ban |

---

### System (3 scripts)
| Script | Description |
|--------|-------------|
| `user-manager.sh` | Create/delete users and manage sudo access |
| `swap-manager.sh` | Create and manage swap space |
| `timezone.sh` | Set system timezone interactively |

---

### Web Server (4 scripts)
| Script | Description |
|--------|-------------|
| `install-nginx.sh` | Install Nginx |
| `install-apache.sh` | Install Apache |
| `setup-reverse-proxy.sh` | Configure Nginx reverse proxy |
| `certbot-manager.sh` | All-in-one SSL certificate manager |

---

## Configuration

Notes:
- Most scripts require `sudo` or root privileges.
- The menu auto-discovers scripts from `tools/*/*.sh`.
- Each script is interactive and prompts for required values.

---

## Monitoring and health

- The menu header shows OS, memory usage, and disk usage.
- Most scripts print status messages and provide next-step prompts.

---

## Troubleshooting

- Run scripts with `bash -x` if you need verbose shell debugging.
- If a tool is missing, install it via your package manager and retry.
- For menu issues, verify `curl` and `git` are available.

---

## Contributing

1) Fork and create a feature branch. 2) Make changes with tests or manual checks. 3) Update documentation when behavior changes. 4) Open a PR with a clear summary.

---

## License

No license file is present in this repository. Add one if you want to specify licensing terms.

---

<div align="center">

**Made with ❤️ by NoobLK**

⬆ Back to top

</div>
