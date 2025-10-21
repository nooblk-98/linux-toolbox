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
- ssl-install.sh - Install SSL certificates with Certbot
- ssl-renew.sh - Renew SSL certificates
- ssl-add-domain.sh - Add domains to SSL certificates
- reverse-proxy.sh - Configure reverse proxy
- ssl-auto-renew.sh - Toggle automatic SSL renewal

### database
- mariadb-phpmyadmin.sh - Install MariaDB 10 with phpMyAdmin

*Note: Empty folders like DOCKER_SCRIPTS, NODE_JS_SCRIPTS, PHP_SCRIPTS, INSTALL_DOCKER_APPS, WEB_SERVER_RELATED should be removed from the repository as they are no longer used.*

