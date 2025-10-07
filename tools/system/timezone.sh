#!/bin/bash

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Timezone Configuration Tool${NC}"
echo "=============================="
echo -e "${BLUE}Current timezone:${NC} $(timedatectl show --property=Timezone --value)"
echo ""
echo "Available timezones (common ones):"
echo "1. UTC"
echo "2. America/New_York"
echo "3. America/Los_Angeles"
echo "4. Europe/London"
echo "5. Europe/Berlin"
echo "6. Asia/Tokyo"
echo "7. Custom (manual entry)"
echo ""
read -p "Select timezone [1-7]: " tz_choice

case $tz_choice in
    1) timezone="UTC" ;;
    2) timezone="America/New_York" ;;
    3) timezone="America/Los_Angeles" ;;
    4) timezone="Europe/London" ;;
    5) timezone="Europe/Berlin" ;;
    6) timezone="Asia/Tokyo" ;;
    7)
        read -p "Enter timezone (e.g., Asia/Shanghai): " timezone
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}Setting timezone to: $timezone${NC}"
sudo timedatectl set-timezone "$timezone"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Timezone changed successfully!${NC}"
    echo -e "${BLUE}New timezone:${NC} $(timedatectl show --property=Timezone --value)"
else
    echo -e "${RED}Failed to change timezone!${NC}"
fi

read -p "Press Enter to continue..."
