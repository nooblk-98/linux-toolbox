#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}User Manager${NC}"
echo "1. Add user"
echo "2. Delete user"
echo "3. Add user to sudo"
echo "4. Remove user from sudo"
echo "5. List users"
read -p "Select option [1-5]: " choice

case $choice in
    1)
        read -p "Enter username: " username
        sudo adduser "$username"
        ;;
    2)
        read -p "Enter username to delete: " username
        sudo deluser --remove-home "$username"
        ;;
    3)
        read -p "Enter username: " username
        sudo usermod -aG sudo "$username"
        echo -e "${GREEN}User $username added to sudo group${NC}"
        ;;
    4)
        read -p "Enter username: " username
        sudo deluser "$username" sudo
        echo -e "${YELLOW}User $username removed from sudo group${NC}"
        ;;
    5)
        echo "System users:"
        cat /etc/passwd | grep -E ":/home/|:/bin/bash" | cut -d: -f1
        ;;
    *) echo -e "${RED}Invalid option${NC}" ;;
esac

read -p "Press Enter to continue..."
