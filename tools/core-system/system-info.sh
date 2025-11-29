#!/bin/bash
# Comprehensive system information display

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}=== System Information ===${NC}\n"

# OS Information
echo -e "${CYAN}Operating System:${NC}"
cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"'
uname -r
echo ""

# Hardware Information
echo -e "${CYAN}Hardware:${NC}"
echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
echo "Cores: $(nproc)"
echo "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
echo ""

# Disk Information
echo -e "${CYAN}Disk Usage:${NC}"
df -h | grep -E '^/dev/'
echo ""

# Network Information
echo -e "${CYAN}Network Interfaces:${NC}"
ip -brief addr show
echo ""

# Uptime
echo -e "${CYAN}System Uptime:${NC}"
uptime -p
echo ""

# Load Average
echo -e "${CYAN}Load Average:${NC}"
uptime | awk -F'load average:' '{print $2}'
