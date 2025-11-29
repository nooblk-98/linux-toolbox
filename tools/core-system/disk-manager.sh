#!/bin/bash
# Disk usage analysis and cleanup tool

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_menu() {
    clear
    echo -e "${GREEN}=== Disk Manager ===${NC}\n"
    echo "1. Show disk usage"
    echo "2. Find large files (>100MB)"
    echo "3. Find large directories"
    echo "4. Clean package cache"
    echo "5. Clean old logs"
    echo "6. Clean temp files"
    echo "0. Exit"
    echo ""
    read -p "Select option: " choice
}

show_disk_usage() {
    echo -e "\n${YELLOW}Disk Usage:${NC}"
    df -h | grep -E '^/dev/'
    echo ""
    read -p "Press Enter to continue..."
}

find_large_files() {
    echo -e "\n${YELLOW}Finding files larger than 100MB...${NC}"
    find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | awk '{ print $9 ": " $5 }'
    echo ""
    read -p "Press Enter to continue..."
}

find_large_dirs() {
    echo -e "\n${YELLOW}Top 10 largest directories:${NC}"
    du -h --max-depth=1 / 2>/dev/null | sort -rh | head -10
    echo ""
    read -p "Press Enter to continue..."
}

clean_package_cache() {
    echo -e "\n${YELLOW}Cleaning package cache...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get clean
        sudo apt-get autoclean
    elif command -v yum &> /dev/null; then
        sudo yum clean all
    fi
    echo -e "${GREEN}Package cache cleaned${NC}"
    read -p "Press Enter to continue..."
}

clean_logs() {
    echo -e "\n${YELLOW}Cleaning old logs...${NC}"
    sudo journalctl --vacuum-time=7d
    sudo find /var/log -type f -name "*.log" -mtime +30 -delete
    echo -e "${GREEN}Old logs cleaned${NC}"
    read -p "Press Enter to continue..."
}

clean_temp() {
    echo -e "\n${YELLOW}Cleaning temp files...${NC}"
    sudo rm -rf /tmp/*
    sudo rm -rf /var/tmp/*
    echo -e "${GREEN}Temp files cleaned${NC}"
    read -p "Press Enter to continue..."
}

while true; do
    show_menu
    case $choice in
        1) show_disk_usage ;;
        2) find_large_files ;;
        3) find_large_dirs ;;
        4) clean_package_cache ;;
        5) clean_logs ;;
        6) clean_temp ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
done
