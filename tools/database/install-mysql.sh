#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}MySQL Server Installer${NC}"

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y mysql-server
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y mysql-server
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y mysql-server
fi

sudo systemctl enable mysql
sudo systemctl start mysql

read -p "Run MySQL secure installation? (y/n): " secure
if [[ "$secure" =~ ^[Yy]$ ]]; then
    sudo mysql_secure_installation
fi

echo -e "${GREEN}MySQL installed and started${NC}"
read -p "Press Enter to continue..."
