#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Node.js & npm Installer${NC}"
echo "This script will install your selected version of Node.js and npm."

read -p "Enter Node.js version (e.g., 18, 20, 21): " NODE_VER

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PM="apt"
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
else
    echo -e "${RED}No supported package manager found.${NC}"
    exit 1
fi

echo -e "${GREEN}Installing Node.js v$NODE_VER...${NC}"

if [ "$PM" = "apt" ]; then
    curl -fsSL https://deb.nodesource.com/setup_"$NODE_VER".x | sudo -E bash -
    sudo apt-get install -y nodejs
elif [ "$PM" = "yum" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_"$NODE_VER".x | sudo bash -
    sudo yum install -y nodejs
elif [ "$PM" = "dnf" ]; then
    curl -fsSL https://rpm.nodesource.com/setup_"$NODE_VER".x | sudo bash -
    sudo dnf install -y nodejs
fi

echo -e "${GREEN}Node.js version: $(node -v)${NC}"
echo -e "${GREEN}npm version: $(npm -v)${NC}"

read -p "Press Enter to continue..."
