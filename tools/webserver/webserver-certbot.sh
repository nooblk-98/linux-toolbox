#!/bin/bash

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Certbot SSL Installer${NC}"
echo "=============================="

# Detect web server
if command -v nginx >/dev/null 2>&1; then
    SERVER="nginx"
elif command -v apache2 >/dev/null 2>&1; then
    SERVER="apache"
elif command -v httpd >/dev/null 2>&1; then
    SERVER="apache"
else
    echo -e "${RED}No supported web server detected (nginx or apache/httpd).${NC}"
    exit 1
fi

echo -e "${GREEN}Detected web server: $SERVER${NC}"

# Install Certbot and plugin
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y certbot
    if [ "$SERVER" = "nginx" ]; then
        sudo apt-get install -y python3-certbot-nginx
    else
        sudo apt-get install -y python3-certbot-apache
    fi
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y epel-release
    sudo yum install -y certbot
    if [ "$SERVER" = "nginx" ]; then
        sudo yum install -y certbot-nginx
    else
        sudo yum install -y certbot-apache
    fi
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y certbot
    if [ "$SERVER" = "nginx" ]; then
        sudo dnf install -y python3-certbot-nginx
    else
        sudo dnf install -y python3-certbot-apache
    fi
else
    echo -e "${RED}No supported package manager found.${NC}"
    exit 1
fi

echo -e "${GREEN}Certbot and plugin installed.${NC}"

# Prompt for domain and email
read -p "Enter your domain name (e.g., example.com): " DOMAIN
read -p "Enter your email for Let's Encrypt notifications: " EMAIL

# Run Certbot
if [ "$SERVER" = "nginx" ]; then
    sudo certbot --nginx -d "$DOMAIN" --email "$EMAIL" --agree-tos --redirect --non-interactive
elif [ "$SERVER" = "apache" ]; then
    sudo certbot --apache -d "$DOMAIN" --email "$EMAIL" --agree-tos --redirect --non-interactive
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}SSL certificate installed and configured!${NC}"
else
    echo -e "${RED}Certbot failed. Please check your web server and domain configuration.${NC}"
fi

read -p "Press Enter to continue..."
