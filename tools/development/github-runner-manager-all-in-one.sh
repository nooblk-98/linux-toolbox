#!/bin/bash

# GitHub Actions Multi-Runner Management System
# Complete solution for managing multiple self-hosted GitHub Actions runners
# Author: Linux Toolbox
# Version: 1.0

# Configuration
RUNNERS_BASE_DIR="/opt/actions-runners"
SERVICES_DIR="/etc/systemd/system"
CONFIG_FILE="/etc/github-runners.conf"
RUNNER_VERSION="2.329.0"  # updated to a newer runner version
RUNNER_USER="github-runner"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Status icons
RUNNING_ICON="🟢"
STOPPED_ICON="🔴"
WARNING_ICON="⚠️"
INFO_ICON="ℹ️"

# Logging functions
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
        error "This operation requires root privileges. Please run with sudo."
        exit 1
    fi
}

# Create github-runner user if it doesn't exist
create_runner_user() {
    if ! id "$RUNNER_USER" &>/dev/null; then
        log "Creating $RUNNER_USER user..."
        useradd -r -s /bin/bash -d /home/$RUNNER_USER -m $RUNNER_USER
        usermod -aG docker $RUNNER_USER 2>/dev/null || true
    fi
}

# Install system dependencies
install_dependencies() {
    log "Installing system dependencies..."
    
    # Detect package manager and install dependencies
    if command -v apt-get &> /dev/null; then
        apt-get update
        apt-get install -y wget curl tar systemd jq
    elif command -v yum &> /dev/null; then
        yum install -y wget curl tar systemd jq
    elif command -v pacman &> /dev/null; then
        pacman -Sy --noconfirm wget curl tar systemd jq
    else
        warning "Could not detect package manager. Please ensure wget, curl, tar, systemd, and jq are installed."
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

# Initialize the runner management system
init_system() {
    log "Initializing GitHub Actions Runner Manager..."
    
    # Create base directories
    mkdir -p "$RUNNERS_BASE_DIR"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Create runner user
    create_runner_user
    
    # Set permissions
    chown -R $RUNNER_USER:$RUNNER_USER "$RUNNERS_BASE_DIR"
    
    # Create config file if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        touch "$CONFIG_FILE"
        chown $RUNNER_USER:$RUNNER_USER "$CONFIG_FILE"
    fi
    
    # Create startup service
    create_startup_service
    
    log "System initialized successfully"
}

# Download and extract GitHub Actions runner
download_runner() {
    local runner_dir="$1"
    
    log "Downloading GitHub Actions runner v$RUNNER_VERSION..."
    
    cd "$runner_dir"
    
    # Download the runner
    wget -q "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
    
    if [[ $? -ne 0 ]]; then
        error "Failed to download runner"
        return 1
    fi
    
    # Extract the runner
    tar xzf "actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
    rm "actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
    
    # Set permissions
    chown -R $RUNNER_USER:$RUNNER_USER "$runner_dir"
    
    return 0
}

# Create systemd service for a runner
create_service() {
    local runner_id="$1"
    local runner_dir="$2"
    local service_file="$SERVICES_DIR/github-runner-$runner_id.service"
    
    log "Creating systemd service for $runner_id..."
    
    cat > "$service_file" << EOF
[Unit]
Description=GitHub Actions Runner ($runner_id)
After=network.target

[Service]
Type=simple
User=$RUNNER_USER
WorkingDirectory=$runner_dir
ExecStart=$runner_dir/run.sh
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
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
ExecStart=$0 start-all
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable github-runners-startup.service
}

# helper: parse owner/repo or full url into owner and repo
parse_repo_input() {
    local input="$1"
    REPO_OWNER=""
    REPO_NAME=""
    # trim
    input="$(echo "$input" | xargs)"
    if [[ "$input" =~ ^https?:// ]]; then
        # URL like https://github.com/owner/repo or https://github.com/owner
        # remove trailing slash
        input="${input%/}"
        # extract path part
        path="${input#*github.com/}"
        REPO_OWNER="$(echo "$path" | cut -d'/' -f1)"
        REPO_NAME="$(echo "$path" | cut -d'/' -f2)"
        # if there's no second part REPO_NAME will be empty -> org-level URL
        if [[ "$REPO_NAME" == "$REPO_OWNER" ]]; then
            REPO_NAME=""
        fi
    elif [[ "$input" =~ / ]]; then
        REPO_OWNER="$(echo "$input" | cut -d'/' -f1)"
        REPO_NAME="$(echo "$input" | cut -d'/' -f2)"
    else
        REPO_OWNER="$input"
        REPO_NAME=""
    fi
}

# Add a new runner (improved input handling)
add_runner() {
    local a1="$1"; local a2="$2"; local a3="$3"; local a4="$4"; local a5="$5"; local a6="$6"
    local repo_owner repo_name runner_name token target_url repo_path_for_config

    # CLI: add --url <url> --token <token>  OR add <owner> <repo> <name> <token>
    if [[ "$a1" == "--url" ]]; then
        parse_repo_input "$a2"
        # support form: add --url <url> --token <token>   OR add --url <url> <token>
        if [[ "$a3" == "--token" && -n "$a4" ]]; then
            token="$a4"
        else
            token="$a3"
        fi
        runner_name="runner-$(date +%s)"
        repo_owner="$REPO_OWNER"
        repo_name="$REPO_NAME"
    else
        # normal form: owner repo name token
        repo_owner="$a1"; repo_name="$a2"; runner_name="$a3"; token="$a4"
    fi

    # if interactive call passed URL in a1 (not using --url flag)
    if [[ -z "$repo_name" && "$repo_owner" =~ ^https?:// ]]; then
        parse_repo_input "$repo_owner"
        repo_owner="$REPO_OWNER"
        repo_name="$REPO_NAME"
    fi

    # Build proper target URL and repo_path_for_config (org vs repo)
    if [[ -z "$repo_name" ]]; then
        # Org or owner-level runner
        target_url="https://github.com/$repo_owner"
        repo_path_for_config="$repo_owner"
    else
        target_url="https://github.com/$repo_owner/$repo_name"
        repo_path_for_config="$repo_owner/$repo_name"
    fi

    if [[ -z "$repo_owner" || -z "$token" ]]; then
        error "Usage: $0 add <owner> <repo> <name> <registration_token>"
        error "Or:   $0 add --url <repo/org url> --token <registration_token>"
        return 1
    fi

    # auto-generate runner_name if empty
    if [[ -z "$runner_name" ]]; then
        runner_name="runner-$(date +%s)"
    fi

    # generate safe runner id (replace '/' with '-' and use 'org' when no repo)
    local safe_repo="${repo_path_for_config//\//-}"
    local runner_id="${safe_repo}-${runner_name}"
    local runner_dir="$RUNNERS_BASE_DIR/$runner_id"

    # Check if runner already exists
    if [[ -d "$runner_dir" ]]; then
        error "Runner $runner_id already exists"
        return 1
    fi
    
    log "Adding runner: $runner_id (target: $target_url)"
    
    # Create runner directory
    mkdir -p "$runner_dir"
    
    # Download and extract runner
    if ! download_runner "$runner_dir"; then
        rm -rf "$runner_dir"
        return 1
    fi
    
    # Configure the runner (use the appropriate URL for org or repo)
    log "Configuring runner..."
    cd "$runner_dir"
    
    sudo -u $RUNNER_USER ./config.sh \
        --url "$target_url" \
        --token "$token" \
        --name "$runner_name" \
        --labels "self-hosted,linux,x64" \
        --work "_work" \
        --unattended \
        --replace
    
    if [[ $? -ne 0 ]]; then
        error "Failed to configure runner"
        rm -rf "$runner_dir"
        return 1
    fi
    
    # Create systemd service
    create_service "$runner_id" "$runner_dir"
    
    # Add to config file (record repo_path_for_config so org or repo recorded properly)
    echo "$runner_id:$repo_path_for_config:$runner_name:$(date)" >> "$CONFIG_FILE"
    
    # Start the service
    systemctl enable "github-runner-$runner_id.service"
    systemctl start "github-runner-$runner_id.service"
    
    log "Runner $runner_id added and started successfully"
}

# Interactive add runner (accept owner/repo OR full URL)
interactive_add() {
    echo "=== Add GitHub Actions Runner (URL + TOKEN only) ==="
    echo
    # Ask only for the two values GitHub provides in the config command
    read -p "Enter GitHub URL (e.g. https://github.com/NoobLk or https://github.com/owner/repo): " repo_input
    read -p "Enter registration token (the --token value): " token

    # Basic validation
    if [[ -z "$repo_input" || -z "$token" ]]; then
        error "Both URL and token are required."
        return 1
    fi

    info "Adding runner for: $repo_input (token provided)"
    # Use add_runner in --url <url> <token> form
    add_runner --url "$repo_input" --token "$token"
}

# Remove a runner
remove_runner() {
    local runner_id="$1"
    local token="$2"
    
    if [[ -z "$runner_id" ]]; then
        error "Usage: $0 remove <runner_id> [removal_token]"
        return 1
    fi
    
    local runner_dir="$RUNNERS_BASE_DIR/$runner_id"
    
    if [[ ! -d "$runner_dir" ]]; then
        error "Runner $runner_id not found"
        return 1
    fi
    
    log "Removing runner: $runner_id"
    
    # Stop and disable service
    systemctl stop "github-runner-$runner_id.service" 2>/dev/null || true
    systemctl disable "github-runner-$runner_id.service" 2>/dev/null || true
    rm -f "$SERVICES_DIR/github-runner-$runner_id.service"
    systemctl daemon-reload
    
    # Remove runner from GitHub if token provided
    if [[ -n "$token" ]]; then
        log "Unregistering runner from GitHub..."
        cd "$runner_dir"
        sudo -u $RUNNER_USER ./config.sh remove --token "$token" || warning "Failed to unregister from GitHub"
    fi
    
    # Remove runner directory
    rm -rf "$runner_dir"
    
    # Remove from config file
    sed -i "/^$runner_id:/d" "$CONFIG_FILE"
    
    log "Runner $runner_id removed successfully"
}

# Interactive remove runner
interactive_remove() {
    echo "=== Remove GitHub Actions Runner ==="
    echo
    
    # Show current runners
    list_runners
    echo
    
    read -p "Enter Runner ID to remove: " runner_id
    
    if [[ -z "$runner_id" ]]; then
        warning "No runner ID provided"
        return 1
    fi
    
    echo
    warning "This will permanently remove the runner from both GitHub and this machine."
    read -p "Are you sure? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo
        echo "To get a removal token (optional but recommended):"
        echo "1. Go to https://github.com/settings/actions/runners"
        echo "2. Or go to your repository settings > Actions > Runners"
        echo "3. Generate a removal token"
        echo
        
        read -p "Removal Token (optional): " removal_token
        
        remove_runner "$runner_id" "$removal_token"
    else
        info "Operation cancelled"
    fi
}

# List all runners
list_runners() {
    log "GitHub Actions Runners:"
    echo
    
    if [[ ! -f "$CONFIG_FILE" || ! -s "$CONFIG_FILE" ]]; then
        info "No runners configured"
        return 0
    fi
    
    printf "%-30s %-20s %-15s %-10s %s\n" "RUNNER ID" "REPOSITORY" "NAME" "STATUS" "CREATED"
    echo "────────────────────────────────────────────────────────────────────────────────────────"
    
    while IFS=':' read -r runner_id repo_path runner_name created_date; do
        if [[ -n "$runner_id" ]]; then
            local status="STOPPED"
            if systemctl is-active --quiet "github-runner-$runner_id.service"; then
                status="${GREEN}RUNNING${NC}"
            else
                status="${RED}STOPPED${NC}"
            fi
            
            printf "%-30s %-20s %-15s %-10s %s\n" "$runner_id" "$repo_path" "$runner_name" "$status" "$created_date"
        fi
    done < "$CONFIG_FILE"
}

# Start all runners
start_all_runners() {
    log "Starting all runners..."
    
    if [[ ! -f "$CONFIG_FILE" || ! -s "$CONFIG_FILE" ]]; then
        info "No runners configured"
        return 0
    fi
    
    while IFS=':' read -r runner_id repo_path runner_name created_date; do
        if [[ -n "$runner_id" ]]; then
            log "Starting $runner_id..."
            systemctl start "github-runner-$runner_id.service"
        fi
    done < "$CONFIG_FILE"
    
    log "All runners started"
}

# Stop all runners
stop_all_runners() {
    log "Stopping all runners..."
    
    if [[ ! -f "$CONFIG_FILE" || ! -s "$CONFIG_FILE" ]]; then
        info "No runners configured"
        return 0
    fi
    
    while IFS=':' read -r runner_id repo_path runner_name created_date; do
        if [[ -n "$runner_id" ]]; then
            log "Stopping $runner_id..."
            systemctl stop "github-runner-$runner_id.service"
        fi
    done < "$CONFIG_FILE"
    
    log "All runners stopped"
}

# Show runner status
show_status() {
    local runner_id="$1"
    
    if [[ -n "$runner_id" ]]; then
        # Show specific runner status
        if [[ ! -d "$RUNNERS_BASE_DIR/$runner_id" ]]; then
            error "Runner $runner_id not found"
            return 1
        fi
        
        log "Status for runner: $runner_id"
        systemctl status "github-runner-$runner_id.service"
    else
        # Show detailed system status
        show_detailed_status
    fi
}

# Monitor runners in real-time
monitor_runners() {
    echo "=== GitHub Actions Runners Monitor ==="
    echo "Press Ctrl+C to exit"
    echo
    
    while true; do
        clear
        echo "=== GitHub Actions Runners Monitor - $(date) ==="
        echo
        list_runners
        echo
        echo "Refreshing in 10 seconds... (Press Ctrl+C to exit)"
        sleep 10
    done
}

# Show logs for a specific runner
show_runner_logs() {
    local runner_id="$1"
    
    if [[ -z "$runner_id" ]]; then
        echo "Available runners:"
        list_runners
        echo
        read -p "Enter Runner ID to view logs: " runner_id
    fi
    
    if [[ -n "$runner_id" ]]; then
        echo "=== Logs for Runner: $runner_id ==="
        echo "Press Ctrl+C to exit"
        echo
        journalctl -u "github-runner-$runner_id.service" -f
    fi
}

# Get system information
get_system_info() {
    echo -e "${BOLD}System Information${NC}"
    echo "════════════════════════════════════════"
    echo "Hostname: $(hostname)"
    echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2 2>/dev/null || echo "Unknown")"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}' 2>/dev/null || echo "N/A")"
    echo "Memory Usage: $(free -h 2>/dev/null | awk 'NR==2{printf "%.1f%%", $3*100/$2}' || echo "N/A")"
    echo "Disk Usage: $(df -h / 2>/dev/null | awk 'NR==2{print $5}' || echo "N/A") (root filesystem)"
    echo
}

# Check Docker status
check_docker() {
    if command -v docker &> /dev/null; then
        if systemctl is-active --quiet docker; then
            echo -e "${GREEN}${RUNNING_ICON} Docker: Running${NC}"
            echo "  Version: $(docker --version | cut -d' ' -f3 | cut -d',' -f1)"
        else
            echo -e "${RED}${STOPPED_ICON} Docker: Installed but not running${NC}"
        fi
    else
        echo -e "${YELLOW}${WARNING_ICON} Docker: Not installed${NC}"
    fi
}

# Check runner user
check_runner_user() {
    if id "$RUNNER_USER" &>/dev/null; then
        echo -e "${GREEN}${RUNNING_ICON} GitHub Runner User: Exists${NC}"
        echo "  UID: $(id -u $RUNNER_USER)"
        echo "  Groups: $(groups $RUNNER_USER | cut -d':' -f2)"
    else
        echo -e "${RED}${STOPPED_ICON} GitHub Runner User: Not found${NC}"
    fi
}

# Show detailed system status
show_detailed_status() {
    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "           GitHub Actions Runner System Status"
    echo "                    $(date)"
    echo "════════════════════════════════════════════════════════════════"
    echo
    
    get_system_info
    
    echo -e "${BOLD}Service Status${NC}"
    echo "════════════════════════════════════════"
    check_docker
    check_runner_user
    echo
    
    echo -e "${BOLD}Directory Status${NC}"
    echo "════════════════════════════════════════"
    
    if [[ -d "$RUNNERS_BASE_DIR" ]]; then
        echo -e "${GREEN}${RUNNING_ICON} Base Directory: $RUNNERS_BASE_DIR${NC}"
        echo "  Owner: $(stat -c '%U:%G' "$RUNNERS_BASE_DIR" 2>/dev/null || echo "N/A")"
        echo "  Permissions: $(stat -c '%a' "$RUNNERS_BASE_DIR" 2>/dev/null || echo "N/A")"
        echo "  Size: $(du -sh "$RUNNERS_BASE_DIR" 2>/dev/null | cut -f1 || echo "N/A")"
    else
        echo -e "${RED}${STOPPED_ICON} Base Directory: Missing${NC}"
    fi
    
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "${GREEN}${RUNNING_ICON} Config File: $CONFIG_FILE${NC}"
        echo "  Runners Configured: $(wc -l < "$CONFIG_FILE" 2>/dev/null || echo "0")"
    else
        echo -e "${YELLOW}${WARNING_ICON} Config File: Not found${NC}"
    fi
    echo
    
    list_runners
    
    echo
    echo "Use '$0 monitor' for real-time monitoring"
    echo "Use '$0 logs <runner-id>' to view specific runner logs"
}

# Complete system installation
install_system() {
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
    
    init_system
    
    # Create useful aliases
    log "Creating useful aliases..."
    
    cat > /etc/profile.d/github-runners.sh << 'EOF'
# GitHub Actions Runner aliases
alias gr='github-runner-manager'
alias grl='github-runner-manager list'
alias grs='github-runner-manager status'
alias grm='github-runner-manager monitor'
EOF
    
    chmod +x /etc/profile.d/github-runners.sh
    
    echo
    echo "================================================================"
    echo "    GitHub Actions Runner Management System Installed!"
    echo "================================================================"
    echo
    echo "Available commands:"
    echo "  $0 add            - Add a new runner (interactive)"
    echo "  $0 remove         - Remove a runner (interactive)"
    echo "  $0 list           - List all runners"
    echo "  $0 status         - Show system status"
    echo "  $0 monitor        - Monitor runners in real-time"
    echo "  $0 logs [id]      - View runner logs"
    echo
    echo "Quick commands (after restarting shell):"
    echo "  gr list           - List runners"
    echo "  gr status         - System status"
    echo "  gr monitor        - Monitor runners"
    echo
    echo "Getting started:"
    echo "1. Add your first runner: $0 add"
    echo "2. Monitor runners: $0 monitor"
    echo "3. View system status: $0 status"
    echo
    echo "Configuration files:"
    echo "  Runners directory: $RUNNERS_BASE_DIR"
    echo "  Config file: $CONFIG_FILE"
    echo "================================================================"
}

# Show help
show_help() {
    echo "GitHub Actions Multi-Runner Management System"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Setup Commands:"
    echo "  install                                   Install the complete system"
    echo "  init                                      Initialize the runner management system"
    echo
    echo "Runner Management:"
    echo "  add [owner] [repo] [name] [token]        Add a new runner (interactive if no args)"
    echo "  remove [runner_id] [removal_token]       Remove a runner (interactive if no args)"
    echo "  list                                      List all runners"
    echo "  start [runner_id]                        Start runner(s)"
    echo "  stop [runner_id]                         Stop runner(s)"
    echo "  restart [runner_id]                      Restart runner(s)"
    echo
    echo "Monitoring & Status:"
    echo "  status [runner_id]                       Show system/runner status"
    echo "  monitor                                   Monitor runners in real-time"
    echo "  logs [runner_id]                         Show runner logs"
    echo
    echo "Internal Commands:"
    echo "  start-all                                Start all configured runners"
    echo "  stop-all                                 Stop all configured runners"
    echo
    echo "Examples:"
    echo "  sudo $0 install                          # Install the system"
    echo "  sudo $0 init                             # Initialize system"
    echo "  sudo $0 add                              # Interactive add runner"
    echo "  sudo $0 add myuser myrepo runner1 TOKEN  # Direct add runner"
    echo "  $0 list                                  # List runners"
    echo "  $0 monitor                               # Monitor in real-time"
    echo "  $0 logs myuser-myrepo-runner1            # View logs"
    echo
    echo "Notes:"
    echo "  - Registration tokens can be obtained from GitHub repo Settings > Actions > Runners"
    echo "  - Runner ID format: <owner>-<repo>-<name>"
    echo "  - All runners are created under: $RUNNERS_BASE_DIR"
    echo "  - Most commands require root privileges (use sudo)"
}

# Main script logic
main() {
    case "$1" in
        install)
            install_system
            ;;
        init)
            check_root
            init_system
            ;;
        add)
            check_root
            # support: add --url <url> --token <token>
            if [[ "$2" == "--url" ]]; then
                add_runner "$2" "$3" "$4" "$5" "$6"
            elif [[ $# -eq 5 ]]; then
                add_runner "$2" "$3" "$4" "$5"
            else
                interactive_add
            fi
            ;;
        remove)
            check_root
            if [[ $# -ge 2 ]]; then
                remove_runner "$2" "$3"
            else
                interactive_remove
            fi
            ;;
        list)
            list_runners
            ;;
        start)
            check_root
            if [[ -n "$2" ]]; then
                systemctl start "github-runner-$2.service"
            else
                start_all_runners
            fi
            ;;
        stop)
            check_root
            if [[ -n "$2" ]]; then
                systemctl stop "github-runner-$2.service"
            else
                stop_all_runners
            fi
            ;;
        restart)
            check_root
            if [[ -n "$2" ]]; then
                systemctl restart "github-runner-$2.service"
            else
                stop_all_runners
                sleep 2
                start_all_runners
            fi
            ;;
        start-all)
            check_root
            start_all_runners
            ;;
        stop-all)
            check_root
            stop_all_runners
            ;;
        status)
            show_status "$2"
            ;;
        monitor)
            monitor_runners
            ;;
        logs)
            show_runner_logs "$2"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            if [[ -n "$1" ]]; then
                error "Unknown command: $1"
                echo
            fi
            show_help
            exit 1
            ;;
    esac
}

# Menu for interactive runner management
main_menu() {
    while true; do
        clear
        echo -e "${BLUE}GitHub Actions Runner Manager${NC}"
        echo "======================================"
        echo -e "${GREEN}1.${NC} Install/Init System"
        echo -e "${GREEN}2.${NC} Add Runner"
        echo -e "${GREEN}3.${NC} Remove Runner"
        echo -e "${GREEN}4.${NC} List Runners"
        echo -e "${GREEN}5.${NC} Start Runner(s)"
        echo -e "${GREEN}6.${NC} Stop Runner(s)"
        echo -e "${GREEN}7.${NC} Restart Runner(s)"
        echo -e "${GREEN}8.${NC} Status"
        echo -e "${GREEN}9.${NC} Monitor"
        echo -e "${GREEN}10.${NC} Show Logs"
        echo -e "${GREEN}0.${NC} Exit"
        echo ""
        read -p "Select an option [0-10]: " choice

        case "$choice" in
            1)
                install_system
                ;;
            2)
                check_root
                interactive_add
                ;;
            3)
                check_root
                interactive_remove
                ;;
            4)
                list_runners
                read -p "Press Enter to continue..."
                ;;
            5)
                check_root
                echo "Leave blank to start all, or enter Runner ID:"
                read -p "Runner ID: " rid
                if [[ -n "$rid" ]]; then
                    systemctl start "github-runner-$rid.service"
                else
                    start_all_runners
                fi
                read -p "Press Enter to continue..."
                ;;
            6)
                check_root
                echo "Leave blank to stop all, or enter Runner ID:"
                read -p "Runner ID: " rid
                if [[ -n "$rid" ]]; then
                    systemctl stop "github-runner-$rid.service"
                else
                    stop_all_runners
                fi
                read -p "Press Enter to continue..."
                ;;
            7)
                check_root
                echo "Leave blank to restart all, or enter Runner ID:"
                read -p "Runner ID: " rid
                if [[ -n "$rid" ]]; then
                    systemctl restart "github-runner-$rid.service"
                else
                    stop_all_runners
                    sleep 2
                    start_all_runners
                fi
                read -p "Press Enter to continue..."
                ;;
            8)
                show_status
                read -p "Press Enter to continue..."
                ;;
            9)
                monitor_runners
                ;;
            10)
                echo "Enter Runner ID (leave blank to list):"
                read -p "Runner ID: " rid
                show_runner_logs "$rid"
                ;;
            0)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

# If no arguments, show menu; else, use CLI mode
if [[ $# -eq 0 ]]; then
    main_menu
else
    main "$@"
fi