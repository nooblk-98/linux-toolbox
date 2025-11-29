#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Git Setup Tool${NC}"

read -p "Enter your Git username: " git_user
read -p "Enter your Git email: " git_email

git config --global user.name "$git_user"
git config --global user.email "$git_email"

read -p "Generate SSH key for Git? (y/n): " gen_key
if [[ "$gen_key" =~ ^[Yy]$ ]]; then
    ssh-keygen -t rsa -b 4096 -C "$git_email"
    echo -e "${GREEN}SSH key generated. Public key:${NC}"
    cat ~/.ssh/id_rsa.pub
fi

echo -e "${GREEN}Git configuration complete${NC}"
read -p "Press Enter to continue..."
