#!/bin/bash

# Node.js Installation Script with NVM Support
# This script installs Node.js using NVM (Node Version Manager) for easy version management

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Node.js Installation with NVM       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}⚠ Warning: Running as root. NVM should be installed for regular users.${NC}"
    read -p "Continue anyway? (y/n): " continue_root
    if [[ ! "$continue_root" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Function to install NVM
install_nvm() {
    echo -e "${CYAN}📦 Installing NVM (Node Version Manager)...${NC}"
    
    # Download and install NVM
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Add to shell profile if not already present
    if ! grep -q "NVM_DIR" ~/.bashrc 2>/dev/null; then
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
    fi
    
    if [ -f ~/.zshrc ]; then
        if ! grep -q "NVM_DIR" ~/.zshrc; then
            echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.zshrc
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.zshrc
        fi
    fi
    
    echo -e "${GREEN}✓ NVM installed successfully${NC}"
}

# Function to install Node.js via NVM
install_nodejs_nvm() {
    local version=$1
    
    echo -e "${CYAN}📦 Installing Node.js $version via NVM...${NC}"
    
    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    nvm install "$version"
    nvm use "$version"
    nvm alias default "$version"
    
    echo -e "${GREEN}✓ Node.js $version installed${NC}"
}

# Function to install Node.js via package manager
install_nodejs_apt() {
    local version=$1
    
    echo -e "${CYAN}📦 Installing Node.js $version via NodeSource repository...${NC}"
    
    # Install dependencies
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    
    # Add NodeSource repository
    curl -fsSL "https://deb.nodesource.com/setup_${version}.x" | sudo -E bash -
    
    # Install Node.js
    sudo apt-get install -y nodejs
    
    echo -e "${GREEN}✓ Node.js installed${NC}"
}

# Check if NVM is already installed
if command -v nvm &> /dev/null || [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo -e "${GREEN}✓ NVM is already installed${NC}"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    NVM_INSTALLED=true
else
    NVM_INSTALLED=false
fi

# Check if Node.js is already installed
if command -v node &> /dev/null; then
    CURRENT_VERSION=$(node --version)
    echo -e "${YELLOW}⚠ Node.js is already installed: $CURRENT_VERSION${NC}"
    echo ""
fi

# Installation method selection
echo -e "${YELLOW}Select installation method:${NC}"
echo "1. Install via NVM (Recommended - allows multiple versions)"
echo "2. Install via package manager (System-wide installation)"
echo "3. Exit"
echo ""
read -p "Enter your choice (1-3): " install_method

case $install_method in
    1)
        # NVM installation
        if [ "$NVM_INSTALLED" = false ]; then
            install_nvm
            # Reload NVM
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        fi
        
        echo ""
        echo -e "${YELLOW}Select Node.js version:${NC}"
        echo "1. LTS (Long Term Support) - Recommended"
        echo "2. Current (Latest features)"
        echo "3. Specific version (e.g., 18.17.0)"
        echo ""
        read -p "Enter your choice (1-3): " version_choice
        
        case $version_choice in
            1)
                install_nodejs_nvm "lts/*"
                ;;
            2)
                install_nodejs_nvm "node"
                ;;
            3)
                read -p "Enter Node.js version (e.g., 18.17.0): " custom_version
                install_nodejs_nvm "$custom_version"
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                exit 1
                ;;
        esac
        ;;
        
    2)
        # Package manager installation
        if ! command -v apt-get &> /dev/null; then
            echo -e "${RED}✗ This script currently supports Debian/Ubuntu systems only${NC}"
            exit 1
        fi
        
        echo ""
        echo -e "${YELLOW}Select Node.js version:${NC}"
        echo "1. Node.js 20.x (Current LTS)"
        echo "2. Node.js 18.x (LTS)"
        echo "3. Node.js 16.x (Maintenance LTS)"
        echo ""
        read -p "Enter your choice (1-3): " version_choice
        
        case $version_choice in
            1)
                install_nodejs_apt "20"
                ;;
            2)
                install_nodejs_apt "18"
                ;;
            3)
                install_nodejs_apt "16"
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                exit 1
                ;;
        esac
        ;;
        
    3)
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
        ;;
        
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# Verify installation
echo ""
echo -e "${CYAN}Verifying installation...${NC}"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    NPM_VERSION=$(npm --version)
    
    echo -e "${GREEN}✓ Node.js installed successfully${NC}"
    echo -e "  Node.js version: ${CYAN}$NODE_VERSION${NC}"
    echo -e "  npm version: ${CYAN}$NPM_VERSION${NC}"
    
    # Show NVM info if installed via NVM
    if [ "$install_method" = "1" ]; then
        echo ""
        echo -e "${YELLOW}NVM Commands:${NC}"
        echo "  nvm install <version>  - Install a Node.js version"
        echo "  nvm use <version>      - Use a specific version"
        echo "  nvm ls                 - List installed versions"
        echo "  nvm ls-remote          - List available versions"
        echo "  nvm alias default <v>  - Set default version"
    fi
else
    echo -e "${RED}✗ Installation failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Installation Complete!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

# Prompt to install global packages
echo ""
read -p "Do you want to install common global packages? (y/n): " install_globals

if [[ "$install_globals" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Installing common global packages...${NC}"
    npm install -g yarn pnpm pm2 nodemon typescript ts-node
    echo -e "${GREEN}✓ Global packages installed${NC}"
fi

echo ""
read -p "Press Enter to continue..."