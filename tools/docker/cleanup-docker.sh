#!/bin/bash

# Docker Cleanup Script
# Removes unused containers, images, volumes, and networks

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Docker Cleanup Tool                  ║${NC}"
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

# Show current Docker disk usage
echo -e "${CYAN}Current Docker disk usage:${NC}"
docker system df
echo ""

# Cleanup menu
echo -e "${YELLOW}Select cleanup option:${NC}"
echo "1. Remove stopped containers"
echo "2. Remove unused images"
echo "3. Remove unused volumes"
echo "4. Remove unused networks"
echo "5. Remove all unused data (containers, images, volumes, networks)"
echo "6. Aggressive cleanup (remove everything unused including build cache)"
echo "7. Custom cleanup"
echo "8. Exit"
echo ""
read -p "Enter your choice (1-8): " choice

case $choice in
    1)
        echo -e "${CYAN}Removing stopped containers...${NC}"
        docker container prune -f
        echo -e "${GREEN}✓ Stopped containers removed${NC}"
        ;;
    2)
        echo -e "${CYAN}Removing unused images...${NC}"
        docker image prune -a -f
        echo -e "${GREEN}✓ Unused images removed${NC}"
        ;;
    3)
        echo -e "${CYAN}Removing unused volumes...${NC}"
        docker volume prune -f
        echo -e "${GREEN}✓ Unused volumes removed${NC}"
        ;;
    4)
        echo -e "${CYAN}Removing unused networks...${NC}"
        docker network prune -f
        echo -e "${GREEN}✓ Unused networks removed${NC}"
        ;;
    5)
        echo -e "${CYAN}Removing all unused data...${NC}"
        docker system prune -a -f --volumes
        echo -e "${GREEN}✓ All unused data removed${NC}"
        ;;
    6)
        echo -e "${YELLOW}⚠ Warning: This will remove:${NC}"
        echo "  - All stopped containers"
        echo "  - All networks not used by at least one container"
        echo "  - All images without at least one container associated"
        echo "  - All build cache"
        echo "  - All volumes not used by at least one container"
        echo ""
        read -p "Are you sure? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            echo -e "${CYAN}Performing aggressive cleanup...${NC}"
            docker system prune -a -f --volumes
            docker builder prune -a -f
            echo -e "${GREEN}✓ Aggressive cleanup completed${NC}"
        else
            echo -e "${YELLOW}Cleanup cancelled${NC}"
        fi
        ;;
    7)
        echo -e "${YELLOW}Custom cleanup options:${NC}"
        echo ""
        read -p "Remove stopped containers? (y/n): " rm_containers
        read -p "Remove dangling images? (y/n): " rm_dangling
        read -p "Remove all unused images? (y/n): " rm_images
        read -p "Remove unused volumes? (y/n): " rm_volumes
        read -p "Remove unused networks? (y/n): " rm_networks
        read -p "Remove build cache? (y/n): " rm_cache
        
        echo ""
        echo -e "${CYAN}Performing custom cleanup...${NC}"
        
        if [[ "$rm_containers" =~ ^[Yy]$ ]]; then
            docker container prune -f
            echo -e "${GREEN}✓ Stopped containers removed${NC}"
        fi
        
        if [[ "$rm_dangling" =~ ^[Yy]$ ]]; then
            docker image prune -f
            echo -e "${GREEN}✓ Dangling images removed${NC}"
        fi
        
        if [[ "$rm_images" =~ ^[Yy]$ ]]; then
            docker image prune -a -f
            echo -e "${GREEN}✓ All unused images removed${NC}"
        fi
        
        if [[ "$rm_volumes" =~ ^[Yy]$ ]]; then
            docker volume prune -f
            echo -e "${GREEN}✓ Unused volumes removed${NC}"
        fi
        
        if [[ "$rm_networks" =~ ^[Yy]$ ]]; then
            docker network prune -f
            echo -e "${GREEN}✓ Unused networks removed${NC}"
        fi
        
        if [[ "$rm_cache" =~ ^[Yy]$ ]]; then
            docker builder prune -a -f
            echo -e "${GREEN}✓ Build cache removed${NC}"
        fi
        ;;
    8)
        echo -e "${YELLOW}Cleanup cancelled${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Show disk usage after cleanup
echo ""
echo -e "${CYAN}Docker disk usage after cleanup:${NC}"
docker system df

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Cleanup Complete!                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

read -p "Press Enter to continue..."