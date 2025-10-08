#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Docker Cleanup Utility${NC}"
echo "This will remove all unused containers, images, volumes, and networks."
echo -e "${RED}WARNING: This will permanently delete unused Docker resources!${NC}"
read -p "Proceed? (y/n): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted.${NC}"
    exit 1
fi

echo -e "${GREEN}Stopping all running containers...${NC}"
docker stop $(docker ps -q) 2>/dev/null

echo -e "${GREEN}Removing all stopped containers...${NC}"
docker container prune -f

echo -e "${GREEN}Removing all unused images...${NC}"
docker image prune -a -f

echo -e "${GREEN}Removing all unused volumes...${NC}"
docker volume prune -f

echo -e "${GREEN}Removing all unused networks...${NC}"
docker network prune -f

echo -e "${GREEN}System-wide cleanup...${NC}"
docker system prune -a -f --volumes

echo -e "${YELLOW}Docker cleanup complete.${NC}"
read -p "Press Enter to continue..."
