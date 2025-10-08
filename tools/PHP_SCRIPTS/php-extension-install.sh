#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}PHP Extension Installer${NC}"
read -p "Enter your PHP version (e.g., 7.4, 8.0, 8.1, 8.2, 8.3): " PHP_VER
echo "Enter required extensions separated by spaces (e.g., mbstring curl zip xml gd intl mysqli pdo):"
read -p "Extensions: " EXT_LIST

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

echo -e "${GREEN}Installing PHP extensions for PHP $PHP_VER...${NC}"

if [ "$PM" = "apt" ]; then
    for ext in $EXT_LIST; do
        sudo apt-get install -y php${PHP_VER}-$ext
    done
elif [ "$PM" = "yum" ] || [ "$PM" = "dnf" ]; then
    for ext in $EXT_LIST; do
        sudo $PM install -y php-$ext
    done
fi

echo -e "${GREEN}Installed extensions:${NC}"
php -m | grep -E "$(echo $EXT_LIST | sed 's/ /|/g')"

read -p "Press Enter to continue..."
