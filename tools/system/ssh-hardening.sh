#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}SSH Hardening Tool${NC}"

# Backup SSH config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

# Apply hardening
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

read -p "Change SSH port? (y/n): " change_port
if [[ "$change_port" =~ ^[Yy]$ ]]; then
    read -p "Enter new SSH port (default 22): " new_port
    new_port=${new_port:-22}
    sudo sed -i "s/#Port 22/Port $new_port/" /etc/ssh/sshd_config
fi

sudo systemctl restart sshd
echo -e "${GREEN}SSH hardening complete${NC}"
read -p "Press Enter to continue..."
