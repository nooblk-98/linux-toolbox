#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Certbot Installer${NC}"
echo -e "${YELLOW}Detecting system and web server...${NC}"

# Detect package manager
PM=""
if command -v apt-get >/dev/null 2>&1; then
    PM="apt"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
fi

# Detect web server
HAS_NGINX=0
HAS_APACHE=0
if command -v nginx >/dev/null 2>&1; then HAS_NGINX=1; fi
if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then HAS_APACHE=1; fi

echo -e "${GREEN}Package manager:${NC} ${PM:-unknown}"
[[ $HAS_NGINX -eq 1 ]] && echo -e "${GREEN}Detected: nginx${NC}"
[[ $HAS_APACHE -eq 1 ]] && echo -e "${GREEN}Detected: apache${NC}"

install_via_packages() {
    case "$PM" in
        apt)
            sudo apt-get update
            sudo apt-get install -y software-properties-common
            # Try distro package first
            if apt-cache show certbot >/dev/null 2>&1; then
                sudo apt-get install -y certbot
            fi
            ;;
        dnf)
            sudo dnf makecache
            if sudo dnf list certbot >/dev/null 2>&1; then
                sudo dnf install -y certbot
            fi
            ;;
        yum)
            sudo yum makecache
            if sudo yum list certbot >/dev/null 2>&1; then
                sudo yum install -y certbot
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

install_snap_certbot() {
    echo -e "${YELLOW}Attempting snapd install (fallback)...${NC}"
    # Install snapd if missing
    if ! command -v snap >/dev/null 2>&1; then
        case "$PM" in
            apt)
                sudo apt-get update
                sudo apt-get install -y snapd
                ;;
            dnf|yum)
                sudo "$PM" install -y snapd
                ;;
            *)
                echo -e "${RED}No known package manager to install snapd. Please install snapd manually.${NC}"
                return 1
                ;;
        esac
    fi
    sudo systemctl enable --now snapd.socket 2>/dev/null || true
    # Ensure classic support
    if [ -d /var/lib/snapd/snap ]; then
        sudo ln -s /var/lib/snapd/snap /snap 2>/dev/null || true
    fi
    sudo snap install core --classic
    sudo snap refresh core
    sudo snap install --classic certbot
    # ensure certbot in PATH
    if [ -x /snap/bin/certbot ] && [ ! -x "$(command -v certbot || true)" ]; then
        sudo ln -sf /snap/bin/certbot /usr/local/bin/certbot 2>/dev/null || true
    fi
}

install_plugin_packages() {
    # Install nginx/apache plugin when detected
    if [ "$HAS_NGINX" -eq 1 ]; then
        echo -e "${YELLOW}Installing certbot nginx plugin...${NC}"
        if [ "$PM" = "apt" ]; then
            sudo apt-get install -y python3-certbot-nginx || sudo apt-get install -y certbot-nginx || true
        elif [ "$PM" = "dnf" ] || [ "$PM" = "yum" ]; then
            sudo "$PM" install -y python3-certbot-nginx certbot-nginx || true
        else
            # If using snap, plugin works via --nginx when snap certbot installed
            true
        fi
    fi

    if [ "$HAS_APACHE" -eq 1 ]; then
        echo -e "${YELLOW}Installing certbot apache plugin...${NC}"
        if [ "$PM" = "apt" ]; then
            sudo apt-get install -y python3-certbot-apache || sudo apt-get install -y certbot-apache || true
        elif [ "$PM" = "dnf" ] || [ "$PM" = "yum" ]; then
            sudo "$PM" install -y python3-certbot-apache certbot-apache || true
        else
            true
        fi
    fi
}

# Main install flow
if command -v certbot >/dev/null 2>&1; then
    echo -e "${GREEN}Certbot already installed: $(certbot --version 2>/dev/null)${NC}"
else
    echo -e "${YELLOW}Trying to install Certbot via native packages...${NC}"
    if install_via_packages; then
        if command -v certbot >/dev/null 2>&1; then
            echo -e "${GREEN}Certbot installed via packages.${NC}"
        else
            echo -e "${YELLOW}Native package install did not provide certbot. Falling back to snap...${NC}"
            install_snap_certbot
        fi
    else
        install_snap_certbot
    fi
fi

# Install plugins if webserver present
install_plugin_packages

# Final verification
if command -v certbot >/dev/null 2>&1; then
    echo -e "${GREEN}Certbot installation successful:${NC} $(certbot --version 2>/dev/null || true)"
    echo -e "${BLUE}You can now run:${NC} certbot --help"
    if [ "$HAS_NGINX" -eq 1 ]; then
        echo -e "${BLUE}To obtain and install a certificate (nginx):${NC} sudo certbot --nginx -d example.com"
    elif [ "$HAS_APACHE" -eq 1 ]; then
        echo -e "${BLUE}To obtain and install a certificate (apache):${NC} sudo certbot --apache -d example.com"
    else
        echo -e "${BLUE}To obtain a certificate using standalone or webroot: see certbot docs.${NC}"
    fi
else
    echo -e "${RED}Certbot installation failed. Please inspect errors above and install manually.${NC}"
    exit 1
fi

read -p "Press Enter to continue..."
