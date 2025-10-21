#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Backup Manager${NC}"
echo "1. Create backup"
echo "2. Schedule daily backup"
echo "3. Restore backup"
echo "4. List backups"
read -p "Select option [1-4]: " choice

case $choice in
    1)
        read -p "Enter source directory: " source
        read -p "Enter backup destination: " dest
        mkdir -p "$dest"
        tar -czf "$dest/backup_$(date +%Y%m%d_%H%M%S).tar.gz" -C "$(dirname "$source")" "$(basename "$source")"
        echo -e "${GREEN}Backup created${NC}"
        ;;
    2)
        read -p "Enter source directory: " source
        read -p "Enter backup destination: " dest
        cron_entry="0 2 * * * tar -czf $dest/backup_\$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz -C \$(dirname $source) \$(basename $source)"
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
        echo -e "${GREEN}Daily backup scheduled at 2 AM${NC}"
        ;;
    3)
        read -p "Enter backup file path: " backup_file
        read -p "Enter restore destination: " restore_dest
        tar -xzf "$backup_file" -C "$restore_dest"
        echo -e "${GREEN}Backup restored${NC}"
        ;;
    4)
        read -p "Enter backup directory: " backup_dir
        ls -la "$backup_dir"/*.tar.gz 2>/dev/null || echo "No backups found"
        ;;
esac

read -p "Press Enter to continue..."
