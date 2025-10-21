#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Certbot Auto-Renewal Toggle${NC}"
echo "============================"

CRON_CMD="certbot renew --quiet"

# Check current status
if crontab -l 2>/dev/null | grep -q "$CRON_CMD"; then
    echo -e "${GREEN}Auto-renewal is currently: ENABLED${NC}"
    echo ""
    echo "1. Disable auto-renewal"
    echo "2. View current schedule"
    echo "0. Exit"
    read -p "Select option [0-2]: " choice
    
    case $choice in
        1)
            # Remove cron job
            crontab -l 2>/dev/null | grep -v "$CRON_CMD" | crontab -
            echo -e "${YELLOW}Auto-renewal has been disabled.${NC}"
            ;;
        2)
            echo -e "${BLUE}Current schedule:${NC}"
            crontab -l 2>/dev/null | grep "$CRON_CMD"
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            ;;
    esac
else
    echo -e "${RED}Auto-renewal is currently: DISABLED${NC}"
    echo ""
    echo "1. Enable auto-renewal (daily at 3:00 AM)"
    echo "2. Enable auto-renewal (custom schedule)"
    echo "0. Exit"
    read -p "Select option [0-2]: " choice
    
    case $choice in
        1)
            # Add default cron job
            (crontab -l 2>/dev/null; echo "0 3 * * * $CRON_CMD") | crontab -
            echo -e "${GREEN}Auto-renewal enabled (daily at 3:00 AM).${NC}"
            ;;
        2)
            read -p "Enter minute (0-59): " minute
            read -p "Enter hour (0-23): " hour
            read -p "Enter day of month (1-31, or * for any): " day
            read -p "Enter month (1-12, or * for any): " month
            read -p "Enter day of week (0-7, or * for any): " weekday
            custom_cron="$minute $hour $day $month $weekday $CRON_CMD"
            (crontab -l 2>/dev/null; echo "$custom_cron") | crontab -
            echo -e "${GREEN}Auto-renewal enabled with custom schedule.${NC}"
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            ;;
    esac
fi

read -p "Press Enter to continue..."
