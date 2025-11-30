#!/bin/bash

# Schedule Automatic System Reboot
# Allows scheduling regular system reboots for maintenance

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Schedule Automatic Reboot            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}✗ This script must be run as root${NC}"
    exit 1
fi

# Menu
echo -e "${YELLOW}Select an option:${NC}"
echo "1. Schedule one-time reboot"
echo "2. Schedule recurring reboot (cron)"
echo "3. View scheduled reboots"
echo "4. Remove scheduled reboots"
echo "5. Exit"
echo ""
read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo -e "${CYAN}Schedule one-time reboot${NC}"
        echo ""
        echo "Enter reboot time:"
        echo "Examples:"
        echo "  - now +10 (10 minutes from now)"
        echo "  - 02:00 (2 AM today/tomorrow)"
        echo "  - 14:30 (2:30 PM today/tomorrow)"
        echo ""
        read -p "Time: " reboot_time
        
        if [ -n "$reboot_time" ]; then
            shutdown -r "$reboot_time"
            echo -e "${GREEN}✓ Reboot scheduled for: $reboot_time${NC}"
            echo -e "${YELLOW}To cancel: shutdown -c${NC}"
        else
            echo -e "${RED}✗ Invalid time${NC}"
        fi
        ;;
    2)
        echo -e "${CYAN}Schedule recurring reboot (cron)${NC}"
        echo ""
        echo "Select frequency:"
        echo "1. Daily at specific time"
        echo "2. Weekly on specific day"
        echo "3. Monthly on specific date"
        echo "4. Custom cron expression"
        echo ""
        read -p "Enter choice (1-4): " freq_choice
        
        case $freq_choice in
            1)
                read -p "Enter time (HH:MM, 24-hour format): " time
                hour=$(echo $time | cut -d: -f1)
                minute=$(echo $time | cut -d: -f2)
                cron_expr="$minute $hour * * * /sbin/shutdown -r now"
                ;;
            2)
                echo "Days: 0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday"
                read -p "Enter day (0-6): " day
                read -p "Enter time (HH:MM): " time
                hour=$(echo $time | cut -d: -f1)
                minute=$(echo $time | cut -d: -f2)
                cron_expr="$minute $hour * * $day /sbin/shutdown -r now"
                ;;
            3)
                read -p "Enter date (1-31): " date
                read -p "Enter time (HH:MM): " time
                hour=$(echo $time | cut -d: -f1)
                minute=$(echo $time | cut -d: -f2)
                cron_expr="$minute $hour $date * * /sbin/shutdown -r now"
                ;;
            4)
                echo "Enter cron expression (minute hour day month weekday)"
                echo "Example: 0 2 * * 0 (Every Sunday at 2 AM)"
                read -p "Cron expression: " custom_cron
                cron_expr="$custom_cron /sbin/shutdown -r now"
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                exit 1
                ;;
        esac
        
        # Add to crontab
        (crontab -l 2>/dev/null; echo "$cron_expr") | crontab -
        echo -e "${GREEN}✓ Recurring reboot scheduled${NC}"
        echo -e "${CYAN}Cron entry: $cron_expr${NC}"
        ;;
    3)
        echo -e "${CYAN}Scheduled reboots:${NC}"
        echo ""
        echo -e "${YELLOW}One-time reboots (shutdown):${NC}"
        if [ -f /run/systemd/shutdown/scheduled ]; then
            cat /run/systemd/shutdown/scheduled
        else
            echo "No one-time reboots scheduled"
        fi
        echo ""
        echo -e "${YELLOW}Recurring reboots (cron):${NC}"
        crontab -l 2>/dev/null | grep shutdown || echo "No recurring reboots scheduled"
        ;;
    4)
        echo -e "${CYAN}Remove scheduled reboots${NC}"
        echo ""
        echo "1. Cancel one-time reboot"
        echo "2. Remove recurring reboot"
        echo ""
        read -p "Enter choice (1-2): " remove_choice
        
        case $remove_choice in
            1)
                shutdown -c
                echo -e "${GREEN}✓ One-time reboot cancelled${NC}"
                ;;
            2)
                echo -e "${YELLOW}Current cron entries with 'shutdown':${NC}"
                crontab -l 2>/dev/null | grep -n shutdown
                echo ""
                read -p "Remove all reboot cron entries? (y/n): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    crontab -l 2>/dev/null | grep -v shutdown | crontab -
                    echo -e "${GREEN}✓ Recurring reboots removed${NC}"
                else
                    echo -e "${YELLOW}Operation cancelled${NC}"
                fi
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
        ;;
    5)
        echo -e "${YELLOW}Exiting${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

echo ""
read -p "Press Enter to continue..."