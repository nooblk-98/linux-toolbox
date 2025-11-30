#!/bin/bash

# PHP Installation Script
# Installs PHP with support for multiple versions

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   PHP Installation Script             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}✗ Cannot detect OS${NC}"
    exit 1
fi

# Select PHP version
echo -e "${YELLOW}Select PHP version to install:${NC}"
echo "1. PHP 8.3 (Latest)"
echo "2. PHP 8.2"
echo "3. PHP 8.1"
echo "4. PHP 8.0"
echo "5. PHP 7.4"
echo ""
read -p "Enter your choice (1-5): " version_choice

case $version_choice in
    1) PHP_VERSION="8.3" ;;
    2) PHP_VERSION="8.2" ;;
    3) PHP_VERSION="8.1" ;;
    4) PHP_VERSION="8.0" ;;
    5) PHP_VERSION="7.4" ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo -e "${CYAN}Installing PHP $PHP_VERSION...${NC}"

if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    # Add PHP repository
    apt-get update
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt-get update
    
    # Install PHP and common extensions
    apt-get install -y \
        php${PHP_VERSION} \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-opcache
    
elif [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "rocky" || "$OS" == "almalinux" ]]; then
    # Install EPEL and Remi repository
    yum install -y epel-release
    yum install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm
    
    # Enable PHP version
    yum-config-manager --enable remi-php${PHP_VERSION/./}
    
    # Install PHP
    yum install -y \
        php \
        php-cli \
        php-fpm \
        php-mysqlnd \
        php-pgsql \
        php-pdo \
        php-gd \
        php-mbstring \
        php-xml \
        php-zip \
        php-bcmath \
        php-intl \
        php-opcache
else
    echo -e "${RED}✗ Unsupported OS: $OS${NC}"
    exit 1
fi

# Start and enable PHP-FPM
echo -e "${CYAN}Starting PHP-FPM...${NC}"
systemctl enable php${PHP_VERSION}-fpm
systemctl start php${PHP_VERSION}-fpm

# Verify installation
echo ""
echo -e "${CYAN}Verifying installation...${NC}"
php -v

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ PHP $PHP_VERSION installed successfully${NC}"
    echo -e "${CYAN}PHP-FPM status:${NC}"
    systemctl status php${PHP_VERSION}-fpm --no-pager
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Installation Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

read -p "Press Enter to continue..."