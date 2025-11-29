#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Python Environment Manager${NC}"
echo "1. Create virtual environment"
echo "2. List virtual environments"
echo "3. Remove virtual environment"
read -p "Select option [1-3]: " choice

case $choice in
    1)
        read -p "Enter environment name: " env_name
        python3 -m venv "$env_name"
        echo -e "${GREEN}Virtual environment '$env_name' created${NC}"
        echo "To activate: source $env_name/bin/activate"
        ;;
    2)
        echo "Available environments:"
        ls -d */ 2>/dev/null | grep -E "(venv|env)" || echo "No virtual environments found"
        ;;
    3)
        read -p "Enter environment name to remove: " env_name
        rm -rf "$env_name"
        echo -e "${GREEN}Environment '$env_name' removed${NC}"
        ;;
esac

read -p "Press Enter to continue..."
