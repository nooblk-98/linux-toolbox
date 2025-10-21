#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}PM2 Manager${NC}"

# Check if PM2 is installed
if ! command -v pm2 >/dev/null 2>&1; then
    echo -e "${RED}PM2 not found. Installing...${NC}"
    npm install -g pm2
fi

echo "1. Start application"
echo "2. Stop application"
echo "3. Restart application"
echo "4. Delete application"
echo "5. List applications"
echo "6. Show logs"
echo "7. Monitor processes"
echo "8. Save PM2 list"
echo "9. Resurrect saved processes"
echo "10. Setup startup script"
read -p "Select option [1-10]: " choice

case $choice in
    1)
        read -p "Enter application path/name: " app_path
        read -p "Enter application name (optional): " app_name
        if [ -n "$app_name" ]; then
            pm2 start "$app_path" --name "$app_name"
        else
            pm2 start "$app_path"
        fi
        ;;
    2)
        read -p "Enter application name/id: " app_id
        pm2 stop "$app_id"
        ;;
    3)
        read -p "Enter application name/id: " app_id
        pm2 restart "$app_id"
        ;;
    4)
        read -p "Enter application name/id: " app_id
        pm2 delete "$app_id"
        ;;
    5)
        pm2 list
        ;;
    6)
        read -p "Enter application name/id (or press Enter for all): " app_id
        if [ -n "$app_id" ]; then
            pm2 logs "$app_id"
        else
            pm2 logs
        fi
        ;;
    7)
        pm2 monit
        ;;
    8)
        pm2 save
        echo -e "${GREEN}PM2 process list saved${NC}"
        ;;
    9)
        pm2 resurrect
        echo -e "${GREEN}Saved processes resurrected${NC}"
        ;;
    10)
        pm2 startup
        echo -e "${GREEN}Run the generated command as root${NC}"
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
esac

read -p "Press Enter to continue..."
