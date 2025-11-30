#!/bin/bash
# filepath: f:\linux-toolbox\run.sh

REPO_URL="https://github.com/nooblk-98/linux-toolbox.git"
REPO_DIR="/tmp/linux-toolbox"

# Clone or update repo
if [ ! -d "$REPO_DIR/.git" ]; then
    echo -e "\033[0;34m[INFO]\033[0m Cloning linux-toolbox from GitHub..."
    git clone "$REPO_URL" "$REPO_DIR"
else
    echo -e "\033[0;34m[INFO]\033[0m Updating linux-toolbox from GitHub..."
    git -C "$REPO_DIR" pull
fi

TOOLS_DIR="$REPO_DIR/tools"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

show_banner() {
    echo -e "${GREEN}██╗     ██╗███╗   ██╗██╗   ██╗██╗  ██╗    ████████╗ ██████╗  ██████╗ ██╗     ███████╗"
    echo -e "██║     ██║████╗  ██║██║   ██║╚██╗██╔╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝"
    echo -e "██║     ██║██╔██╗ ██║██║   ██║ ╚███╔╝        ██║   ██║   ██║██║   ██║██║     ███████╗"
    echo -e "██║     ██║██║╚██╗██║██║   ██║ ██╔██╗        ██║   ██║   ██║██║   ██║██║     ╚════██║"
    echo -e "███████╗██║██║ ╚████║╚██████╔╝██╔╝ ██╗       ██║   ╚██████╔╝╚██████╔╝███████╗███████║"
    echo -e "╚══════╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝${NC}"
    echo -e ""
    echo -e "${YELLOW}Maintainer: noobLk-98${NC}\n"
}

# System resource info (plain text)
show_system_info() {
    clear
    show_banner
    echo -e "${CYAN}========== System Resource Monitor ==========${NC}"
    # OS Info
    os_name=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
    echo -e "${MAGENTA}OS: ${NC}${os_name}"
    # RAM
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    mem_percent=$((mem_used * 100 / mem_total))
    echo -e "${BLUE}Memory Usage:${NC} ${mem_used}MB/${mem_total}MB (${mem_percent}%)"
    # Disk
    disk_total=$(df -h / | tail -1 | awk '{print $2}')
    disk_used=$(df -h / | tail -1 | awk '{print $3}')
    disk_percent=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    echo -e "${YELLOW}Disk Usage:  ${NC}${disk_used}/${disk_total} (${disk_percent}%)"
    echo -e "${CYAN}=============================================${NC}\n"
}

print_header() {
    echo -e "${GREEN}${BOLD}$1${NC}"
}

print_status() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get display name for category (Title Case, No Emojis)
get_category_display_name() {
    local category="$1"
    case "$category" in
        "automation") echo "Automation" ;;
        "backup-recovery") echo "Backup & Recovery" ;;
        "cicd") echo "CI/CD" ;;
        "containers") echo "Containers" ;;
        "core-system") echo "Core System" ;;
        "database") echo "Database" ;;
        "development") echo "Development" ;;
        "docker") echo "Docker" ;;
        "kubernetes") echo "Kubernetes" ;;
        "monitoring") echo "Monitoring" ;;
        "networking") echo "Networking" ;;
        "nodejs") echo "Node.js" ;;
        "observability") echo "Observability" ;;
        "security") echo "Security" ;;
        "system") echo "System" ;;
        "webserver") echo "Web Server" ;;
        *) 
            # Convert to Title Case for other categories
            echo "$category" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1'
            ;;
    esac
}

# Discover categories (subfolders with .sh files)
discover_categories() {
    local categories=()
    while IFS= read -r -d '' dir; do
        if find "$dir" -maxdepth 1 -type f -name "*.sh" | grep -q .; then
            categories+=("$(basename "$dir")")
        fi
    done < <(find "$TOOLS_DIR" -mindepth 1 -maxdepth 1 -type d -print0)
    # Also include .sh files directly in tools/ as "General"
    if find "$TOOLS_DIR" -maxdepth 1 -type f -name "*.sh" | grep -q .; then
        categories+=("General")
    fi
    printf "%s\n" "${categories[@]}" | sort
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

# Function to update from repo
update_from_repo() {
    clear
    show_banner
    echo -e "${YELLOW}Updating Linux Toolbox from GitHub...${NC}"
    
    if [ -d "$REPO_DIR/.git" ]; then
        cd "$REPO_DIR"
        git reset --hard HEAD
        git pull origin main
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully updated from repository!${NC}"
        else
            echo -e "${RED}Failed to update from repository!${NC}"
            echo -e "${YELLOW}Trying to clone fresh copy...${NC}"
            cd /tmp
            rm -rf "$REPO_DIR"
            git clone "$REPO_URL" "$REPO_DIR"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Successfully cloned repository!${NC}"
            else
                echo -e "${RED}Failed to clone repository!${NC}"
            fi
        fi
    else
        echo -e "${YELLOW}Cloning fresh copy from GitHub...${NC}"
        rm -rf "$REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Successfully cloned repository!${NC}"
        else
            echo -e "${RED}Failed to clone repository!${NC}"
        fi
    fi
    
    read -p "Press Enter to return to main menu..."
}

# Display category menu
show_category_menu() {
    show_system_info
    print_header "Linux Toolbox Categories"
    echo "--------------------------------"
    local i=1
    local categories=($(discover_categories))
    for cat in "${categories[@]}"; do
        local display_name=$(get_category_display_name "$cat")
        echo -e "${CYAN}$i.${NC} ${display_name}"
        ((i++))
    done
    echo -e "${MAGENTA}$i.${NC} Update from Repo"
    echo -e "${RED}0.${NC} Exit"
    echo ""
    echo -e "${MAGENTA}Select a category [0-$i]:${NC} "
    echo ""
    echo "Tip: Press Ctrl+C to quit at any time."
}

# Display tool menu for a category
show_tool_menu() {
    show_system_info
    local category="$1"
    local display_name=$(get_category_display_name "$category")
    print_header "$display_name Tools"
    echo "--------------------------------"
    local i=1
    local tools=($(discover_tools_in_category "$category"))
    for tool in "${tools[@]}"; do
        tool_name=$(basename "$tool" .sh)
        echo -e "${CYAN}$i.${NC} ${GREEN}$tool_name${NC}"
        ((i++))
    done
    echo -e "${RED}0.${NC} Back"
    echo ""
    echo -e "${MAGENTA}Select a tool to run [0-$(($i-1))]:${NC} "
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
        local update_option=$((${#categories[@]} + 1))
        
        if [[ "$cat_choice" == "0" ]]; then
            print_status "Exiting. Goodbye!"
            exit 0
        elif [[ "$cat_choice" == "$update_option" ]]; then
            update_from_repo
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