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
read -p "Domain name (e.g., example.com): " domain

# Ask about www subdomain
echo ""
echo -e "${CYAN}Include www subdomain?${NC}"
echo "  1) Domain only (example.com)"
echo "  2) Domain + www (example.com and www.example.com)"
echo "  3) Subdomain only (app.example.com)"
echo "  4) Subdomain + www (app.example.com and www.app.example.com)"
read -p "Select option [1-4]: " domain_option

# Build server_name based on selection
case $domain_option in
    1)
        server_name="$domain"
        ssl_domains="-d $domain"
        ;;
    2)
        server_name="$domain www.$domain"
        ssl_domains="-d $domain -d www.$domain"
        ;;
    3)
        server_name="$domain"
        ssl_domains="-d $domain"
        ;;
    4)
        server_name="$domain www.$domain"
        ssl_domains="-d $domain -d www.$domain"
        ;;
    *)
        server_name="$domain"
        ssl_domains="-d $domain"
        echo -e "${YELLOW}Invalid option, using domain only${NC}"
        ;;
esac

echo ""
read -p "Backend server (e.g., localhost:3000 or 127.0.0.1:8080): " backend

# Normalize backend URL: allow inputs with or without scheme
if [[ "$backend" =~ ^https?:// ]]; then
    backend_url="$backend"
else
    backend_url="http://$backend"
fi

echo ""
echo -e "${CYAN}SSL/HTTPS Configuration:${NC}"
read -p "Enable SSL with Certbot? (y/n): " enable_ssl

install_certbot="n"
if [[ "$enable_ssl" =~ ^[Yy]$ ]]; then
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}Certbot is not installed.${NC}"
        read -p "Install Certbot now? (y/n): " install_certbot
    fi
fi

# Install Certbot if requested
if [[ "$install_certbot" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Installing Certbot...${NC}"
    
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    fi
    
    case $OS in
        ubuntu|debian)
            apt-get update
            apt-get install -y certbot python3-certbot-nginx
            ;;
        rhel|centos|rocky|almalinux|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y certbot python3-certbot-nginx
            else
                yum install -y certbot python3-certbot-nginx
            fi
            ;;
        *)
            echo -e "${RED}Unsupported OS for automatic Certbot installation${NC}"
            install_certbot="n"
            ;;
    esac
    
    if [[ "$install_certbot" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✓ Certbot installed successfully${NC}"
    fi
fi

# Create Nginx configuration (use .conf extension for broader compatibility)
config_file="/etc/nginx/sites-available/$domain.conf"

echo ""
echo -e "${CYAN}Creating Nginx configuration...${NC}"

cat > "$config_file" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $server_name;

    location / {
        proxy_pass $backend_url;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
}
EOF

# Enable the site
ln -sf "$config_file" "/etc/nginx/sites-enabled/$domain.conf"

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
        echo ""
        echo -e "${CYAN}Setting up SSL with Certbot...${NC}"
        echo -e "${YELLOW}Make sure your domain DNS is pointing to this server!${NC}"
        echo ""
        read -p "Proceed with SSL setup? (y/n): " proceed_ssl
        
        if [[ "$proceed_ssl" =~ ^[Yy]$ ]]; then
            # Get email for SSL certificate
            read -p "Enter email address for SSL certificate: " ssl_email
            
            # Run certbot
            certbot --nginx $ssl_domains --email "$ssl_email" --agree-tos --no-eff-email
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ SSL certificate installed successfully${NC}"
                
                # Setup auto-renewal
                if ! crontab -l 2>/dev/null | grep -q "certbot renew"; then
                    (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet") | crontab -
                    echo -e "${GREEN}✓ Auto-renewal configured${NC}"
                fi
            else
                echo -e "${RED}✗ SSL installation failed${NC}"
                echo -e "${YELLOW}You can manually setup SSL later with:${NC}"
                echo "  certbot --nginx $ssl_domains"
            fi
        else
            echo -e "${YELLOW}SSL setup skipped. You can run it later with:${NC}"
            echo "  certbot --nginx $ssl_domains"
        fi
    else
        echo -e "${YELLOW}Certbot not installed. To enable SSL later:${NC}"
        echo "  1. Install certbot: apt-get install certbot python3-certbot-nginx"
        echo "  2. Run: certbot --nginx $ssl_domains"
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Reverse Proxy Setup Complete!       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Configuration Details:${NC}"
echo -e "  Config file: ${GREEN}$config_file${NC}"
echo -e "  Domain(s): ${GREEN}$server_name${NC}"
echo -e "  Backend: ${GREEN}$backend_url${NC}"
echo -e "  SSL: ${GREEN}$([ "$enable_ssl" = "y" ] && echo "Enabled" || echo "Disabled")${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Ensure your backend service is running on $backend"
echo "  2. Point your domain DNS to this server's IP"
echo "  3. Test your site: http://$domain"
if [[ "$enable_ssl" =~ ^[Yy]$ ]] && command -v certbot &> /dev/null; then
    echo "  4. Access via HTTPS: https://$domain"
fi
echo ""

read -p "Press Enter to continue..."