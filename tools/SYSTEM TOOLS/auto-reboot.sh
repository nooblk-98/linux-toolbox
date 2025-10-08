#!/bin/bash

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Auto Reboot Configuration Tool${NC}"
echo "=============================="
echo ""
echo "1. Daily reboot at specific time"
echo "2. Weekly reboot"
echo "3. Monthly reboot"
echo "4. Remove auto reboot"
echo ""
read -p "Select option [1-4]: " reboot_choice

case $reboot_choice in
    1)
        read -p "Enter hour (0-23): " hour
        read -p "Enter minute (0-59): " minute
        cron_entry="$minute $hour * * * /sbin/reboot"
        ;;
    2)
        read -p "Enter day of week (0=Sunday, 1=Monday, etc.): " day
        read -p "Enter hour (0-23): " hour
        read -p "Enter minute (0-59): " minute
        cron_entry="$minute $hour * * $day /sbin/reboot"
        ;;
    3)
        read -p "Enter day of month (1-31): " day
        read -p "Enter hour (0-23): " hour
        read -p "Enter minute (0-59): " minute
        cron_entry="$minute $hour $day * * /sbin/reboot"
        ;;
    4)
        crontab -l | grep -v "/sbin/reboot" | crontab -
        echo -e "${GREEN}Auto reboot removed!${NC}"
        read -p "Press Enter to continue..."
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

# Add to crontab
(crontab -l 2>/dev/null | grep -v "/sbin/reboot"; echo "$cron_entry") | crontab -

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Auto reboot configured successfully!${NC}"
    echo -e "${BLUE}Cron entry:${NC} $cron_entry"
else
    echo -e "${RED}Failed to configure auto reboot!${NC}"
fi

read -p "Press Enter to continue..."
