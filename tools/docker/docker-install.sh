#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Docker & Docker Compose Installer${NC}"
echo "======================================"

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
    PM="apt"
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
else
    echo -e "${RED}No supported package manager found.${NC}"
    exit 1
fi

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
if [ "$PM" = "apt" ]; then
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
elif [ "$PM" = "yum" ]; then
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io
elif [ "$PM" = "dnf" ]; then
    sudo dnf -y install dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io
fi

# Start and enable Docker
sudo systemctl enable docker
sudo systemctl start docker

echo -e "${GREEN}Docker installed and started.${NC}"

# Install Docker Compose (latest version)
echo -e "${YELLOW}Installing Docker Compose...${NC}"
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

if command -v docker-compose >/dev/null 2>&1; then
    echo -e "${GREEN}Docker Compose installed: $(docker-compose --version)${NC}"
else
    echo -e "${RED}Docker Compose installation failed.${NC}"
fi

# Add current user to docker group
sudo usermod -aG docker $USER
echo -e "${YELLOW}You may need to log out and back in for group changes to take effect.${NC}"

read -p "Press Enter to continue..."
