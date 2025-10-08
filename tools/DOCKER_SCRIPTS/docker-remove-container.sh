#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Docker Container Remover${NC}"

containers=()
names=()
ids=()

while IFS= read -r line; do
    cid=$(echo "$line" | awk '{print $1}')
    cname=$(echo "$line" | awk '{print $2}')
    # Only add if name is not empty
    if [ -n "$cname" ]; then
        containers+=("$cid $cname")
        names+=("$cname")
        ids+=("$cid")
    fi
done < <(docker ps -a --format '{{.ID}} {{.Names}}')

if [ ${#containers[@]} -eq 0 ]; then
    echo -e "${RED}No containers found.${NC}"
    exit 0
fi

echo "List of running and stopped containers:"
i=1
for entry in "${containers[@]}"; do
    cid=$(echo "$entry" | awk '{print $1}')
    cname=$(echo "$entry" | awk '{print $2}')
    status=$(docker inspect -f '{{.State.Status}}' "$cid")
    echo -e "${GREEN}$i.${NC} $cname ($cid) - $status"
    ((i++))
done

echo -e "${RED}0.${NC} Cancel"
read -p "Select a container to remove [1-$((${#containers[@]}))]: " choice

if [[ "$choice" == "0" ]]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

if [[ "$choice" -ge 1 && "$choice" -le ${#containers[@]} ]]; then
    selected="${containers[$((choice-1))]}"
    cid=$(echo "$selected" | awk '{print $1}')
    cname=$(echo "$selected" | awk '{print $2}')
    echo -e "${YELLOW}Stopping container $cname ($cid)...${NC}"
    docker stop "$cid" 2>/dev/null
    echo -e "${YELLOW}Removing container $cname ($cid)...${NC}"
    docker rm "$cid"
    echo -e "${GREEN}Container $cname removed.${NC}"
else
    echo -e "${RED}Invalid selection.${NC}"
fi

read -p "Press Enter to continue..."
