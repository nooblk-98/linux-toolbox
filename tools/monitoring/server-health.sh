#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Server Health Check${NC}"
echo "================================"

# System uptime
echo -e "${GREEN}Uptime:${NC} $(uptime -p)"

# Load average
load=$(uptime | awk -F'load average:' '{print $2}')
echo -e "${GREEN}Load Average:${NC}$load"

# Memory usage
mem_info=$(free -h | grep Mem)
echo -e "${GREEN}Memory:${NC} $mem_info"

# Disk usage
echo -e "${GREEN}Disk Usage:${NC}"
df -h | grep -E "^/dev/"

# Running services
echo -e "\n${GREEN}Critical Services:${NC}"
services=("ssh" "nginx" "apache2" "mysql" "docker")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo -e "$service: ${GREEN}Running${NC}"
    else
        echo -e "$service: ${RED}Stopped${NC}"
    fi
done

read -p "Press Enter to continue..."
