#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Certbot Renewal Tool${NC}"
echo "=============================="
echo -e "${YELLOW}Select a renewal method:${NC}"
echo ""
echo "1. Standard renewal"
if command -v nginx >/dev/null 2>&1; then
    echo "2. Nginx plugin renewal"
fi
if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
    echo "3. Apache plugin renewal"
fi
echo "4. Standalone mode (stops web server temporarily)"
echo "5. Webroot mode"
echo ""
read -p "Enter your choice: " method_choice

case $method_choice in
    1)
        echo -e "${BLUE}Standard renewal${NC}"
        sudo certbot renew
        ;;
    2)
        if command -v nginx >/dev/null 2>&1; then
            echo -e "${BLUE}Nginx plugin renewal${NC}"
            sudo certbot renew --nginx
        else
            echo -e "${RED}Nginx not found!${NC}"
        fi
        ;;
    3)
        if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
            echo -e "${BLUE}Apache plugin renewal${NC}"
            sudo certbot renew --apache
        else
            echo -e "${RED}Apache not found!${NC}"
        fi
        ;;
    4)
        echo -e "${BLUE}Standalone mode${NC}"
        echo -e "${YELLOW}Stopping web servers...${NC}"
        sudo systemctl stop nginx apache2 httpd 2>/dev/null
        sudo certbot renew --standalone
        echo -e "${YELLOW}Starting web servers...${NC}"
        sudo systemctl start nginx apache2 httpd 2>/dev/null
        ;;
    5)
        read -p "Enter your webroot path (e.g., /var/www/html): " WEBROOT
        echo -e "${BLUE}Webroot mode${NC}"
        sudo certbot renew --webroot -w "$WEBROOT"
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}Renewal completed.${NC}"
read -p "Press Enter to continue..."
