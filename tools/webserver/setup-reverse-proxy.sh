#!/bin/bash

# Nginx Reverse Proxy Setup Script
# Configure Nginx as a reverse proxy for applications

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Nginx Reverse Proxy Setup           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    exit 1
fi

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}Nginx is not installed. Installing...${NC}"
    apt-get update
    apt-get install -y nginx
fi

# Get configuration details
echo -e "${CYAN}Enter reverse proxy configuration:${NC}"
echo ""
read -p "Domain name (e.g., app.example.com): " domain
read -p "Backend server (e.g., localhost:3000 or 127.0.0.1:8080): " backend
read -p "Enable SSL/HTTPS? (y/n): " enable_ssl

# Create Nginx configuration
config_file="/etc/nginx/sites-available/$domain"

echo -e "${CYAN}Creating Nginx configuration...${NC}"

cat > "$config_file" <<EOF
server {
    listen 80;
    server_name $domain;

    location / {
        proxy_pass http://$backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable the site
ln -sf "$config_file" "/etc/nginx/sites-enabled/$domain"

# Test Nginx configuration
echo -e "${CYAN}Testing Nginx configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✓ Configuration is valid${NC}"
    
    # Reload Nginx
    systemctl reload nginx
    echo -e "${GREEN}✓ Nginx reloaded${NC}"
else
    echo -e "${RED}✗ Configuration error${NC}"
    exit 1
fi

# Setup SSL if requested
if [[ "$enable_ssl" =~ ^[Yy]$ ]]; then
    if command -v certbot &> /dev/null; then
        echo -e "${CYAN}Setting up SSL with Certbot...${NC}"
        certbot --nginx -d "$domain"
    else
        echo -e "${YELLOW}Certbot not installed. Install it to enable SSL:${NC}"
        echo "  apt-get install certbot python3-certbot-nginx"
        echo "  certbot --nginx -d $domain"
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Reverse Proxy Setup Complete!       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Configuration file: $config_file${NC}"
echo -e "${CYAN}Domain: $domain${NC}"
echo -e "${CYAN}Backend: $backend${NC}"

read -p "Press Enter to continue..."