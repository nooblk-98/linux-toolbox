#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Web Server Configuration Checker & Fixer${NC}"
echo "=========================================="

# Detect web server
if command -v nginx >/dev/null 2>&1; then
    SERVER="nginx"
    CONFIG_DIR="/etc/nginx"
elif command -v apache2 >/dev/null 2>&1; then
    SERVER="apache"
    CONFIG_DIR="/etc/apache2"
elif command -v httpd >/dev/null 2>&1; then
    SERVER="apache"
    CONFIG_DIR="/etc/httpd"
else
    echo -e "${RED}No supported web server detected!${NC}"
    exit 1
fi

echo -e "${GREEN}Detected web server: $SERVER${NC}"

# Get available sites
if [ "$SERVER" = "nginx" ]; then
    sites_dir="$CONFIG_DIR/sites-available"
else
    sites_dir="$CONFIG_DIR/sites-available"
fi

# List available sites
echo -e "${YELLOW}Available sites:${NC}"
site_files=()
i=1
for file in "$sites_dir"/*; do
    if [ -f "$file" ] && [[ ! "$file" =~ \.(backup|bak|old)$ ]] && ! grep -q "#!/bin/bash" "$file" 2>/dev/null; then
        site_name=$(basename "$file" .conf)
        echo -e "${GREEN}$i.${NC} $site_name"
        site_files+=("$file")
        ((i++))
    fi
done

if [ ${#site_files[@]} -eq 0 ]; then
    echo -e "${RED}No valid site configurations found!${NC}"
    exit 1
fi

echo ""
read -p "Select site to check [1-${#site_files[@]}]: " choice

if [[ "$choice" -lt 1 || "$choice" -gt ${#site_files[@]} ]]; then
    echo -e "${RED}Invalid selection!${NC}"
    exit 1
fi

selected_site="${site_files[$((choice-1))]}"
site_name=$(basename "$selected_site" .conf)

echo -e "${YELLOW}Analyzing: $site_name${NC}"

# Backup original config
backup_file="${selected_site}.backup.$(date +%Y%m%d_%H%M%S)"
sudo cp "$selected_site" "$backup_file"

# Analysis results
issues=()
fixes=()

# Check for HTTP to HTTPS redirect
if [ "$SERVER" = "nginx" ]; then
    if ! grep -q "return 301 https" "$selected_site" && ! grep -q "rewrite.*https" "$selected_site"; then
        issues+=("Missing HTTP to HTTPS redirect")
        fixes+=("http_redirect")
    fi
    
    # Check for www redirect
    domains=$(grep -E "^\s*server_name" "$selected_site" | head -1 | sed 's/^\s*server_name\s*//g' | sed 's/;\s*$//g')
    if [[ "$domains" =~ www\. ]] && ! grep -q "return 301.*www" "$selected_site"; then
        issues+=("Missing non-www to www redirect")
        fixes+=("www_redirect")
    fi
    
    # Check SSL configuration
    if grep -q "ssl_certificate" "$selected_site"; then
        if ! grep -q "ssl_protocols" "$selected_site"; then
            issues+=("Missing SSL protocols configuration")
            fixes+=("ssl_protocols")
        fi
        if ! grep -q "ssl_ciphers" "$selected_site"; then
            issues+=("Missing SSL ciphers configuration")
            fixes+=("ssl_ciphers")
        fi
    fi
    
    # Check security headers
    if ! grep -q "add_header X-Frame-Options" "$selected_site"; then
        issues+=("Missing security headers")
        fixes+=("security_headers")
    fi
    
else
    # Apache checks
    if ! grep -q "RewriteRule.*https" "$selected_site" && ! grep -q "Redirect.*https" "$selected_site"; then
        issues+=("Missing HTTP to HTTPS redirect")
        fixes+=("http_redirect")
    fi
    
    if ! grep -q "SSLProtocol" "$selected_site" && grep -q "SSLEngine on" "$selected_site"; then
        issues+=("Missing SSL protocols configuration")
        fixes+=("ssl_protocols")
    fi
    
    if ! grep -q "Header always set" "$selected_site"; then
        issues+=("Missing security headers")
        fixes+=("security_headers")
    fi
fi

# Display results
echo ""
echo -e "${BLUE}Configuration Analysis Results:${NC}"
echo "==============================="

if [ ${#issues[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ No issues found! Configuration looks good.${NC}"
    read -p "Press Enter to continue..."
    exit 0
fi

for i in "${!issues[@]}"; do
    echo -e "${RED}✗${NC} ${issues[$i]}"
done

echo ""
echo -e "${YELLOW}Available fixes:${NC}"
for i in "${!fixes[@]}"; do
    echo -e "${GREEN}$((i+1)).${NC} Fix: ${issues[$i]}"
done
echo -e "${GREEN}$((${#fixes[@]}+1)).${NC} Fix all issues"
echo -e "${RED}0.${NC} Exit without fixing"

echo ""
read -p "Select fix to apply [0-$((${#fixes[@]}+1))]: " fix_choice

if [ "$fix_choice" = "0" ]; then
    echo -e "${YELLOW}No changes made.${NC}"
    exit 0
fi

# Apply fixes
apply_fix() {
    local fix_type=$1
    
    case $fix_type in
        "http_redirect")
            if [ "$SERVER" = "nginx" ]; then
                # Add HTTP redirect block
                if ! grep -q "listen 80" "$selected_site"; then
                    sudo sed -i '1i\
server {\
    listen 80;\
    server_name '"$(echo $domains)"';\
    return 301 https://$server_name$request_uri;\
}\
' "$selected_site"
                fi
            else
                # Apache redirect
                sudo sed -i '/DocumentRoot/a\
    RewriteEngine On\
    RewriteCond %{HTTPS} off\
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]' "$selected_site"
            fi
            echo -e "${GREEN}✓ Added HTTP to HTTPS redirect${NC}"
            ;;
            
        "www_redirect")
            if [ "$SERVER" = "nginx" ]; then
                # Add www redirect
                primary_domain=$(echo $domains | awk '{print $1}')
                if [[ "$primary_domain" =~ ^www\. ]]; then
                    non_www=${primary_domain#www.}
                    sudo sed -i "/server_name.*$primary_domain/i\
server {\
    listen 80;\
    listen 443 ssl http2;\
    server_name $non_www;\
    return 301 https://www.$non_www\$request_uri;\
}" "$selected_site"
                fi
            fi
            echo -e "${GREEN}✓ Added www redirect${NC}"
            ;;
            
        "ssl_protocols")
            if [ "$SERVER" = "nginx" ]; then
                sudo sed -i '/ssl_certificate_key/a\
    \
    # SSL Configuration\
    ssl_protocols TLSv1.2 TLSv1.3;\
    ssl_prefer_server_ciphers off;' "$selected_site"
            else
                sudo sed -i '/SSLEngine on/a\
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1\
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256' "$selected_site"
            fi
            echo -e "${GREEN}✓ Added SSL protocols configuration${NC}"
            ;;
            
        "ssl_ciphers")
            if [ "$SERVER" = "nginx" ]; then
                sudo sed -i '/ssl_protocols/a\
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;' "$selected_site"
            fi
            echo -e "${GREEN}✓ Added SSL ciphers configuration${NC}"
            ;;
            
        "security_headers")
            if [ "$SERVER" = "nginx" ]; then
                sudo sed -i '/ssl_prefer_server_ciphers/a\
    \
    # Security Headers\
    add_header X-Frame-Options "SAMEORIGIN" always;\
    add_header X-XSS-Protection "1; mode=block" always;\
    add_header X-Content-Type-Options "nosniff" always;\
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;' "$selected_site"
            else
                sudo sed -i '/SSLCipherSuite/a\
    \
    # Security Headers\
    Header always set X-Frame-Options "SAMEORIGIN"\
    Header always set X-XSS-Protection "1; mode=block"\
    Header always set X-Content-Type-Options "nosniff"\
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"' "$selected_site"
            fi
            echo -e "${GREEN}✓ Added security headers${NC}"
            ;;
    esac
}

if [ "$fix_choice" = "$((${#fixes[@]}+1))" ]; then
    # Fix all
    for fix in "${fixes[@]}"; do
        apply_fix "$fix"
    done
else
    # Fix specific issue
    apply_fix "${fixes[$((fix_choice-1))]}"
fi

# Test configuration
echo ""
echo -e "${YELLOW}Testing configuration...${NC}"
if [ "$SERVER" = "nginx" ]; then
    if sudo nginx -t; then
        echo -e "${GREEN}✓ Configuration test passed${NC}"
        read -p "Reload nginx to apply changes? (y/n): " reload
        if [[ "$reload" =~ ^[Yy]$ ]]; then
            sudo systemctl reload nginx
            echo -e "${GREEN}✓ Nginx reloaded${NC}"
        fi
    else
        echo -e "${RED}✗ Configuration test failed! Restoring backup...${NC}"
        sudo cp "$backup_file" "$selected_site"
    fi
else
    if sudo apache2ctl configtest 2>/dev/null || sudo httpd -t 2>/dev/null; then
        echo -e "${GREEN}✓ Configuration test passed${NC}"
        read -p "Reload apache to apply changes? (y/n): " reload
        if [[ "$reload" =~ ^[Yy]$ ]]; then
            sudo systemctl reload apache2 2>/dev/null || sudo systemctl reload httpd
            echo -e "${GREEN}✓ Apache reloaded${NC}"
        fi
    else
        echo -e "${RED}✗ Configuration test failed! Restoring backup...${NC}"
        sudo cp "$backup_file" "$selected_site"
    fi
fi

echo ""
echo -e "${BLUE}Configuration Fix Summary:${NC}"
echo "=========================="
echo -e "Site: ${GREEN}$site_name${NC}"
echo -e "Backup: ${GREEN}$backup_file${NC}"
echo -e "Status: ${GREEN}Fixed and Applied${NC}"

read -p "Press Enter to continue..."
