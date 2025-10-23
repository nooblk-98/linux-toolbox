#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}SSL Certificate Obtain & Apply Tool${NC}"
echo "===================================="

# Check if certbot is installed
if ! command -v certbot >/dev/null 2>&1; then
    echo -e "${RED}Error: Certbot not found! Please install certbot first.${NC}"
    exit 1
fi

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

# Get domains
read -p "Enter your primary domain (e.g., example.com): " primary_domain
read -p "Add www subdomain? (y/n): " add_www

domains="-d $primary_domain"
if [[ "$add_www" =~ ^[Yy]$ ]]; then
    domains="$domains -d www.$primary_domain"
fi

read -p "Add additional domains? (comma separated, e.g., api.example.com,blog.example.com): " additional_domains
if [ -n "$additional_domains" ]; then
    IFS=',' read -ra DOMAIN_ARRAY <<< "$additional_domains"
    for domain in "${DOMAIN_ARRAY[@]}"; do
        domain=$(echo "$domain" | xargs) # trim whitespace
        if [ -n "$domain" ]; then
            domains="$domains -d $domain"
        fi
    done
fi

echo -e "${GREEN}Domains to certificate:${NC} $domains"

# Get email
read -p "Enter your email for Let's Encrypt notifications: " email

# Choose certificate method
echo ""
echo -e "${YELLOW}Certificate obtainment methods:${NC}"
echo "1. Webroot (recommended for existing sites)"
echo "2. Standalone (stops web server temporarily)"
echo "3. Web server plugin (nginx/apache)"
echo ""
read -p "Select method [1-3]: " method_choice

case $method_choice in
    1)
        # Webroot method
        if [ "$SERVER" = "nginx" ]; then
            default_webroot="/var/www/html"
        else
            default_webroot="/var/www/html"
        fi
        read -p "Enter webroot path (default: $default_webroot): " webroot_path
        webroot_path=${webroot_path:-$default_webroot}
        
        if [ ! -d "$webroot_path" ]; then
            echo -e "${YELLOW}Creating webroot directory: $webroot_path${NC}"
            sudo mkdir -p "$webroot_path"
        fi
        
        certbot_cmd="certbot certonly --webroot -w $webroot_path $domains --email $email --agree-tos --non-interactive"
        ;;
    2)
        # Standalone method
        echo -e "${YELLOW}This will temporarily stop your web server${NC}"
        read -p "Continue? (y/n): " confirm_standalone
        if [[ ! "$confirm_standalone" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Operation cancelled${NC}"
            exit 0
        fi
        
        echo -e "${YELLOW}Stopping web server...${NC}"
        sudo systemctl stop $SERVER
        
        certbot_cmd="certbot certonly --standalone $domains --email $email --agree-tos --non-interactive"
        ;;
    3)
        # Web server plugin method
        if [ "$SERVER" = "nginx" ]; then
            certbot_cmd="certbot --nginx $domains --email $email --agree-tos --redirect --non-interactive"
        else
            certbot_cmd="certbot --apache $domains --email $email --agree-tos --redirect --non-interactive"
        fi
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

# Run certbot
echo -e "${YELLOW}Obtaining SSL certificate...${NC}"
echo "Running: $certbot_cmd"
sudo $certbot_cmd

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSL certificate obtained successfully!${NC}"
    
    # If method 3 (plugin), configuration is already applied
    if [ "$method_choice" = "3" ]; then
        echo -e "${GREEN}✓ SSL configuration applied automatically${NC}"
    else
        # For methods 1 and 2, we need to configure the web server
        echo -e "${YELLOW}Configuring web server...${NC}"
        
        cert_path="/etc/letsencrypt/live/$primary_domain/fullchain.pem"
        key_path="/etc/letsencrypt/live/$primary_domain/privkey.pem"
        
        if [ "$SERVER" = "nginx" ]; then
            # Create or update nginx configuration
            config_file="/etc/nginx/sites-available/$primary_domain"
            
            cat <<EOF | sudo tee "$config_file" > /dev/null
server {
    listen 80;
    server_name $primary_domain$([ "$add_www" = "y" ] && echo " www.$primary_domain");
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $primary_domain$([ "$add_www" = "y" ] && echo " www.$primary_domain");
    
    ssl_certificate $cert_path;
    ssl_certificate_key $key_path;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    root /var/www/html;
    index index.html index.htm index.php;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
}
EOF
            
            # Enable site
            sudo ln -sf "$config_file" "/etc/nginx/sites-enabled/"
            
        else
            # Apache configuration
            config_file="/etc/apache2/sites-available/$primary_domain-ssl.conf"
            
            cat <<EOF | sudo tee "$config_file" > /dev/null
<VirtualHost *:443>
    ServerName $primary_domain
    $([ "$add_www" = "y" ] && echo "ServerAlias www.$primary_domain")
    
    DocumentRoot /var/www/html
    
    SSLEngine on
    SSLCertificateFile $cert_path
    SSLCertificateKeyFile $key_path
    
    # Redirect HTTP to HTTPS
    <IfModule mod_rewrite.c>
        RewriteEngine On
        RewriteCond %{HTTPS} off
        RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
    </IfModule>
</VirtualHost>

<VirtualHost *:80>
    ServerName $primary_domain
    $([ "$add_www" = "y" ] && echo "ServerAlias www.$primary_domain")
    
    RewriteEngine On
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>
EOF
            
            # Enable site and SSL module
            sudo a2enmod ssl
            sudo a2ensite "$primary_domain-ssl"
        fi
        
        # Test and reload web server
        if [ "$SERVER" = "nginx" ]; then
            sudo nginx -t && sudo systemctl reload nginx
        else
            sudo apache2ctl configtest && sudo systemctl reload apache2
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Web server configured successfully${NC}"
        else
            echo -e "${RED}✗ Web server configuration failed${NC}"
        fi
    fi
    
    # Restart web server if it was stopped
    if [ "$method_choice" = "2" ]; then
        echo -e "${YELLOW}Starting web server...${NC}"
        sudo systemctl start $SERVER
    fi
    
    # Setup auto-renewal
    read -p "Setup automatic certificate renewal? (y/n): " setup_renewal
    if [[ "$setup_renewal" =~ ^[Yy]$ ]]; then
        CRON_CMD="certbot renew --quiet"
        if ! crontab -l 2>/dev/null | grep -q "$CRON_CMD"; then
            (crontab -l 2>/dev/null; echo "0 3 * * * $CRON_CMD") | crontab -
            echo -e "${GREEN}✓ Auto-renewal configured (daily at 3:00 AM)${NC}"
        else
            echo -e "${YELLOW}Auto-renewal already configured${NC}"
        fi
    fi
    
    # Show certificate info
    echo ""
    echo -e "${BLUE}SSL Certificate Summary:${NC}"
    echo "================================"
    echo -e "Primary Domain: ${GREEN}$primary_domain${NC}"
    echo -e "All Domains: ${GREEN}$(echo $domains | sed 's/-d //g')${NC}"
    echo -e "Certificate Path: ${GREEN}$cert_path${NC}"
    echo -e "Key Path: ${GREEN}$key_path${NC}"
    echo -e "Expires: ${GREEN}$(sudo openssl x509 -in $cert_path -noout -enddate | cut -d= -f2)${NC}"
    echo -e "Status: ${GREEN}Active and Applied${NC}"
    
else
    echo -e "${RED}✗ Failed to obtain SSL certificate${NC}"
    
    # Restart web server if it was stopped
    if [ "$method_choice" = "2" ]; then
        echo -e "${YELLOW}Starting web server...${NC}"
        sudo systemctl start $SERVER
    fi
fi

read -p "Press Enter to continue..."
