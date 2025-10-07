#!/bin/bash
# filepath: d:\github\linux-toolbox\tools\certbot-add-domain.sh

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Install Certbot
install_certbot() {
    print_status "Installing Certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx python3-certbot-apache
}

# Obtain domains from user
read -p "Enter your domains (comma-separated): " DOMAINS_INPUT
IFS=',' read -r -a DOMAINS <<< "$DOMAINS_INPUT"

# Obtain email for Let's Encrypt notifications
read -p "Enter your email address: " EMAIL

# Auto-detect web server
if command -v nginx >/dev/null 2>&1; then
    SERVER="nginx"
elif command -v apache2 >/dev/null 2>&1; then
    SERVER="apache"
elif command -v httpd >/dev/null 2>&1; then
    SERVER="apache"
else
    print_error "No supported web server detected (nginx or apache/httpd)."
    exit 1
fi

echo -e "${GREEN}Detected web server: $SERVER${NC}"

# Install Certbot if not already installed
if ! command -v certbot &> /dev/null; then
    install_certbot
fi

# Run Certbot for all domains
if [ "$SERVER" = "nginx" ]; then
    sudo certbot --nginx $DOMAINS --email "$EMAIL" --agree-tos --redirect --non-interactive
elif [ "$SERVER" = "apache" ]; then
    sudo certbot --apache $DOMAINS --email "$EMAIL" --agree-tos --redirect --non-interactive
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}SSL certificate installed and configured for:$DOMAINS${NC}"
    # Ask for auto-renew setup
    read -p "Do you want to enable automatic certificate renewal? (y/n): " AUTORENEW
    if [[ "$AUTORENEW" =~ ^[Yy]$ ]]; then
        # Add cron job for certbot renew if not already present
        CRON_CMD="certbot renew --quiet"
        (crontab -l 2>/dev/null | grep -v "$CRON_CMD"; echo "0 3 * * * $CRON_CMD") | crontab -
        echo -e "${GREEN}Automatic renewal configured (daily at 3:00 AM).${NC}"
    fi
else
    echo -e "${RED}Certbot failed. Please check your web server and domain configuration.${NC}"
fi

read -p "Press Enter to continue..."