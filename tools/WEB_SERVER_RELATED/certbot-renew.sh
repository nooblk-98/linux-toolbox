#!/bin/bash

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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
echo "6. Try all methods"
echo ""
read -p "Enter your choice: " method_choice

case $method_choice in
    1)
        echo -e "${BLUE}Standard renewal: certbot renew${NC}"
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
        sudo systemctl stop nginx 2>/dev/null
        sudo systemctl stop apache2 2>/dev/null
        sudo systemctl stop httpd 2>/dev/null
        sudo certbot renew --standalone
        echo -e "${YELLOW}Starting web servers...${NC}"
        sudo systemctl start nginx 2>/dev/null
        sudo systemctl start apache2 2>/dev/null
        sudo systemctl start httpd 2>/dev/null
        ;;
    5)
        read -p "Enter your webroot path (e.g., /var/www/html): " WEBROOT
        echo -e "${BLUE}Webroot mode${NC}"
        sudo certbot renew --webroot -w "$WEBROOT"
        ;;
    6)
        # 1. Standard renewal
        echo -e "${BLUE}1. Standard: certbot renew${NC}"
        sudo certbot renew
        echo ""

        # 2. Renew with nginx plugin
        if command -v nginx >/dev/null 2>&1; then
            echo -e "${BLUE}2. Nginx plugin: certbot --nginx renew${NC}"
            sudo certbot renew --nginx
            echo ""
        fi

        # 3. Renew with apache plugin
        if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
            echo -e "${BLUE}3. Apache plugin: certbot --apache renew${NC}"
            sudo certbot renew --apache
            echo ""
        fi

        # 4. Renew with standalone mode (requires stopping web server)
        echo -e "${BLUE}4. Standalone mode: certbot renew --standalone${NC}"
        echo -e "${YELLOW}Standalone mode requires stopping your web server temporarily.${NC}"
        read -p "Do you want to try standalone mode? (y/n): " standalone_choice
        if [[ "$standalone_choice" =~ ^[Yy]$ ]]; then
            sudo systemctl stop nginx 2>/dev/null
            sudo systemctl stop apache2 2>/dev/null
            sudo systemctl stop httpd 2>/dev/null
            sudo certbot renew --standalone
            sudo systemctl start nginx 2>/dev/null
            sudo systemctl start apache2 2>/dev/null
            sudo systemctl start httpd 2>/dev/null
            echo ""
        fi

        # 5. Renew with webroot mode (requires webroot path)
        echo -e "${BLUE}5. Webroot mode: certbot renew --webroot -w /path/to/webroot${NC}"
        read -p "Do you want to try webroot mode? (y/n): " webroot_choice
        if [[ "$webroot_choice" =~ ^[Yy]$ ]]; then
            read -p "Enter your webroot path (e.g., /var/www/html): " WEBROOT
            sudo certbot renew --webroot -w "$WEBROOT"
            echo ""
        fi
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

echo -e "${GREEN}Renewal completed.${NC}"
read -p "Press Enter to continue..."
