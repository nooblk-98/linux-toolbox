#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Port Scanner${NC}"
read -p "Enter target IP/hostname: " target
read -p "Enter port range (e.g., 1-1000): " port_range

IFS='-' read -ra RANGE <<< "$port_range"
start_port=${RANGE[0]}
end_port=${RANGE[1]}

echo "Scanning ports $start_port to $end_port on $target..."
for ((port=$start_port; port<=$end_port; port++)); do
    timeout 1 bash -c "echo >/dev/tcp/$target/$port" 2>/dev/null && echo -e "${GREEN}Port $port: Open${NC}" || echo -e "${RED}Port $port: Closed${NC}"
done

read -p "Press Enter to continue..."
