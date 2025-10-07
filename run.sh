#!/bin/bash
# filepath: d:\github\linux-toolbox\run.sh

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/tools" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}$1${NC}"
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Discover available tools
discover_tools() {
    find "$TOOLS_DIR" -maxdepth 1 -type f -name "*.sh" | sort
}

# Display menu
show_menu() {
    print_header "Linux Toolbox Menu"
    echo "=========================="
    local i=1
    for tool in $(discover_tools); do
        tool_name=$(basename "$tool" .sh)
        echo -e "${GREEN}$i.${NC} $tool_name"
        ((i++))
    done
    echo -e "${RED}0.${NC} Exit"
    echo ""
    echo -e "${YELLOW}Select a tool to run [0-$(($i-1))]:${NC} "
}

# Run selected tool
run_tool() {
    local choice=$1
    local tools=($(discover_tools))
    if [[ "$choice" -ge 1 && "$choice" -le "${#tools[@]}" ]]; then
        tool_script="${tools[$((choice-1))]}"
        print_status "Running $(basename "$tool_script")..."
        bash "$tool_script"
    elif [[ "$choice" == "0" ]]; then
        print_status "Exiting. Goodbye!"
        exit 0
    else
        print_error "Invalid selection!"
    fi
}

main() {
    if [ ! -d "$TOOLS_DIR" ]; then
        print_error "Tools directory not found: $TOOLS_DIR"
        exit 1
    fi
    while true; do
        show_menu
        read choice
        run_tool "$choice"
        echo ""
        read -p "Press Enter to return to menu..."
    done
}

main