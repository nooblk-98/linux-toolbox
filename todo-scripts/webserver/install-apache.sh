#!/bin/bash
# Apache installation and basic configuration

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

echo -e "${GREEN}=== Apache Installation & Configuration ===${NC}\n"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

# Function to install Apache on Debian/Ubuntu
install_apache_debian() {
    echo -e "${CYAN}Installing Apache on Debian/Ubuntu...${NC}"
    
    apt update
    apt install -y apache2
    
    # Enable Apache service
    systemctl enable apache2
    systemctl start apache2
    
    # Enable essential modules
    a2enmod rewrite
    a2enmod ssl
    a2enmod headers
    a2enmod expires
    a2enmod proxy
    a2enmod proxy_http
    
    # Restart to apply changes
    systemctl restart apache2
    
    echo -e "${GREEN}Apache installed successfully on Debian/Ubuntu${NC}"
}

# Function to install Apache on RHEL/CentOS/Rocky/Alma
install_apache_rhel() {
    echo -e "${CYAN}Installing Apache on RHEL-based system...${NC}"
    
    if command -v dnf &> /dev/null; then
        dnf install -y httpd mod_ssl
    else
        yum install -y httpd mod_ssl
    fi
    
    # Enable and start Apache
    systemctl enable httpd
    systemctl start httpd
    
    # Configure firewall
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    fi
    
    echo -e "${GREEN}Apache installed successfully on RHEL-based system${NC}"
}

# Function to configure basic security
configure_security() {
    echo -e "${CYAN}Configuring basic security...${NC}"
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        CONF_DIR="/etc/apache2/conf-available"
        CONF_FILE="$CONF_DIR/security.conf"
        
        # Update security configuration
        cat > "$CONF_FILE" << 'EOF'
# Hide Apache version
ServerTokens Prod
ServerSignature Off

# Disable directory listing
<Directory />
    Options -Indexes
</Directory>

# Prevent clickjacking
Header always set X-Frame-Options "SAMEORIGIN"

# XSS Protection
Header always set X-XSS-Protection "1; mode=block"

# Prevent MIME sniffing
Header always set X-Content-Type-Options "nosniff"

# Enable HSTS
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
EOF
        
        a2enconf security
        
    else
        CONF_FILE="/etc/httpd/conf.d/security.conf"
        
        cat > "$CONF_FILE" << 'EOF'
# Hide Apache version
ServerTokens Prod
ServerSignature Off

# Disable directory listing
<Directory />
    Options -Indexes
</Directory>

# Prevent clickjacking
Header always set X-Frame-Options "SAMEORIGIN"

# XSS Protection
Header always set X-XSS-Protection "1; mode=block"

# Prevent MIME sniffing
Header always set X-Content-Type-Options "nosniff"

# Enable HSTS
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
EOF
    fi
    
    echo -e "${GREEN}Security configuration applied${NC}"
}

# Function to create default virtual host
create_default_vhost() {
    echo -e "${CYAN}Creating default virtual host...${NC}"
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        VHOST_DIR="/etc/apache2/sites-available"
        WEB_ROOT="/var/www/html"
        
        cat > "$VHOST_DIR/000-default.conf" << 'EOF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    
    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
        
    else
        VHOST_DIR="/etc/httpd/conf.d"
        WEB_ROOT="/var/www/html"
        
        cat > "$VHOST_DIR/000-default.conf" << 'EOF'
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    
    ErrorLog logs/error.log
    CustomLog logs/access.log combined
    
    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
    fi
    
    # Create index page
    cat > "$WEB_ROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Apache Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            text-align: center;
        }
        h1 { color: #d42;
        }
    </style>
</head>
<body>
    <h1>Apache Web Server is Running!</h1>
    <p>Your Apache web server has been successfully installed and configured.</p>
    <p>Replace this file with your own content.</p>
</body>
</html>
EOF
    
    echo -e "${GREEN}Default virtual host created${NC}"
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

# Configure security
configure_security

# Create default virtual host
create_default_vhost

# Restart Apache to apply all changes
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    systemctl restart apache2
    SERVICE_STATUS=$(systemctl is-active apache2)
else
    systemctl restart httpd
    SERVICE_STATUS=$(systemctl is-active httpd)
fi

# Display status
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Apache Installation Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${CYAN}Service Status:${NC} $SERVICE_STATUS"

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    echo -e "${CYAN}Configuration:${NC} /etc/apache2/"
    echo -e "${CYAN}Document Root:${NC} /var/www/html"
    echo -e "${CYAN}Service Control:${NC} systemctl {start|stop|restart|status} apache2"
else
    echo -e "${CYAN}Configuration:${NC} /etc/httpd/"
    echo -e "${CYAN}Document Root:${NC} /var/www/html"
    echo -e "${CYAN}Service Control:${NC} systemctl {start|stop|restart|status} httpd"
fi

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Configure your firewall to allow HTTP (80) and HTTPS (443)"
echo "2. Set up SSL certificates using certbot or your preferred method"
echo "3. Create virtual hosts for your websites"
echo "4. Configure additional modules as needed"
echo ""
echo -e "${CYAN}Access your server:${NC} http://$(hostname -I | awk '{print $1}')"
echo ""
