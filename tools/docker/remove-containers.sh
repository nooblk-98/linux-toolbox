#!/bin/bash

# Interactive Docker Container Removal Tool
# Allows selective removal of Docker containers

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Docker Container Removal Tool       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker is not running${NC}"
    exit 1
fi

# Menu
echo -e "${YELLOW}Select removal option:${NC}"
echo "1. Remove all stopped containers"
echo "2. Remove specific container (interactive)"
echo "3. Remove containers by status"
echo "4. Remove all containers (including running)"
echo "5. Exit"
echo ""
read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo -e "${CYAN}Listing stopped containers...${NC}"
        STOPPED=$(docker ps -a -f status=exited -q)
        
        if [ -z "$STOPPED" ]; then
            echo -e "${YELLOW}No stopped containers found${NC}"
        else
            docker ps -a -f status=exited
            echo ""
            read -p "Remove all stopped containers? (y/n): " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker container prune -f
                echo -e "${GREEN}✓ Stopped containers removed${NC}"
            else
                echo -e "${YELLOW}Operation cancelled${NC}"
            fi
        fi
        ;;
    2)
        echo -e "${CYAN}Available containers:${NC}"
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}"
        echo ""
        read -p "Enter container ID or name to remove: " container
        
        if [ -n "$container" ]; then
            if docker ps -a --format "{{.ID}} {{.Names}}" | grep -q "$container"; then
                read -p "Force remove (stop if running)? (y/n): " force
                if [[ "$force" =~ ^[Yy]$ ]]; then
                    docker rm -f "$container"
                    echo -e "${GREEN}✓ Container removed${NC}"
                else
                    docker rm "$container"
                    if [ $? -eq 0 ]; then
                        echo -e "${GREEN}✓ Container removed${NC}"
                    else
                        echo -e "${RED}✗ Failed to remove container (may be running)${NC}"
                    fi
                fi
            else
                echo -e "${RED}✗ Container not found${NC}"
            fi
        fi
        ;;
    3)
        echo -e "${YELLOW}Select status:${NC}"
        echo "1. Exited"
        echo "2. Created"
        echo "3. Dead"
        echo ""
        read -p "Enter choice (1-3): " status_choice
        
        case $status_choice in
            1) STATUS="exited" ;;
            2) STATUS="created" ;;
            3) STATUS="dead" ;;
            *) echo -e "${RED}Invalid choice${NC}"; exit 1 ;;
        esac
        
        echo -e "${CYAN}Containers with status: $STATUS${NC}"
        docker ps -a -f status=$STATUS
        echo ""
        read -p "Remove all containers with this status? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            docker ps -a -f status=$STATUS -q | xargs -r docker rm
            echo -e "${GREEN}✓ Containers removed${NC}"
        else
            echo -e "${YELLOW}Operation cancelled${NC}"
        fi
        ;;
    4)
        echo -e "${RED}⚠ WARNING: This will remove ALL containers including running ones!${NC}"
        docker ps -a
        echo ""
        read -p "Are you absolutely sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" = "yes" ]; then
            docker rm -f $(docker ps -a -q)
            echo -e "${GREEN}✓ All containers removed${NC}"
        else
            echo -e "${YELLOW}Operation cancelled${NC}"
        fi
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
echo -e "${CYAN}Remaining containers:${NC}"
docker ps -a

echo ""
read -p "Press Enter to continue..."