#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Certbot Installer${NC}"
echo -e "${YELLOW}Detecting system and web server...${NC}"

# Detect package manager
PM=""
if command -v apt-get >/dev/null 2>&1; then
    PM="apt"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
fi

# Detect web server
HAS_NGINX=0
HAS_APACHE=0
if command -v nginx >/dev/null 2>&1; then HAS_NGINX=1; fi
if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then HAS_APACHE=1; fi

echo -e "${GREEN}Package manager:${NC} ${PM:-unknown}"
[[ $HAS_NGINX -eq 1 ]] && echo -e "${GREEN}Detected: nginx${NC}"
[[ $HAS_APACHE -eq 1 ]] && echo -e "${GREEN}Detected: apache${NC}"

# Install Certbot via snap (recommended method)
if command -v certbot >/dev/null 2>&1; then
    echo -e "${GREEN}Certbot already installed: $(certbot --version 2>/dev/null)${NC}"
else
    echo -e "${YELLOW}Installing Certbot via snap...${NC}"
    
    # Install snapd if missing
    if ! command -v snap >/dev/null 2>&1; then
        case "$PM" in
            apt)
                sudo apt-get update && sudo apt-get install -y snapd
                ;;
            dnf|yum)
                sudo "$PM" install -y snapd
                ;;
            *)
                echo -e "${RED}No known package manager to install snapd.${NC}"
                exit 1
                ;;
        esac
    fi
    
    sudo systemctl enable --now snapd.socket
    sudo snap install core; sudo snap refresh core
    sudo snap install --classic certbot
    sudo ln -sf /snap/bin/certbot /usr/local/bin/certbot
fi

# Install web server plugins if needed
if [ "$HAS_NGINX" -eq 1 ]; then
    echo -e "${YELLOW}Installing certbot nginx plugin...${NC}"
    if [ "$PM" = "apt" ]; then
        sudo apt-get install -y python3-certbot-nginx || true
    elif [ "$PM" = "dnf" ] || [ "$PM" = "yum" ]; then
        sudo "$PM" install -y python3-certbot-nginx || true
    fi
fi

if [ "$HAS_APACHE" -eq 1 ]; then
    echo -e "${YELLOW}Installing certbot apache plugin...${NC}"
    if [ "$PM" = "apt" ]; then
        sudo apt-get install -y python3-certbot-apache || true
    elif [ "$PM" = "dnf" ] || [ "$PM" = "yum" ]; then
        sudo "$PM" install -y python3-certbot-apache || true
    fi
fi

echo -e "${GREEN}Certbot installation completed!${NC}"
read -p "Press Enter to continue..."
