#!/bin/bash
# Simple Nginx installation

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

echo -e "${GREEN}=== Simple Nginx Installation ===${NC}\n"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

# Function to install Nginx on Debian/Ubuntu
install_nginx_debian() {
    echo -e "${CYAN}Installing Nginx on Debian/Ubuntu...${NC}"
    
    apt update
    apt install -y nginx
    
    systemctl enable nginx
    systemctl start nginx
    
    echo -e "${GREEN}Nginx installed successfully${NC}"
}

# Function to install Nginx on RHEL/CentOS/Rocky/Alma
install_nginx_rhel() {
    echo -e "${CYAN}Installing Nginx on RHEL-based system...${NC}"
    
    # Install EPEL repository if not present
    if ! rpm -q epel-release &> /dev/null; then
        if command -v dnf &> /dev/null; then
            dnf install -y epel-release
        else
            yum install -y epel-release
        fi
    fi
    
    # Install Nginx
    if command -v dnf &> /dev/null; then
        dnf install -y nginx
    else
        yum install -y nginx
    fi
    
    systemctl enable nginx
    systemctl start nginx
    
    # Configure firewall if available
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    fi
    
    echo -e "${GREEN}Nginx installed successfully${NC}"
}

# Main installation process
case $OS in
    ubuntu|debian)
        install_nginx_debian
        ;;
    rhel|centos|rocky|almalinux|fedora)
        install_nginx_rhel
        ;;
    *)
        echo -e "${RED}Unsupported operating system: $OS${NC}"
        exit 1
        ;;
esac

# Display status
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Nginx Installation Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${CYAN}Service Status:${NC} $(systemctl is-active nginx)"
echo -e "${CYAN}Configuration:${NC} /etc/nginx/"

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    echo -e "${CYAN}Document Root:${NC} /var/www/html"
else
    echo -e "${CYAN}Document Root:${NC} /usr/share/nginx/html"
fi

echo -e "${CYAN}Service Control:${NC} systemctl {start|stop|restart|status} nginx"
echo ""
echo -e "${CYAN}Access your server:${NC} http://$(hostname -I | awk '{print $1}')"
echo ""
