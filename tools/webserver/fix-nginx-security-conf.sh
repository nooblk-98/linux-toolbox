#!/bin/bash

# Fix Nginx security.conf configuration file
# This fixes the "if directive is not allowed here" error

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Fixing Nginx security.conf...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Backup existing file
if [ -f /etc/nginx/conf.d/security.conf ]; then
    cp /etc/nginx/conf.d/security.conf /etc/nginx/conf.d/security.conf.backup
    echo -e "${GREEN}✓ Backed up existing security.conf${NC}"
fi

# Create corrected security configuration
cat > /etc/nginx/conf.d/security.conf << 'EOF'
# Hide Nginx version
server_tokens off;

# Buffer overflow protection
client_body_buffer_size 1k;
client_header_buffer_size 1k;
client_max_body_size 10m;
large_client_header_buffers 2 1k;

# Timeouts
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 15;
send_timeout 10;
EOF

echo -e "${GREEN}✓ Created corrected security.conf${NC}"

# Test Nginx configuration
echo -e "${CYAN}Testing Nginx configuration...${NC}"
if nginx -t; then
    echo -e "${GREEN}✓ Configuration test passed${NC}"
    
    # Reload Nginx
    systemctl reload nginx
    echo -e "${GREEN}✓ Nginx reloaded successfully${NC}"
    
    echo ""
    echo -e "${GREEN}Fix applied successfully!${NC}"
    echo -e "${YELLOW}Note: Security headers are now included in individual server blocks${NC}"
else
    echo -e "${RED}✗ Configuration test failed${NC}"
    
    # Restore backup
    if [ -f /etc/nginx/conf.d/security.conf.backup ]; then
        mv /etc/nginx/conf.d/security.conf.backup /etc/nginx/conf.d/security.conf
        echo -e "${YELLOW}Restored backup${NC}"
    fi
    exit 1
fi
