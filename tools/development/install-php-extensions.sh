#!/bin/bash

# PHP Extensions Installation Script
# Install additional PHP extensions

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   PHP Extensions Installer             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    exit 1
fi

# Detect PHP version
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    echo -e "${GREEN}✓ Detected PHP $PHP_VERSION${NC}"
else
    echo -e "${RED}✗ PHP is not installed${NC}"
    exit 1
fi

# Extension categories
echo -e "${YELLOW}Select extension category:${NC}"
echo "1. Database extensions"
echo "2. Web development extensions"
echo "3. Image processing extensions"
echo "4. Performance extensions"
echo "5. All common extensions"
echo "6. Custom selection"
echo ""
read -p "Enter your choice (1-6): " category

case $category in
    1)
        EXTENSIONS="mysql pgsql sqlite3 mongodb redis"
        ;;
    2)
        EXTENSIONS="curl xml json mbstring zip"
        ;;
    3)
        EXTENSIONS="gd imagick"
        ;;
    4)
        EXTENSIONS="opcache apcu"
        ;;
    5)
        EXTENSIONS="mysql pgsql curl gd mbstring xml zip bcmath intl opcache redis"
        ;;
    6)
        echo -e "${CYAN}Available extensions:${NC}"
        echo "mysql, pgsql, sqlite3, mongodb, redis, curl, gd, imagick,"
        echo "mbstring, xml, zip, bcmath, intl, opcache, apcu, soap,"
        echo "ldap, imap, xdebug"
        echo ""
        read -p "Enter extensions (space-separated): " EXTENSIONS
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Install extensions
echo -e "${CYAN}Installing PHP extensions...${NC}"

if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    for ext in $EXTENSIONS; do
        echo -e "${YELLOW}Installing php${PHP_VERSION}-${ext}...${NC}"
        apt-get install -y php${PHP_VERSION}-${ext}
    done
elif command -v yum &> /dev/null; then
    # CentOS/RHEL
    for ext in $EXTENSIONS; do
        echo -e "${YELLOW}Installing php-${ext}...${NC}"
        yum install -y php-${ext}
    done
else
    echo -e "${RED}✗ Unsupported package manager${NC}"
    exit 1
fi

# Restart PHP-FPM
echo -e "${CYAN}Restarting PHP-FPM...${NC}"
systemctl restart php${PHP_VERSION}-fpm 2>/dev/null || systemctl restart php-fpm

# Show installed extensions
echo ""
echo -e "${GREEN}✓ Extensions installed${NC}"
echo -e "${CYAN}Loaded PHP extensions:${NC}"
php -m

echo ""
read -p "Press Enter to continue..."