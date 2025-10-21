#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Firewall Manager${NC}"
echo "1. Enable UFW"
echo "2. Disable UFW"
echo "3. Allow port"
echo "4. Block port"
echo "5. Show status"
echo "6. Reset firewall"
read -p "Select option [1-6]: " choice

case $choice in
    1) sudo ufw --force enable && echo -e "${GREEN}UFW enabled${NC}" ;;
    2) sudo ufw disable && echo -e "${YELLOW}UFW disabled${NC}" ;;
    3) 
        read -p "Enter port to allow: " port
        sudo ufw allow "$port"
        echo -e "${GREEN}Port $port allowed${NC}"
        ;;
    4)
        read -p "Enter port to block: " port
        sudo ufw deny "$port"
        echo -e "${RED}Port $port blocked${NC}"
        ;;
    5) sudo ufw status verbose ;;
    6) 
        read -p "Reset firewall rules? (y/n): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] && sudo ufw --force reset
        ;;
    *) echo -e "${RED}Invalid option${NC}" ;;
esac

read -p "Press Enter to continue..."
