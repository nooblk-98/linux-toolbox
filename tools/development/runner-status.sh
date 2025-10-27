#!/bin/bash

# GitHub Actions Runner Status Monitor
# Provides detailed status information and health checks

RUNNERS_BASE_DIR="/opt/actions-runners"
CONFIG_FILE="/etc/github-runners.conf"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Status icons
RUNNING_ICON="🟢"
STOPPED_ICON="🔴"
WARNING_ICON="⚠️"
INFO_ICON="ℹ️"

# Get system information
get_system_info() {
    echo -e "${BOLD}System Information${NC}"
    echo "════════════════════════════════════════"
    echo "Hostname: $(hostname)"
    echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Memory Usage: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}') (root filesystem)"
    echo
}

# Check if Docker is available
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

# Check GitHub runner user
check_runner_user() {
    if id "github-runner" &>/dev/null; then
        echo -e "${GREEN}${RUNNING_ICON} GitHub Runner User: Exists${NC}"
        echo "  UID: $(id -u github-runner)"
        echo "  Groups: $(groups github-runner | cut -d':' -f2)"
    else
        echo -e "${RED}${STOPPED_ICON} GitHub Runner User: Not found${NC}"
    fi
}

# Check directories and permissions
check_directories() {
    echo -e "${BOLD}Directory Status${NC}"
    echo "════════════════════════════════════════"
    
    if [[ -d "$RUNNERS_BASE_DIR" ]]; then
        echo -e "${GREEN}${RUNNING_ICON} Base Directory: $RUNNERS_BASE_DIR${NC}"
        echo "  Owner: $(stat -c '%U:%G' "$RUNNERS_BASE_DIR")"
        echo "  Permissions: $(stat -c '%a' "$RUNNERS_BASE_DIR")"
        echo "  Size: $(du -sh "$RUNNERS_BASE_DIR" 2>/dev/null | cut -f1)"
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
}

# Detailed runner status
get_runner_details() {
    echo -e "${BOLD}Runner Details${NC}"
    echo "════════════════════════════════════════"
    
    if [[ ! -f "$CONFIG_FILE" || ! -s "$CONFIG_FILE" ]]; then
        echo -e "${INFO_ICON} No runners configured"
        return 0
    fi
    
    while IFS=':' read -r runner_id repo_path runner_name created_date; do
        if [[ -n "$runner_id" ]]; then
            echo -e "${BOLD}Runner: $runner_id${NC}"
            echo "  Repository: $repo_path"
            echo "  Name: $runner_name"
            echo "  Created: $created_date"
            
            # Service status
            if systemctl is-active --quiet "github-runner-$runner_id.service"; then
                echo -e "  Status: ${GREEN}${RUNNING_ICON} Running${NC}"
                
                # Get service start time
                local start_time=$(systemctl show "github-runner-$runner_id.service" --property=ActiveEnterTimestamp --value)
                echo "  Started: $start_time"
                
                # Get memory usage
                local memory_usage=$(systemctl show "github-runner-$runner_id.service" --property=MemoryCurrent --value)
                if [[ "$memory_usage" != "[not set]" && "$memory_usage" -gt 0 ]]; then
                    echo "  Memory: $(numfmt --to=iec "$memory_usage")"
                fi
                
                # Check if runner directory exists
                local runner_dir="$RUNNERS_BASE_DIR/$runner_id"
                if [[ -d "$runner_dir" ]]; then
                    echo "  Directory: $runner_dir ($(du -sh "$runner_dir" 2>/dev/null | cut -f1))"
                    
                    # Check for active jobs
                    if [[ -d "$runner_dir/_work" ]]; then
                        local work_dirs=$(find "$runner_dir/_work" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
                        if [[ $work_dirs -gt 0 ]]; then
                            echo -e "  ${INFO_ICON} Active workspaces: $work_dirs"
                        fi
                    fi
                else
                    echo -e "  Directory: ${RED}Missing${NC}"
                fi
            else
                echo -e "  Status: ${RED}${STOPPED_ICON} Stopped${NC}"
                
                # Check if service exists
                if systemctl list-unit-files "github-runner-$runner_id.service" &>/dev/null; then
                    echo "  Service: Configured but not running"
                else
                    echo -e "  Service: ${RED}Not configured${NC}"
                fi
            fi
            
            # Check for recent failures
            local failed_count=$(journalctl -u "github-runner-$runner_id.service" --since="24 hours ago" -p err --no-pager -q | wc -l)
            if [[ $failed_count -gt 0 ]]; then
                echo -e "  ${WARNING_ICON} Errors in last 24h: $failed_count"
            fi
            
            echo
        fi
    done < "$CONFIG_FILE"
}

# Network connectivity test
test_connectivity() {
    echo -e "${BOLD}Connectivity Test${NC}"
    echo "════════════════════════════════════════"
    
    # Test GitHub connectivity
    if curl -s --max-time 5 https://api.github.com/zen > /dev/null; then
        echo -e "${GREEN}${RUNNING_ICON} GitHub API: Reachable${NC}"
    else
        echo -e "${RED}${STOPPED_ICON} GitHub API: Unreachable${NC}"
    fi
    
    # Test Docker Hub (if Docker is available)
    if command -v docker &> /dev/null; then
        if curl -s --max-time 5 https://index.docker.io/v1/ > /dev/null; then
            echo -e "${GREEN}${RUNNING_ICON} Docker Hub: Reachable${NC}"
        else
            echo -e "${RED}${STOPPED_ICON} Docker Hub: Unreachable${NC}"
        fi
    fi
    echo
}

# System health summary
health_summary() {
    echo -e "${BOLD}Health Summary${NC}"
    echo "════════════════════════════════════════"
    
    local issues=0
    local warnings=0
    
    # Check critical components
    if [[ ! -d "$RUNNERS_BASE_DIR" ]]; then
        echo -e "${RED}${STOPPED_ICON} Critical: Base directory missing${NC}"
        ((issues++))
    fi
    
    if ! id "github-runner" &>/dev/null; then
        echo -e "${RED}${STOPPED_ICON} Critical: Runner user missing${NC}"
        ((issues++))
    fi
    
    if [[ -f "$CONFIG_FILE" && -s "$CONFIG_FILE" ]]; then
        local stopped_runners=0
        while IFS=':' read -r runner_id repo_path runner_name created_date; do
            if [[ -n "$runner_id" ]]; then
                if ! systemctl is-active --quiet "github-runner-$runner_id.service"; then
                    ((stopped_runners++))
                fi
            fi
        done < "$CONFIG_FILE"
        
        if [[ $stopped_runners -gt 0 ]]; then
            echo -e "${YELLOW}${WARNING_ICON} Warning: $stopped_runners runner(s) stopped${NC}"
            ((warnings++))
        fi
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}${WARNING_ICON} Warning: Docker not installed${NC}"
        ((warnings++))
    fi
    
    # Overall status
    if [[ $issues -eq 0 && $warnings -eq 0 ]]; then
        echo -e "${GREEN}${RUNNING_ICON} Overall Status: Healthy${NC}"
    elif [[ $issues -eq 0 ]]; then
        echo -e "${YELLOW}${WARNING_ICON} Overall Status: Minor Issues ($warnings warnings)${NC}"
    else
        echo -e "${RED}${STOPPED_ICON} Overall Status: Critical Issues ($issues critical, $warnings warnings)${NC}"
    fi
    echo
}

# Main function
main() {
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
    
    check_directories
    get_runner_details
    test_connectivity
    health_summary
    
    echo "Use 'runner-helper monitor' for real-time monitoring"
    echo "Use 'runner-helper logs <runner-id>' to view specific runner logs"
}

# Handle command line arguments
case "$1" in
    --json)
        # TODO: Implement JSON output for monitoring tools
        echo "JSON output not implemented yet"
        exit 1
        ;;
    --brief)
        # Brief status without detailed information
        if [[ -f "$CONFIG_FILE" && -s "$CONFIG_FILE" ]]; then
            local total=$(wc -l < "$CONFIG_FILE")
            local running=0
            
            while IFS=':' read -r runner_id repo_path runner_name created_date; do
                if [[ -n "$runner_id" ]] && systemctl is-active --quiet "github-runner-$runner_id.service"; then
                    ((running++))
                fi
            done < "$CONFIG_FILE"
            
            echo "Runners: $running/$total running"
        else
            echo "Runners: 0/0 running"
        fi
        ;;
    --help|-h)
        echo "GitHub Actions Runner Status Monitor"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --brief    Show brief status only"
        echo "  --json     Output in JSON format (not implemented)"
        echo "  --help     Show this help"
        echo
        exit 0
        ;;
    *)
        main
        ;;
esac