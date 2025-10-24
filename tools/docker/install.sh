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
    # Detect Amazon Linux, CentOS/RHEL version more accurately
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ "$ID" == "amzn" ]]; then
            OS_ID="amazon"
            OS_VERSION="$VERSION_ID"
        elif [[ "$ID" == "centos" ]]; then
            OS_ID="centos"
            OS_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)
        elif [[ "$ID" == "rhel" ]]; then
            OS_ID="rhel"
            OS_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)
        elif [[ "$ID" == "rocky" ]]; then
            OS_ID="centos"  # Rocky uses CentOS repos for Docker
            OS_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)
        elif [[ "$ID" == "almalinux" ]]; then
            OS_ID="centos"  # AlmaLinux uses CentOS repos for Docker
            OS_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)
        fi
    elif [ -f /etc/redhat-release ]; then
        if grep -q "Amazon Linux" /etc/redhat-release; then
            OS_ID="amazon"
            OS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
        elif grep -q "CentOS" /etc/redhat-release; then
            OS_ID="centos"
            OS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
        elif grep -q "Red Hat" /etc/redhat-release; then
            OS_ID="rhel"
            OS_VERSION=$(grep -oE '[0-9]+' /etc/redhat-release | head -1)
        else
            OS_ID="centos"
            OS_VERSION="7"
        fi
    else
        OS_ID="centos"
        OS_VERSION="7"
    fi
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
if [ -n "$OS_VERSION" ]; then
    echo -e "${GREEN}OS Version: $OS_VERSION${NC}"
fi

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
        case $OS_ID in
            "amazon")
                # Amazon Linux 2
                echo -e "${YELLOW}Installing Docker for Amazon Linux...${NC}"
                sudo yum update -y
                sudo yum install -y docker
                # Install docker-compose from pip
                sudo yum install -y python3-pip
                sudo pip3 install docker-compose
                ;;
            "centos"|"rhel")
                # CentOS/RHEL - existing logic
                if [ "$OS_VERSION" -ge 8 ]; then
                    # CentOS 8+ / RHEL 8+
                    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                    
                    # For CentOS 8+, we might need to use podman-docker or install from EPEL
                    if ! sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
                        echo -e "${YELLOW}Official Docker repo failed, trying alternative installation...${NC}"
                        sudo yum install -y epel-release
                        sudo yum install -y docker docker-compose
                    fi
                else
                    # CentOS 7 / RHEL 7
                    sudo yum install -y yum-utils device-mapper-persistent-data lvm2
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                    sudo yum install -y docker-ce docker-ce-cli containerd.io
                    
                    # Install docker-compose separately for CentOS 7
                    if ! command -v docker-compose >/dev/null 2>&1; then
                        sudo yum install -y epel-release
                        sudo yum install -y python-pip
                        sudo pip install docker-compose
                    fi
                fi
                ;;
            *)
                echo -e "${RED}Unsupported OS: $OS_ID${NC}"
                exit 1
                ;;
        esac
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

# Create docker group if it doesn't exist
if ! getent group docker >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating docker group...${NC}"
    sudo groupadd docker
fi

# Start and enable Docker service
echo -e "${YELLOW}Starting Docker service...${NC}"
if systemctl list-unit-files | grep -q docker.service; then
    sudo systemctl enable docker
    sudo systemctl start docker
elif command -v service >/dev/null 2>&1; then
    # Fallback for older systems
    sudo service docker start
    sudo chkconfig docker on 2>/dev/null || true
else
    echo -e "${RED}Could not start Docker service${NC}"
fi

# Special handling for Amazon Linux firewall
if [ "$OS_ID" = "amazon" ]; then
    echo -e "${YELLOW}Configuring firewall for Amazon Linux...${NC}"
    # Enable docker service to start on boot
    sudo systemctl enable docker
    # Make sure docker0 bridge is properly configured
    sudo systemctl restart docker
fi

# Verify Docker is running
if ! sudo docker version >/dev/null 2>&1; then
    echo -e "${YELLOW}Docker service might not be running, attempting to start...${NC}"
    sudo systemctl start docker 2>/dev/null || sudo service docker start 2>/dev/null
fi

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

# Better verification
if sudo docker version >/dev/null 2>&1; then
    echo -e "${BLUE}Docker version:${NC} $(sudo docker --version)"
    echo -e "${GREEN}✓ Docker is working${NC}"
else
    echo -e "${RED}✗ Docker installation may have issues${NC}"
    echo -e "${YELLOW}Try: sudo systemctl status docker${NC}"
fi

if command -v docker-compose >/dev/null 2>&1; then
    echo -e "${BLUE}Docker Compose version:${NC} $(docker-compose --version)"
elif docker compose version >/dev/null 2>&1; then
    echo -e "${BLUE}Docker Compose (plugin) version:${NC} $(docker compose version)"
fi

echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "- You may need to log out and back in for group changes to take effect"
echo "- Test with: sudo docker run hello-world (then try without sudo after re-login)"
echo "- Use 'docker compose' (new) or 'docker-compose' (legacy)"
if [ "$OS_ID" = "amazon" ]; then
    echo "- Amazon Linux 2 uses system Docker package (not Docker CE)"
fi
if [ "$OS_VERSION" -ge 8 ] && [ "$PM" = "yum" ] && [ "$OS_ID" != "amazon" ]; then
    echo "- For CentOS 8+, consider using Podman as an alternative to Docker"
fi

read -p "Press Enter to continue..."