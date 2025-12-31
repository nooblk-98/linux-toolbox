#!/bin/bash
# Nginx installation and basic configuration

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

echo -e "${GREEN}=== Nginx Installation & Configuration ===${NC}\n"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo -e "${RED}Cannot detect OS${NC}"
    exit 1
fi

# Function to install Nginx on Debian/Ubuntu
install_nginx_debian() {
    echo -e "${CYAN}Installing Nginx on Debian/Ubuntu...${NC}"
    
    apt update
    apt install -y nginx
    
    # Enable Nginx service
    systemctl enable nginx
    systemctl start nginx
    
    echo -e "${GREEN}Nginx installed successfully on Debian/Ubuntu${NC}"
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
    
    # Enable and start Nginx
    systemctl enable nginx
    systemctl start nginx
    
    # Configure firewall
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    fi
    
    # SELinux configuration
    if command -v setenforce &> /dev/null; then
        setsebool -P httpd_can_network_connect 1
    fi
    
    echo -e "${GREEN}Nginx installed successfully on RHEL-based system${NC}"
}

# Function to configure basic security
configure_security() {
    echo -e "${CYAN}Configuring basic security...${NC}"
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        CONF_DIR="/etc/nginx"
    else
        CONF_DIR="/etc/nginx"
    fi
    
    # Create security configuration
    cat > "$CONF_DIR/conf.d/security.conf" << 'EOF'
# Hide Nginx version
server_tokens off;

# Buffer overflow protection
client_body_buffer_size 1k;
client_header_buffer_size 1k;
client_max_body_size 10m;
large_client_header_buffers 2 1k;

# Timeouts
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 15;
send_timeout 10;
EOF
    
    echo -e "${GREEN}Security configuration applied${NC}"
}

# Function to create optimized nginx.conf
configure_nginx() {
    echo -e "${CYAN}Configuring Nginx...${NC}"
    
    # Backup original configuration
    if [ -f /etc/nginx/nginx.conf ]; then
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    fi
    
    # Create optimized configuration
    cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;
    gzip_disable "msie6";

    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
EOF
    
    # Adjust user for Debian/Ubuntu
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sed -i 's/user nginx;/user www-data;/' /etc/nginx/nginx.conf
    fi
    
    echo -e "${GREEN}Nginx configuration optimized${NC}"
}

# Function to create default server block
create_default_server() {
    echo -e "${CYAN}Creating default server block...${NC}"
    
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        SITES_DIR="/etc/nginx/sites-available"
        ENABLED_DIR="/etc/nginx/sites-enabled"
        WEB_ROOT="/var/www/html"
        
        mkdir -p "$SITES_DIR" "$ENABLED_DIR"
        
        cat > "$SITES_DIR/default" << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    location / {
        try_files $uri $uri/ =404;
        
        # Limit request methods
        if ($request_method !~ ^(GET|HEAD|POST)$ ) {
            return 405;
        }
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Access and error logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF
        
        # Enable site
        ln -sf "$SITES_DIR/default" "$ENABLED_DIR/default"
        
    else
        CONF_DIR="/etc/nginx/conf.d"
        WEB_ROOT="/usr/share/nginx/html"
        
        cat > "$CONF_DIR/default.conf" << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    server_name _;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    
    location / {
        try_files $uri $uri/ =404;
        
        # Limit request methods
        if ($request_method !~ ^(GET|HEAD|POST)$ ) {
            return 405;
        }
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
    
    # Access and error logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
}
EOF
    fi
    
    # Create index page
    cat > "$WEB_ROOT/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Nginx Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            text-align: center;
        }
        h1 {
            color: #009639;
        }
    </style>
</head>
<body>
    <h1>Nginx Web Server is Running!</h1>
    <p>Your Nginx web server has been successfully installed and configured.</p>
    <p>Replace this file with your own content.</p>
</body>
</html>
EOF
    
    echo -e "${GREEN}Default server block created${NC}"
}

# Function to test and reload configuration
test_and_reload() {
    echo -e "${CYAN}Testing Nginx configuration...${NC}"
    
    if nginx -t; then
        echo -e "${GREEN}Configuration test passed${NC}"
        systemctl reload nginx
    else
        echo -e "${RED}Configuration test failed!${NC}"
        return 1
    fi
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

# Configure Nginx
configure_nginx

# Configure security
configure_security

# Create default server block
create_default_server

# Test and reload
test_and_reload

# Get service status
SERVICE_STATUS=$(systemctl is-active nginx)

# Display status
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Nginx Installation Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${CYAN}Service Status:${NC} $SERVICE_STATUS"
echo -e "${CYAN}Configuration:${NC} /etc/nginx/"

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    echo -e "${CYAN}Document Root:${NC} /var/www/html"
    echo -e "${CYAN}Sites Available:${NC} /etc/nginx/sites-available/"
    echo -e "${CYAN}Sites Enabled:${NC} /etc/nginx/sites-enabled/"
else
    echo -e "${CYAN}Document Root:${NC} /usr/share/nginx/html"
    echo -e "${CYAN}Config Directory:${NC} /etc/nginx/conf.d/"
fi

echo -e "${CYAN}Service Control:${NC} systemctl {start|stop|restart|reload|status} nginx"

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Configure your firewall to allow HTTP (80) and HTTPS (443)"
echo "2. Set up SSL certificates using certbot or your preferred method"
echo "3. Create server blocks for your websites"
echo "4. Optimize configuration based on your needs"
echo ""
echo -e "${CYAN}Useful Commands:${NC}"
echo "  - Test config: nginx -t"
echo "  - Reload config: systemctl reload nginx"
echo "  - View logs: tail -f /var/log/nginx/error.log"
echo ""
echo -e "${CYAN}Access your server:${NC} http://$(hostname -I | awk '{print $1}')"
echo ""
