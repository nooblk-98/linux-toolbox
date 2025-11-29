#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Certbot Add Domain Tool${NC}"
echo "=============================="

# Auto-detect web server
if command -v nginx >/dev/null 2>&1; then
    SERVER="nginx"
elif command -v apache2 >/dev/null 2>&1; then
    SERVER="apache"
elif command -v httpd >/dev/null 2>&1; then
    SERVER="apache"
else
    echo -e "${RED}No supported web server detected.${NC}"
    exit 1
fi

echo -e "${GREEN}Detected web server: $SERVER${NC}"

# Get domains to add
read -p "Enter domains to add (comma-separated): " DOMAINS_INPUT
IFS=',' read -r -a DOMAINS <<< "$DOMAINS_INPUT"

# Get email
read -p "Enter your email address: " EMAIL

# Build domain arguments
domain_args=""
for domain in "${DOMAINS[@]}"; do
    domain=$(echo "$domain" | xargs) # trim
    if [ -n "$domain" ]; then
        domain_args="$domain_args -d $domain"
    fi
done

# Run Certbot
if [ "$SERVER" = "nginx" ]; then
    sudo certbot --nginx $domain_args --email "$EMAIL" --agree-tos --redirect --non-interactive
elif [ "$SERVER" = "apache" ]; then
    sudo certbot --apache $domain_args --email "$EMAIL" --agree-tos --redirect --non-interactive
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}SSL certificate updated with new domains!${NC}"
    
    # Ask for auto-renew setup
    read -p "Enable automatic certificate renewal? (y/n): " AUTORENEW
    if [[ "$AUTORENEW" =~ ^[Yy]$ ]]; then
        CRON_CMD="certbot renew --quiet"
        (crontab -l 2>/dev/null | grep -v "$CRON_CMD"; echo "0 3 * * * $CRON_CMD") | crontab -
        echo -e "${GREEN}Automatic renewal configured.${NC}"
    fi
else
    echo -e "${RED}Failed to add domains to certificate.${NC}"
fi

read -p "Press Enter to continue..."
