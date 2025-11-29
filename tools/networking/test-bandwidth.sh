#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Network Bandwidth Test${NC}"

if ! command -v speedtest-cli >/dev/null 2>&1; then
    echo "Installing speedtest-cli..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y speedtest-cli
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y python3-pip && pip3 install speedtest-cli
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y python3-pip && pip3 install speedtest-cli
    fi
fi

echo -e "${GREEN}Running speed test...${NC}"
speedtest-cli

read -p "Press Enter to continue..."
