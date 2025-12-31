#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Fail2ban Setup${NC}"

if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y fail2ban
elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y epel-release && sudo yum install -y fail2ban
elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y fail2ban
fi

sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Basic configuration
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

sudo systemctl restart fail2ban
echo -e "${GREEN}Fail2ban installed and configured${NC}"
read -p "Press Enter to continue..."
