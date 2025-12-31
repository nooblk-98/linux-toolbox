#!/bin/bash
# Simple Apache installation

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

echo -e "${GREEN}=== Simple Apache Installation ===${NC}\n"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

# Function to install Apache on Debian/Ubuntu
install_apache_debian() {
    echo -e "${CYAN}Installing Apache on Debian/Ubuntu...${NC}"
    
    apt update
    apt install -y apache2
    
    systemctl enable apache2
    systemctl start apache2
    
    echo -e "${GREEN}Apache installed successfully${NC}"
}

# Function to install Apache on RHEL/CentOS/Rocky/Alma
install_apache_rhel() {
    echo -e "${CYAN}Installing Apache on RHEL-based system...${NC}"
    
    if command -v dnf &> /dev/null; then
        dnf install -y httpd
    else
        yum install -y httpd
    fi
    
    systemctl enable httpd
    systemctl start httpd
    
    # Configure firewall if available
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    fi
    
    echo -e "${GREEN}Apache installed successfully${NC}"
}

# Main installation process
case $OS in
    ubuntu|debian)
        install_apache_debian
        ;;
    rhel|centos|rocky|almalinux|fedora)
        install_apache_rhel
        ;;
    *)
        echo -e "${RED}Unsupported operating system: $OS${NC}"
        exit 1
        ;;
esac

# Display status
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Apache Installation Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    echo -e "${CYAN}Service Status:${NC} $(systemctl is-active apache2)"
    echo -e "${CYAN}Configuration:${NC} /etc/apache2/"
    echo -e "${CYAN}Document Root:${NC} /var/www/html"
    echo -e "${CYAN}Service Control:${NC} systemctl {start|stop|restart|status} apache2"
else
    echo -e "${CYAN}Service Status:${NC} $(systemctl is-active httpd)"
    echo -e "${CYAN}Configuration:${NC} /etc/httpd/"
    echo -e "${CYAN}Document Root:${NC} /var/www/html"
    echo -e "${CYAN}Service Control:${NC} systemctl {start|stop|restart|status} httpd"
fi

echo ""
echo -e "${CYAN}Access your server:${NC} http://$(hostname -I | awk '{print $1}')"
echo ""
