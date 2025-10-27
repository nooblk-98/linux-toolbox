#!/bin/bash

# GitHub Actions Runner Manager
# Manages multiple self-hosted GitHub Actions runners on a single machine
# Each runner is dedicated to one repository and runs in its own directory

# Configuration
RUNNERS_BASE_DIR="/opt/actions-runners"
SERVICES_DIR="/etc/systemd/system"
CONFIG_FILE="/etc/github-runners.conf"
RUNNER_VERSION="2.311.0"  # Update this to the latest version
RUNNER_USER="github-runner"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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
        error "This script must be run as root"
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

# Add a new runner
add_runner() {
    local repo_owner="$1"
    local repo_name="$2"
    local runner_name="$3"
    local token="$4"
    
    if [[ -z "$repo_owner" || -z "$repo_name" || -z "$runner_name" || -z "$token" ]]; then
        error "Usage: add_runner <repo_owner> <repo_name> <runner_name> <registration_token>"
        return 1
    fi
    
    local runner_id="${repo_owner}-${repo_name}-${runner_name}"
    local runner_dir="$RUNNERS_BASE_DIR/$runner_id"
    
    # Check if runner already exists
    if [[ -d "$runner_dir" ]]; then
        error "Runner $runner_id already exists"
        return 1
    fi
    
    log "Adding runner: $runner_id"
    
    # Create runner directory
    mkdir -p "$runner_dir"
    
    # Download and extract runner
    if ! download_runner "$runner_dir"; then
        rm -rf "$runner_dir"
        return 1
    fi
    
    # Configure the runner
    log "Configuring runner..."
    cd "$runner_dir"
    
    sudo -u $RUNNER_USER ./config.sh \
        --url "https://github.com/$repo_owner/$repo_name" \
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
    
    # Add to config file
    echo "$runner_id:$repo_owner/$repo_name:$runner_name:$(date)" >> "$CONFIG_FILE"
    
    # Start the service
    systemctl enable "github-runner-$runner_id.service"
    systemctl start "github-runner-$runner_id.service"
    
    log "Runner $runner_id added and started successfully"
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

# Remove a runner
remove_runner() {
    local runner_id="$1"
    local token="$2"
    
    if [[ -z "$runner_id" ]]; then
        error "Usage: remove_runner <runner_id> [removal_token]"
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
start_all() {
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
stop_all() {
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
status() {
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
        # Show all runners status
        list_runners
    fi
}

# Show help
show_help() {
    echo "GitHub Actions Runner Manager"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  init                                      Initialize the runner management system"
    echo "  add <owner> <repo> <name> <token>        Add a new runner"
    echo "  remove <runner_id> [removal_token]       Remove a runner"
    echo "  list                                      List all runners"
    echo "  start [runner_id]                        Start runner(s)"
    echo "  stop [runner_id]                         Stop runner(s)"
    echo "  restart [runner_id]                      Restart runner(s)"
    echo "  status [runner_id]                       Show runner status"
    echo "  help                                      Show this help"
    echo
    echo "Examples:"
    echo "  $0 init"
    echo "  $0 add myuser myrepo runner1 ABCD1234567890"
    echo "  $0 remove myuser-myrepo-runner1"
    echo "  $0 list"
    echo "  $0 start myuser-myrepo-runner1"
    echo "  $0 stop"
    echo
    echo "Notes:"
    echo "  - Registration tokens can be obtained from GitHub repo Settings > Actions > Runners"
    echo "  - Runner ID format: <owner>-<repo>-<name>"
    echo "  - All runners are created under: $RUNNERS_BASE_DIR"
}

# Main script logic
main() {
    case "$1" in
        init)
            check_root
            init_system
            ;;
        add)
            check_root
            add_runner "$2" "$3" "$4" "$5"
            ;;
        remove)
            check_root
            remove_runner "$2" "$3"
            ;;
        list)
            list_runners
            ;;
        start)
            check_root
            if [[ -n "$2" ]]; then
                systemctl start "github-runner-$2.service"
            else
                start_all
            fi
            ;;
        stop)
            check_root
            if [[ -n "$2" ]]; then
                systemctl stop "github-runner-$2.service"
            else
                stop_all
            fi
            ;;
        restart)
            check_root
            if [[ -n "$2" ]]; then
                systemctl restart "github-runner-$2.service"
            else
                stop_all
                sleep 2
                start_all
            fi
            ;;
        status)
            status "$2"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"