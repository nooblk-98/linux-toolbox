#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Migrate to Certbot SSL Management${NC}"
echo "=================================="

# Check if nginx is installed
if ! command -v nginx >/dev/null 2>&1; then
    echo -e "${RED}Error: Nginx not found!${NC}"
    exit 1
fi

# Check if certbot is installed
if ! command -v certbot >/dev/null 2>&1; then
    echo -e "${RED}Error: Certbot not found! Please install certbot first.${NC}"
    exit 1
fi

# List available nginx sites
echo -e "${YELLOW}Available nginx sites:${NC}"
sites_available="/etc/nginx/sites-available"
sites_enabled="/etc/nginx/sites-enabled"

if [ ! -d "$sites_available" ]; then
    sites_available="/etc/nginx/conf.d"
    sites_enabled="/etc/nginx/conf.d"
fi

site_files=($(find "$sites_available" -name "*.conf" -o -name "*" ! -name "default*" 2>/dev/null | grep -v "default"))
if [ ${#site_files[@]} -eq 0 ]; then
    echo -e "${RED}No nginx site configurations found!${NC}"
    exit 1
fi

echo ""
for i in "${!site_files[@]}"; do
    site_name=$(basename "${site_files[$i]}" .conf)
    echo -e "${GREEN}$((i+1)).${NC} $site_name (${site_files[$i]})"
done

echo ""
read -p "Select site to migrate [1-${#site_files[@]}]: " choice

if [[ "$choice" -lt 1 || "$choice" -gt ${#site_files[@]} ]]; then
    echo -e "${RED}Invalid selection!${NC}"
    exit 1
fi

selected_site="${site_files[$((choice-1))]}"
site_name=$(basename "$selected_site" .conf)

echo -e "${YELLOW}Analyzing site: $site_name${NC}"

# Extract domain names from nginx config
domains=$(grep -E "server_name" "$selected_site" | grep -v "#" | sed 's/server_name//g' | sed 's/;//g' | xargs)
if [ -z "$domains" ]; then
    read -p "Could not detect domains. Enter domains (space separated): " domains
fi

echo -e "${GREEN}Detected domains:${NC} $domains"

# Backup original config
backup_file="${selected_site}.backup.$(date +%Y%m%d_%H%M%S)"
sudo cp "$selected_site" "$backup_file"
echo -e "${GREEN}✓ Config backed up to: $backup_file${NC}"

# Check if site has SSL already
if grep -q "ssl_certificate" "$selected_site"; then
    echo -e "${YELLOW}Site already has SSL configuration${NC}"
    
    # Show current SSL certificate info
    cert_path=$(grep "ssl_certificate " "$selected_site" | head -1 | awk '{print $2}' | sed 's/;//')
    if [ -f "$cert_path" ]; then
        echo -e "${BLUE}Current certificate info:${NC}"
        openssl x509 -in "$cert_path" -text -noout | grep -E "(Subject:|Issuer:|Not After)" 2>/dev/null || echo "Could not read certificate"
    fi
    
    read -p "Replace current SSL with Certbot? (y/n): " replace_ssl
    if [[ ! "$replace_ssl" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Migration cancelled${NC}"
        exit 0
    fi
    
    # Remove existing SSL configuration
    echo -e "${YELLOW}Removing existing SSL configuration...${NC}"
    sudo sed -i '/ssl_/d' "$selected_site"
    sudo sed -i '/listen 443/d' "$selected_site"
    
    # Ensure port 80 listener exists
    if ! grep -q "listen 80" "$selected_site"; then
        sudo sed -i '/listen /a\    listen 80;' "$selected_site"
    fi
fi

# Test nginx config
sudo nginx -t
if [ $? -ne 0 ]; then
    echo -e "${RED}Nginx config test failed! Restoring backup...${NC}"
    sudo cp "$backup_file" "$selected_site"
    exit 1
fi

# Reload nginx
sudo systemctl reload nginx

# Get email for certbot
read -p "Enter email for Let's Encrypt notifications: " email

# Run certbot
echo -e "${YELLOW}Running Certbot to obtain and configure SSL...${NC}"
domain_args=""
for domain in $domains; do
    if [ "$domain" != "_" ] && [ "$domain" != "default_server" ]; then
        domain_args="$domain_args -d $domain"
    fi
done

if [ -z "$domain_args" ]; then
    echo -e "${RED}No valid domains found for certificate!${NC}"
    exit 1
fi

echo "Running: certbot --nginx $domain_args --email $email --agree-tos --redirect --non-interactive"
sudo certbot --nginx $domain_args --email $email --agree-tos --redirect --non-interactive

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Successfully migrated to Certbot SSL!${NC}"
    
    # Show certificate info
    echo -e "${BLUE}New certificate info:${NC}"
    first_domain=$(echo $domains | awk '{print $1}')
    certbot certificates -d "$first_domain" 2>/dev/null || echo "Certificate installed successfully"
    
    # Setup auto-renewal if not already configured
    if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
        read -p "Setup automatic certificate renewal? (y/n): " setup_auto
        if [[ "$setup_auto" =~ ^[Yy]$ ]]; then
            (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet") | crontab -
            echo -e "${GREEN}✓ Auto-renewal configured (daily at 3:00 AM)${NC}"
        fi
    fi
    
    echo ""
    echo -e "${BLUE}Migration Summary:${NC}"
    echo "================================"
    echo -e "Site: ${GREEN}$site_name${NC}"
    echo -e "Domains: ${GREEN}$domains${NC}"
    echo -e "Config: ${GREEN}$selected_site${NC}"
    echo -e "Backup: ${GREEN}$backup_file${NC}"
    echo -e "Status: ${GREEN}SSL managed by Certbot${NC}"
else
    echo -e "${RED}✗ Certbot failed! Restoring original config...${NC}"
    sudo cp "$backup_file" "$selected_site"
    sudo systemctl reload nginx
    echo -e "${YELLOW}Original configuration restored${NC}"
fi

read -p "Press Enter to continue..."
