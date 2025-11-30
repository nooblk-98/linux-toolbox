#!/bin/bash

# MariaDB 10 + phpMyAdmin Installation Script
# Installs MariaDB database server and phpMyAdmin web interface

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   MariaDB 10 + phpMyAdmin Installer   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    exit 1
fi

# Install MariaDB
echo -e "${CYAN}Installing MariaDB 10...${NC}"

if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    apt-get update
    apt-get install -y mariadb-server mariadb-client
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    yum install -y mariadb-server mariadb
else
    echo -e "${RED}✗ Unsupported package manager${NC}"
    exit 1
fi

# Start and enable MariaDB
echo -e "${CYAN}Starting MariaDB service...${NC}"
systemctl enable mariadb
systemctl start mariadb

# Secure MariaDB installation
echo -e "${CYAN}Securing MariaDB installation...${NC}"
echo ""
read -p "Set MariaDB root password: " -s MYSQL_ROOT_PASSWORD
echo ""

mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User='';"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DROP DATABASE IF EXISTS test;"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"

echo -e "${GREEN}✓ MariaDB secured${NC}"

# Install phpMyAdmin
echo ""
read -p "Install phpMyAdmin? (y/n): " install_pma

if [[ "$install_pma" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Installing phpMyAdmin...${NC}"
    
    if command -v apt-get &> /dev/null; then
        # Install dependencies
        apt-get install -y php php-mbstring php-zip php-gd php-json php-curl php-mysql
        
        # Download phpMyAdmin
        PMA_VERSION="5.2.1"
        cd /tmp
        wget https://files.phpmyadmin.net/phpMyAdmin/${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz
        tar xzf phpMyAdmin-${PMA_VERSION}-all-languages.tar.gz
        mv phpMyAdmin-${PMA_VERSION}-all-languages /usr/share/phpmyadmin
        
        # Create config
        mkdir -p /usr/share/phpmyadmin/tmp
        chmod 777 /usr/share/phpmyadmin/tmp
        cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php
        
        # Generate blowfish secret
        BLOWFISH=$(openssl rand -base64 32)
        sed -i "s/\$cfg\['blowfish_secret'\] = ''/\$cfg\['blowfish_secret'\] = '${BLOWFISH}'/" /usr/share/phpmyadmin/config.inc.php
        
        # Create Nginx config
        if command -v nginx &> /dev/null; then
            cat > /etc/nginx/sites-available/phpmyadmin <<EOF
server {
    listen 8080;
    server_name _;
    root /usr/share/phpmyadmin;
    index index.php;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
}
EOF
            ln -sf /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/
            systemctl reload nginx
            echo -e "${GREEN}✓ phpMyAdmin available at http://your-server:8080${NC}"
        fi
        
        echo -e "${GREEN}✓ phpMyAdmin installed${NC}"
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Installation Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}MariaDB root password: [saved]${NC}"
echo -e "${CYAN}Connect: mysql -u root -p${NC}"

if [[ "$install_pma" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}phpMyAdmin: http://your-server:8080${NC}"
fi

read -p "Press Enter to continue..."