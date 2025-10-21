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

### SYSTEM
- timezone.sh
- auto-reboot.sh

### DOCKER_SCRIPTS  
- docker-cleanup.sh
- docker-remove-container.sh

### NODE_JS_SCRIPTS
- nodejs-install.sh

### PHP_SCRIPTS
- php-install.sh
- php-extension-install.sh

### INSTALL_DOCKER_APPS
- install-mariadb10-phpmyadmin.sh

### WEB_SERVER_RELATED
- webserver-certbot.sh
- certbot-renew.sh
- certbot-add-domain.sh
- add-reverse-proxy.sh
- certbot-auto-renew-toggle.sh

