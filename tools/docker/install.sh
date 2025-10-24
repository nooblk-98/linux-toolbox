#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Docker & Docker Compose Installer${NC}"
echo "======================================"

# Detect package manager and OS
if command -v apt-get >/dev/null 2>&1; then
    PM="apt"
    OS_ID=$(lsb_release -is 2>/dev/null || echo "debian")
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
    OS_ID="centos"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
    OS_ID="fedora"
elif command -v pacman >/dev/null 2>&1; then
    PM="pacman"
    OS_ID="arch"
elif command -v zypper >/dev/null 2>&1; then
    PM="zypper"
    OS_ID="opensuse"
else
    echo -e "${RED}Unsupported package manager${NC}"
    exit 1
fi

echo -e "${GREEN}Detected OS: $OS_ID with package manager: $PM${NC}"

# Install Docker
echo -e "${YELLOW}Installing Docker...${NC}"
case $PM in
    "apt")
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$(echo $OS_ID | tr '[:upper:]' '[:lower:]')/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(echo $OS_ID | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
    "yum")
        # CentOS/RHEL
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
    "dnf")
        # Fedora
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;
    "pacman")
        # Arch Linux
        sudo pacman -Syu --noconfirm docker docker-compose
        ;;
    "zypper")
        # openSUSE
        sudo zypper install -y docker docker-compose
        ;;
esac

# Start and enable Docker service
echo -e "${YELLOW}Starting Docker service...${NC}"
sudo systemctl enable docker
sudo systemctl start docker

# Add current user to docker group
echo -e "${YELLOW}Adding user to docker group...${NC}"
sudo usermod -aG docker $USER

# Install Docker Compose (standalone) if not already installed via plugin
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing Docker Compose standalone...${NC}"
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Verify installation
echo ""
echo -e "${GREEN}Installation completed!${NC}"
echo -e "${BLUE}Docker version:${NC} $(docker --version 2>/dev/null || echo "Not available")"

if command -v docker-compose >/dev/null 2>&1; then
    echo -e "${BLUE}Docker Compose version:${NC} $(docker-compose --version)"
elif docker compose version >/dev/null 2>&1; then
    echo -e "${BLUE}Docker Compose (plugin) version:${NC} $(docker compose version)"
fi

echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "- You may need to log out and back in for group changes to take effect"
echo "- Test with: docker run hello-world"
echo "- Use 'docker compose' (new) or 'docker-compose' (legacy)"

read -p "Press Enter to continue..."