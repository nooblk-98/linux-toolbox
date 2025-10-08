#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}PHP Installer${NC}"
echo "Select PHP version to install:"
echo "1. PHP 7.4"
echo "2. PHP 8.0"
echo "3. PHP 8.1"
echo "4. PHP 8.2"
echo "5. PHP 8.3"
read -p "Enter your choice [1-5]: " PHP_CHOICE

case "$PHP_CHOICE" in
    1) PHP_VER="7.4" ;;
    2) PHP_VER="8.0" ;;
    3) PHP_VER="8.1" ;;
    4) PHP_VER="8.2" ;;
    5) PHP_VER="8.3" ;;
    *)
        echo -e "${RED}Invalid selection.${NC}"
        exit 1
        ;;
esac

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PM="apt"
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
else
    echo -e "${RED}No supported package manager found.${NC}"
    exit 1
fi

echo -e "${GREEN}Installing PHP $PHP_VER...${NC}"

if [ "$PM" = "apt" ]; then
    sudo apt-get update
    sudo apt-get install -y software-properties-common
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt-get update
    sudo apt-get install -y php$PHP_VER php$PHP_VER-cli php$PHP_VER-fpm php$PHP_VER-mysql php$PHP_VER-xml php$PHP_VER-mbstring php$PHP_VER-curl php$PHP_VER-zip
elif [ "$PM" = "yum" ] || [ "$PM" = "dnf" ]; then
    sudo $PM install -y epel-release
    sudo $PM install -y https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E '%{rhel}').rpm
    sudo $PM install -y yum-utils
    sudo yum-config-manager --enable remi-php${PHP_VER//./}
    sudo $PM install -y php php-cli php-fpm php-mysqlnd php-xml php-mbstring php-curl php-zip
fi

echo -e "${GREEN}PHP $(php -v | head -n 1) installed.${NC}"
read -p "Press Enter to continue..."
