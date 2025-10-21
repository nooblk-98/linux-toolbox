#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Network Information${NC}"
echo "================================"

echo -e "${GREEN}IP Configuration:${NC}"
ip addr show

echo -e "\n${GREEN}Routing Table:${NC}"
ip route show

echo -e "\n${GREEN}DNS Configuration:${NC}"
cat /etc/resolv.conf

echo -e "\n${GREEN}Public IP:${NC}"
curl -s ifconfig.me

read -p "Press Enter to continue..."
