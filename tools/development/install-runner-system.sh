#!/bin/bash

# GitHub Actions Runner System Installer
# Sets up the complete runner management system

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This installation script must be run as root"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    log "Installing system dependencies..."
    
    # Detect package manager
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y wget curl tar systemd
    elif command -v yum &> /dev/null; then
        yum install -y wget curl tar systemd
    elif command -v pacman &> /dev/null; then
        pacman -Sy --noconfirm wget curl tar systemd
    else
        warning "Could not detect package manager. Please ensure wget, curl, tar, and systemd are installed."
    fi
}

# Install Docker (optional but recommended)
install_docker() {
    if command -v docker &> /dev/null; then
        info "Docker is already installed"
        return 0
    fi
    
    log "Installing Docker..."
    
    # Install Docker using the official script
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    log "Docker installed successfully"
}

# Set up the runner management system
setup_system() {
    log "Setting up GitHub Actions Runner Management System..."
    
    # Create system directories
    local install_dir="/opt/linux-toolbox/tools/development"
    mkdir -p "$install_dir"
    
    # Copy scripts to system location
    local script_dir="$(dirname "$(realpath "$0")")"
    
    if [[ -f "$script_dir/github-runner-manager.sh" ]]; then
        cp "$script_dir/github-runner-manager.sh" "$install_dir/"
        chmod +x "$install_dir/github-runner-manager.sh"
    else
        error "github-runner-manager.sh not found in script directory"
        exit 1
    fi
    
    if [[ -f "$script_dir/runner-helper.sh" ]]; then
        cp "$script_dir/runner-helper.sh" "$install_dir/"
        chmod +x "$install_dir/runner-helper.sh"
        
        # Update the manager script path in helper
        sed -i "s|/opt/linux-toolbox/tools/development/github-runner-manager.sh|$install_dir/github-runner-manager.sh|g" "$install_dir/runner-helper.sh"
    else
        error "runner-helper.sh not found in script directory"
        exit 1
    fi
    
    # Create symlinks for easy access
    ln -sf "$install_dir/github-runner-manager.sh" /usr/local/bin/github-runner-manager
    ln -sf "$install_dir/runner-helper.sh" /usr/local/bin/runner-helper
    
    # Initialize the system
    "$install_dir/github-runner-manager.sh" init
    
    log "System setup completed"
}

# Create useful aliases and functions
create_aliases() {
    log "Creating useful aliases..."
    
    cat > /etc/profile.d/github-runners.sh << 'EOF'
# GitHub Actions Runner aliases
alias gr='runner-helper'
alias grl='runner-helper list'
alias grs='runner-helper status'
alias grm='runner-helper monitor'

# Quick functions
gra() {
    if [[ $# -eq 4 ]]; then
        sudo github-runner-manager add "$1" "$2" "$3" "$4"
    else
        runner-helper add
    fi
}

grr() {
    if [[ $# -eq 1 ]]; then
        sudo github-runner-manager remove "$1"
    else
        runner-helper remove
    fi
}

grlogs() {
    runner-helper logs "$1"
}
EOF
    
    chmod +x /etc/profile.d/github-runners.sh
    
    info "Aliases created. Restart your shell or run 'source /etc/profile.d/github-runners.sh' to use them"
}

# Create a systemd service to auto-start all runners on boot
create_startup_service() {
    log "Creating startup service for automatic runner management..."
    
    cat > /etc/systemd/system/github-runners-startup.service << EOF
[Unit]
Description=GitHub Actions Runners Startup Service
After=network.target docker.service
Wants=docker.service

[Service]
Type=oneshot
ExecStart=/opt/linux-toolbox/tools/development/github-runner-manager.sh start
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable github-runners-startup.service
    
    log "Startup service created and enabled"
}

# Show installation summary
show_summary() {
    echo
    echo "================================================================"
    echo "    GitHub Actions Runner Management System Installed!"
    echo "================================================================"
    echo
    echo "Available commands:"
    echo "  runner-helper          - Interactive helper for common tasks"
    echo "  github-runner-manager  - Full-featured management script"
    echo
    echo "Quick commands (after restarting shell):"
    echo "  gr                     - Runner helper shortcut"
    echo "  grl                    - List runners"
    echo "  grs                    - System status"
    echo "  grm                    - Monitor runners"
    echo "  gra <owner> <repo> <name> <token>  - Add runner"
    echo "  grr <runner_id>        - Remove runner"
    echo "  grlogs <runner_id>     - View runner logs"
    echo
    echo "Getting started:"
    echo "1. Add your first runner: runner-helper add"
    echo "2. Monitor runners: runner-helper monitor"
    echo "3. View system status: runner-helper status"
    echo
    echo "Configuration files:"
    echo "  Runners directory: /opt/actions-runners/"
    echo "  Config file: /etc/github-runners.conf"
    echo "  Scripts location: /opt/linux-toolbox/tools/development/"
    echo
    echo "For help: runner-helper help"
    echo "================================================================"
}

# Main installation function
main() {
    echo "================================================================"
    echo "   GitHub Actions Runner Management System Installer"
    echo "================================================================"
    echo
    
    check_root
    
    read -p "Install Docker? (recommended) [Y/n]: " install_docker_choice
    
    install_dependencies
    
    if [[ ! "$install_docker_choice" =~ ^[Nn]$ ]]; then
        install_docker
    fi
    
    setup_system
    create_aliases
    create_startup_service
    
    show_summary
}

# Handle command line arguments
case "$1" in
    --no-docker)
        echo "Skipping Docker installation..."
        check_root
        install_dependencies
        setup_system
        create_aliases
        create_startup_service
        show_summary
        ;;
    --help|-h)
        echo "GitHub Actions Runner System Installer"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --no-docker    Skip Docker installation"
        echo "  --help         Show this help"
        echo
        exit 0
        ;;
    *)
        main
        ;;
esac