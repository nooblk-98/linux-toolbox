<div align="center">

# 🐧 Linux Toolbox

### *A Comprehensive Collection of Linux Server Management Scripts for DevOps*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/nooblk-98/linux-toolbox/graphs/commit-activity)

*Simplify your Linux server administration with 143+ interactive, user-friendly scripts*

[Quick Start](#-quick-start) • [Features](#-features) • [Categories](#-script-categories) • [Documentation](#-documentation)

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
- 📋 Interactive menu with 12 organized categories
- ✨ Color-coded, emoji-enhanced interface
- 🎯 143+ DevOps-focused scripts

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 🎯 **User-Friendly**
- Interactive menus with emoji indicators
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
- Security auditing tools

</td>
<td width="50%">

### 🛠️ **Comprehensive Coverage**
- 12 organized categories
- 143+ scripts and growing
- Kubernetes & container orchestration
- CI/CD pipeline tools
- Full observability stack

</td>
</tr>
</table>

---

## 📦 Script Categories

### 🖥️ **Core System** (10 scripts)
Essential system administration and maintenance tools.

| Script | Description |
|--------|-------------|
| `set-timezone.sh` | Configure system timezone interactively |
| `schedule-reboot.sh` | Schedule automatic system reboots |
| `manage-users.sh` | User account management (create/delete/sudo) |
| `system-info.sh` | Comprehensive system information display |
| `disk-manager.sh` | Disk usage analysis and cleanup |
| `service-manager.sh` | Systemd service management helper |
| `package-manager.sh` | Universal package manager wrapper |
| `kernel-update.sh` | Safe kernel update and rollback |
| `performance-tuning.sh` | System performance optimization |
| `log-analyzer.sh` | System log analysis and rotation |

---

### 🔒 **Security** (11 scripts)
Security hardening, compliance, and auditing tools.

| Script | Description |
|--------|-------------|
| `manage-firewall.sh` | UFW firewall rule management |
| `harden-ssh.sh` | SSH security configuration (key-only auth, custom ports) |
| `setup-fail2ban.sh` | Fail2ban installation and configuration |
| `security-audit.sh` | Comprehensive security audit (CIS benchmarks) |
| `ssl-checker.sh` | SSL/TLS certificate validator and monitor |
| `port-security.sh` | Open port scanner and security checker |
| `selinux-manager.sh` | SELinux configuration and troubleshooting |
| `apparmor-manager.sh` | AppArmor profile management |
| `vulnerability-scan.sh` | Basic vulnerability scanner (Lynis integration) |
| `password-policy.sh` | Enforce password policies |
| `audit-logs.sh` | Security audit log analyzer |

---

### 🌐 **Networking** (11 scripts)
Network configuration, diagnostics, and monitoring tools.

| Script | Description |
|--------|-------------|
| `test-bandwidth.sh` | Network speed testing (upload/download) |
| `scan-ports.sh` | Simple port scanner |
| `show-network-info.sh` | Network configuration display |
| `manage-smb-mounts.sh` | SMB/CIFS mount management |
| `dns-manager.sh` | DNS configuration and testing |
| `network-diagnostics.sh` | Comprehensive network troubleshooting |
| `vpn-setup.sh` | WireGuard/OpenVPN setup wizard |
| `traffic-monitor.sh` | Real-time network traffic monitoring |
| `firewall-rules.sh` | Advanced iptables/nftables management |
| `load-balancer.sh` | HAProxy/Nginx load balancer setup |
| `network-benchmark.sh` | Network performance benchmarking |

---

### 🐳 **Containers** (10 scripts)
Docker and container management tools.

| Script | Description |
|--------|-------------|
| `install-docker.sh` | Docker & Docker Compose installation |
| `cleanup-docker.sh` | Remove unused containers/images/volumes |
| `remove-containers.sh` | Interactive container removal |
| `docker-compose-manager.sh` | Docker Compose project management |
| `docker-security-scan.sh` | Container security scanning (Trivy) |
| `docker-registry.sh` | Private Docker registry setup |
| `docker-network-manager.sh` | Docker network management |
| `docker-volume-manager.sh` | Docker volume backup/restore |
| `podman-setup.sh` | Podman installation and migration |
| `container-health.sh` | Container health monitoring |

---

### ☸️ **Kubernetes** (10 scripts)
Kubernetes cluster management and deployment tools.

| Script | Description |
|--------|-------------|
| `install-k3s.sh` | Lightweight Kubernetes (K3s) installation |
| `install-minikube.sh` | Minikube setup for local development |
| `kubectl-setup.sh` | kubectl and kubeconfig management |
| `helm-manager.sh` | Helm chart deployment and management |
| `k8s-dashboard.sh` | Kubernetes dashboard installation |
| `k8s-monitoring.sh` | Prometheus + Grafana for K8s |
| `k8s-ingress.sh` | Ingress controller setup (Nginx/Traefik) |
| `k8s-backup.sh` | Velero backup setup |
| `k8s-troubleshoot.sh` | Kubernetes troubleshooting helper |
| `k8s-secrets.sh` | Secrets management (Sealed Secrets/Vault) |

---

### 🔄 **CI/CD** (10 scripts)
Continuous Integration and Deployment pipeline tools.

| Script | Description |
|--------|-------------|
| `github-runner-basic.sh` | GitHub Actions runner (single instance) |
| `github-runner-advanced.sh` | ⭐ Advanced GitHub runner manager (multi-instance) |
| `jenkins-setup.sh` | Jenkins installation and configuration |
| `gitlab-runner.sh` | GitLab CI runner setup |
| `drone-ci.sh` | Drone CI installation |
| `argocd-setup.sh` | ArgoCD for GitOps |
| `tekton-setup.sh` | Tekton Pipelines installation |
| `sonarqube-setup.sh` | Code quality analysis setup |
| `nexus-setup.sh` | Artifact repository setup |
| `pipeline-templates.sh` | CI/CD pipeline template generator |

---

### 🌍 **Web Server** (12 scripts)
Web server installation, configuration, and SSL management.

| Script | Description |
|--------|-------------|
| `certbot-manager.sh` | ⭐ **All-in-One SSL Manager** (install, obtain, renew, manage certificates) |
| `setup-reverse-proxy.sh` | Configure Nginx reverse proxy |
| `backup-wordpress.sh` | WordPress site backup (files + database) |
| `check-webserver-config.sh` | Web server config validator |
| `install-nginx.sh` | Nginx installation and basic config |
| `install-apache.sh` | Apache installation and basic config |
| `install-caddy.sh` | Caddy web server setup |
| `vhost-manager.sh` | Virtual host management |
| `php-fpm-tuning.sh` | PHP-FPM optimization |
| `cache-setup.sh` | Redis/Memcached setup |
| `cdn-setup.sh` | CDN configuration helper |
| `waf-setup.sh` | ModSecurity WAF setup |

---

### 🗄️ **Database** (10 scripts)
Database installation, management, and optimization.

| Script | Description |
|--------|-------------|
| `install-mariadb-phpmyadmin.sh` | MariaDB 10 with phpMyAdmin |
| `install-mysql.sh` | MySQL server installation |
| `install-postgresql.sh` | PostgreSQL installation |
| `install-mongodb.sh` | MongoDB installation |
| `install-redis.sh` | Redis installation and configuration |
| `db-backup.sh` | Universal database backup script |
| `db-restore.sh` | Database restoration helper |
| `db-replication.sh` | Database replication setup |
| `db-performance.sh` | Database performance tuning |
| `db-migration.sh` | Database migration helper |

---

### 📊 **Observability** (10 scripts)
Monitoring, logging, and alerting solutions.

| Script | Description |
|--------|-------------|
| `check-server-health.sh` | Complete server health check |
| `prometheus-setup.sh` | Prometheus monitoring installation |
| `grafana-setup.sh` | Grafana dashboard installation |
| `elk-stack.sh` | ELK Stack (Elasticsearch, Logstash, Kibana) |
| `loki-setup.sh` | Grafana Loki for log aggregation |
| `alertmanager-setup.sh` | Prometheus Alertmanager |
| `node-exporter.sh` | Prometheus Node Exporter |
| `uptime-kuma.sh` | Uptime monitoring dashboard |
| `netdata-setup.sh` | Real-time performance monitoring |
| `log-aggregation.sh` | Centralized logging setup |
| `apm-setup.sh` | Application Performance Monitoring |

---

### 🤖 **Automation** (8 scripts)
Infrastructure as Code and configuration management tools.

| Script | Description |
|--------|-------------|
| `ansible-setup.sh` | Ansible installation and configuration |
| `terraform-setup.sh` | Terraform installation and workspace setup |
| `ansible-playbook-runner.sh` | Ansible playbook execution helper |
| `terraform-manager.sh` | Terraform state and workspace management |
| `packer-setup.sh` | Packer for image building |
| `vagrant-setup.sh` | Vagrant development environment |
| `pulumi-setup.sh` | Pulumi infrastructure as code |
| `cloud-init-generator.sh` | Cloud-init configuration generator |

---

### 💻 **Development** (13 scripts)
Developer tools and environment setup.

| Script | Description |
|--------|-------------|
| `setup-git.sh` | Git configuration and SSH keys |
| `manage-python-env.sh` | Python virtual environment manager |
| `manage-pm2.sh` | PM2 process manager for Node.js |
| `install-nodejs.sh` | Node.js installation (NVM support) |
| `install-php.sh` | PHP installation (multiple versions) |
| `install-php-extensions.sh` | PHP extensions installation |
| `install-go.sh` | Go language installation |
| `install-rust.sh` | Rust toolchain installation |
| `install-java.sh` | Java JDK installation |
| `vscode-server.sh` | VS Code Server setup |
| `tmux-setup.sh` | Tmux configuration and session manager |
| `dotfiles-manager.sh` | Dotfiles backup and restore |
| `dev-environment.sh` | Complete dev environment setup |

---

### 💾 **Backup & Recovery** (8 scripts)
Backup automation and disaster recovery tools.

| Script | Description |
|--------|-------------|
| `manage-backups.sh` | Backup automation tool |
| `restic-setup.sh` | Restic backup tool setup |
| `borg-backup.sh` | BorgBackup installation and configuration |
| `snapshot-manager.sh` | LVM/ZFS snapshot management |
| `disaster-recovery.sh` | Disaster recovery planning tool |
| `cloud-backup.sh` | Cloud backup integration (S3, B2, etc.) |
| `backup-verification.sh` | Backup integrity verification |
| `restore-wizard.sh` | Interactive restore wizard |

---

## 🎯 Highlighted Features

### ⭐ GitHub Actions Runner Manager (Advanced)

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
sudo ./github-runner-advanced.sh install

# Add a runner interactively
sudo ./github-runner-advanced.sh add

# Monitor all runners in real-time
./github-runner-advanced.sh monitor

# View detailed status
./github-runner-advanced.sh status
```

**Perfect for:**
- Running multiple repository runners on one server
- CI/CD pipeline automation
- Self-hosted GitHub Actions workflows
- Development and testing environments

---

## 📖 Documentation

### Using the Interactive Menu

1. **Launch the toolbox:**
   ```bash
   bash <(curl -sSL "https://raw.githubusercontent.com/nooblk-98/linux-toolbox/main/run.sh")
   ```

2. **Navigate the menu:**
   - 12 categories organized by function with emoji indicators
   - System resources displayed at the top
   - Enter the number of your choice
   - Follow interactive prompts

3. **Direct script execution:**
   ```bash
   # Clone the repository
   git clone https://github.com/nooblk-98/linux-toolbox.git
   cd linux-toolbox/tools
   
   # Run any script directly
   sudo bash core-system/manage-users.sh
   sudo bash security/harden-ssh.sh
   sudo bash cicd/github-runner-advanced.sh install
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

**Made with ❤️ for the Linux DevOps community**

*Simplifying server administration, one script at a time*

**139+ Scripts | 12 Categories | Constantly Growing**

</div>
