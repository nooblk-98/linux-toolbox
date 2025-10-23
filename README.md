# linux-toolbox

## Quick Start

Run the toolbox directly (always latest version):

```bash
bash <(curl -sSL "https://raw.githubusercontent.com/nooblk-98/linux-toolbox/main/run.sh?$(date +%s)")
```

Or with wget:

```bash
bash <(wget -qO- "https://raw.githubusercontent.com/nooblk-98/linux-toolbox/main/run.sh?$(date +%s)")
```

## Force Fresh Download & Run

Remove any cached version and run latest:

```bash
rm -f run.sh && curl -sSL "https://raw.githubusercontent.com/nooblk-98/linux-toolbox/main/run.sh" -o run.sh && chmod +x run.sh && ./run.sh
```

Or one-liner without local file:

```bash
rm -f run.sh; bash <(curl -sSL "https://raw.githubusercontent.com/nooblk-98/linux-toolbox/main/run.sh")
```

## Tools List

### system
- timezone.sh - Configure system timezone
- auto-reboot.sh - Schedule automatic reboots
- firewall-manager.sh - UFW firewall management
- ssh-hardening.sh - SSH security configuration
- fail2ban-setup.sh - Install and configure Fail2ban
- user-manager.sh - User account management
- backup-manager.sh - Backup automation tool

### network
- bandwidth-test.sh - Network speed testing
- port-scanner.sh - Simple port scanner
- network-info.sh - Network configuration display

### development
- git-setup.sh - Git configuration and SSH keys
- python-env.sh - Python virtual environment manager
- pm2-manager.sh - PM2 process manager for Node.js

### docker
- install.sh - Install Docker and Docker Compose
- cleanup.sh - Remove unused containers, images, volumes
- remove-container.sh - Interactive container removal

### nodejs
- install.sh - Install Node.js and npm (version selection)

### php
- install.sh - Install PHP (version selection)
- extensions.sh - Install PHP extensions

### webserver
- certbot-install.sh - Install Certbot and plugins
- certbot-obtain.sh - Obtain and apply SSL certificates
- certbot-renew.sh - Renew SSL certificates (multiple methods)
- certbot-add-domain.sh - Add domains to existing certificates
- certbot-auto-renew.sh - Toggle automatic SSL renewal
- migrate-to-certbot.sh - Migrate existing SSL to Certbot management
- reverse-proxy.sh - Configure reverse proxy
- wordpress-backup.sh - WordPress site backup with database dump

### database
- mariadb-phpmyadmin.sh - Install MariaDB 10 with phpMyAdmin
- mysql-install.sh - Install MySQL server

### monitoring
- server-health.sh - Complete server health check

*Note: Empty folders like DOCKER_SCRIPTS, NODE_JS_SCRIPTS, PHP_SCRIPTS, INSTALL_DOCKER_APPS, WEB_SERVER_RELATED should be removed from the repository as they are no longer used.*

