#!/bin/bash

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Reverse Proxy Configuration Tool${NC}"
echo "===================================="

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

read -p "Enter your domain name (e.g., example.com): " DOMAIN
read -p "Enter backend service address (e.g., http://127.0.0.1:3000): " BACKEND

if [ "$SERVER" = "nginx" ]; then
    CONF_PATH="/etc/nginx/sites-available/$DOMAIN"
    echo -e "${YELLOW}Creating Nginx reverse proxy config at $CONF_PATH...${NC}"
    sudo tee "$CONF_PATH" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location / {
        proxy_pass $BACKEND;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
    sudo ln -sf "$CONF_PATH" /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
    echo -e "${GREEN}Nginx reverse proxy configured.${NC}"
elif [ "$SERVER" = "apache" ]; then
    CONF_PATH="/etc/apache2/sites-available/$DOMAIN.conf"
    echo -e "${YELLOW}Creating Apache reverse proxy config at $CONF_PATH...${NC}"
    sudo tee "$CONF_PATH" > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN

    ProxyPreserveHost On
    ProxyPass / $BACKEND/
    ProxyPassReverse / $BACKEND/

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOF
    sudo a2enmod proxy proxy_http
    sudo a2ensite "$DOMAIN"
    sudo apache2ctl configtest && sudo systemctl reload apache2
    echo -e "${GREEN}Apache reverse proxy configured.${NC}"
fi

read -p "Do you want to install HTTPS with Certbot for this domain? (y/n): " INSTALL_SSL
if [[ "$INSTALL_SSL" =~ ^[Yy]$ ]]; then
    if ! command -v certbot >/dev/null 2>&1; then
        echo -e "${YELLOW}Certbot not found, installing...${NC}"
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
    fi

    if [ "$SERVER" = "nginx" ]; then
        sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --agree-tos --redirect --non-interactive
    elif [ "$SERVER" = "apache" ]; then
        sudo certbot --apache -d "$DOMAIN" -d "www.$DOMAIN" --agree-tos --redirect --non-interactive
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSL certificate installed and configured for $DOMAIN.${NC}"
        read -p "Enable automatic certificate renewal? (y/n): " AUTORENEW
        if [[ "$AUTORENEW" =~ ^[Yy]$ ]]; then
            CRON_CMD="certbot renew --quiet"
            (crontab -l 2>/dev/null | grep -v "$CRON_CMD"; echo "0 3 * * * $CRON_CMD") | crontab -
            echo -e "${GREEN}Automatic renewal configured (daily at 3:00 AM).${NC}"
        fi
    else
        echo -e "${RED}Certbot failed. Please check your web server and domain configuration.${NC}"
    fi
fi

read -p "Press Enter to continue..."
