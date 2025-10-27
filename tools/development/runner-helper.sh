#!/bin/bash

# GitHub Actions Runner Quick Management Helper
# Provides simplified commands for common runner operations

MANAGER_SCRIPT="/opt/linux-toolbox/tools/development/github-runner-manager.sh"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if manager script exists
if [[ ! -f "$MANAGER_SCRIPT" ]]; then
    echo "Error: GitHub Runner Manager script not found at $MANAGER_SCRIPT"
    echo "Please ensure the main script is properly installed."
    exit 1
fi

# Quick add function with prompts
quick_add() {
    echo "=== Quick Add GitHub Actions Runner ==="
    echo
    
    read -p "GitHub Repository Owner: " repo_owner
    read -p "GitHub Repository Name: " repo_name
    read -p "Runner Name (e.g., server-01): " runner_name
    
    echo
    echo "To get a registration token:"
    echo "1. Go to https://github.com/$repo_owner/$repo_name/settings/actions/runners"
    echo "2. Click 'New self-hosted runner'"
    echo "3. Copy the token from the configuration command"
    echo
    
    read -p "Registration Token: " token
    
    echo
    info "Adding runner: $repo_owner/$repo_name ($runner_name)"
    
    sudo "$MANAGER_SCRIPT" add "$repo_owner" "$repo_name" "$runner_name" "$token"
}

# Quick remove function with selection
quick_remove() {
    echo "=== Remove GitHub Actions Runner ==="
    echo
    
    # Show current runners
    "$MANAGER_SCRIPT" list
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
        
        sudo "$MANAGER_SCRIPT" remove "$runner_id" "$removal_token"
    else
        info "Operation cancelled"
    fi
}

# Monitor runners
monitor() {
    echo "=== GitHub Actions Runners Monitor ==="
    echo "Press Ctrl+C to exit"
    echo
    
    while true; do
        clear
        echo "=== GitHub Actions Runners Monitor - $(date) ==="
        echo
        "$MANAGER_SCRIPT" list
        echo
        echo "Refreshing in 10 seconds... (Press Ctrl+C to exit)"
        sleep 10
    done
}

# Show logs for a specific runner
show_logs() {
    local runner_id="$1"
    
    if [[ -z "$runner_id" ]]; then
        echo "Available runners:"
        "$MANAGER_SCRIPT" list
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

# System status
system_status() {
    echo "=== GitHub Actions Runner System Status ==="
    echo
    
    # Check if system is initialized
    if [[ -d "/opt/actions-runners" ]]; then
        info "System is initialized"
    else
        warning "System not initialized. Run: sudo $MANAGER_SCRIPT init"
        return 1
    fi
    
    # Check runner user
    if id "github-runner" &>/dev/null; then
        info "GitHub runner user exists"
    else
        warning "GitHub runner user not found"
    fi
    
    # Show runners
    echo
    "$MANAGER_SCRIPT" list
    
    # Show disk usage
    echo
    echo "Disk usage for runners directory:"
    du -sh /opt/actions-runners/* 2>/dev/null || echo "No runners found"
}

# Show help
show_help() {
    echo "GitHub Actions Runner Helper"
    echo
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  add         Interactively add a new runner"
    echo "  remove      Interactively remove a runner"
    echo "  list        List all runners"
    echo "  start       Start all runners"
    echo "  stop        Stop all runners"
    echo "  restart     Restart all runners"
    echo "  status      Show system status"
    echo "  monitor     Monitor runners in real-time"
    echo "  logs [id]   Show logs for a runner"
    echo "  init        Initialize the system"
    echo "  help        Show this help"
    echo
    echo "Advanced usage (direct manager script):"
    echo "  sudo $MANAGER_SCRIPT <command> [options]"
}

# Main command handling
case "$1" in
    add)
        quick_add
        ;;
    remove)
        quick_remove
        ;;
    list)
        "$MANAGER_SCRIPT" list
        ;;
    start)
        sudo "$MANAGER_SCRIPT" start
        ;;
    stop)
        sudo "$MANAGER_SCRIPT" stop
        ;;
    restart)
        sudo "$MANAGER_SCRIPT" restart
        ;;
    status)
        system_status
        ;;
    monitor)
        monitor
        ;;
    logs)
        show_logs "$2"
        ;;
    init)
        sudo "$MANAGER_SCRIPT" init
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        if [[ -n "$1" ]]; then
            echo "Unknown command: $1"
            echo
        fi
        show_help
        exit 1
        ;;
esac