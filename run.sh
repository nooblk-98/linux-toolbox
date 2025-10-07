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

# Discover categories (subfolders with .sh files)
discover_categories() {
    find "$TOOLS_DIR" -mindepth 1 -type d | while read -r dir; do
        if find "$dir" -maxdepth 1 -type f -name "*.sh" | grep -q .; then
            basename "$dir"
        fi
    done
    # Also include .sh files directly in tools/ as "General"
    if find "$TOOLS_DIR" -maxdepth 1 -type f -name "*.sh" | grep -q .; then
        echo "General"
    fi
}

# Discover tools in a category
discover_tools_in_category() {
    local category="$1"
    if [ "$category" = "General" ]; then
        find "$TOOLS_DIR" -maxdepth 1 -type f -name "*.sh" | sort
    else
        find "$TOOLS_DIR/$category" -maxdepth 1 -type f -name "*.sh" | sort
    fi
}

# Display category menu
show_category_menu() {
    print_header "Linux Toolbox Categories"
    echo "=========================="
    local i=1
    local categories=($(discover_categories))
    for cat in "${categories[@]}"; do
        echo -e "${GREEN}$i.${NC} $cat"
        ((i++))
    done
    echo -e "${RED}0.${NC} Exit"
    echo ""
    echo -e "${YELLOW}Select a category [0-$(($i-1))]:${NC} "
    echo ""
    echo "Tip: Press Ctrl+C to quit at any time."
}

# Display tool menu for a category
show_tool_menu() {
    local category="$1"
    print_header "Category: $category"
    echo "--------------------------"
    local i=1
    local tools=($(discover_tools_in_category "$category"))
    for tool in "${tools[@]}"; do
        tool_name=$(basename "$tool" .sh)
        echo -e "${GREEN}$i.${NC} $tool_name"
        ((i++))
    done
    echo -e "${RED}0.${NC} Back"
    echo ""
    echo -e "${YELLOW}Select a tool to run [0-$(($i-1))]:${NC} "
}

main() {
    if [ ! -d "$TOOLS_DIR" ]; then
        print_error "Tools directory not found: $TOOLS_DIR"
        exit 1
    fi
    while true; do
        show_category_menu
        read cat_choice
        local categories=($(discover_categories))
        if [[ "$cat_choice" == "0" ]]; then
            print_status "Exiting. Goodbye!"
            exit 0
        elif [[ "$cat_choice" -ge 1 && "$cat_choice" -le "${#categories[@]}" ]]; then
            local category="${categories[$((cat_choice-1))]}"
            while true; do
                show_tool_menu "$category"
                read tool_choice
                local tools=($(discover_tools_in_category "$category"))
                if [[ "$tool_choice" == "0" ]]; then
                    break
                elif [[ "$tool_choice" -ge 1 && "$tool_choice" -le "${#tools[@]}" ]]; then
                    tool_script="${tools[$((tool_choice-1))]}"
                    print_status "Running $(basename "$tool_script")..."
                    bash "$tool_script"
                    echo ""
                    read -p "Press Enter to return to $category menu..."
                else
                    print_error "Invalid selection!"
                fi
            done
        else
            print_error "Invalid selection!"
        fi
    done
}

main