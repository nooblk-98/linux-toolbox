#!/bin/bash

################################################################################
# Swap Manager Script
# Purpose: Create and manage swap space with recommended size calculation
# Author: Linux Toolbox
# Description: Calculates recommended swap size based on current RAM,
#              displays recommendation, and allows custom value input
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Get current RAM size in KB
get_ram_size() {
    grep MemTotal /proc/meminfo | awk '{print $2}'
}

# Calculate recommended swap size based on RAM (using integer math)
calculate_recommended_swap() {
    local ram_kb=$1
    local ram_gb=$((ram_kb / 1024 / 1024))
    local recommended_swap
    
    # Swap recommendation logic:
    # RAM < 2GB: 2x RAM
    # RAM 2-8GB: 1.5x RAM
    # RAM 8-64GB: 1x RAM
    # RAM > 64GB: 0.5x RAM (or fixed 32GB)
    
    if [ "$ram_gb" -lt 2 ]; then
        recommended_swap=$((ram_gb * 2))
    elif [ "$ram_gb" -lt 8 ]; then
        recommended_swap=$((ram_gb * 3 / 2))  # 1.5x using integer math
    elif [ "$ram_gb" -lt 64 ]; then
        recommended_swap=$((ram_gb * 1))
    else
        recommended_swap=32
    fi
    
    echo "$recommended_swap"
}

# Check existing swap
check_existing_swap() {
    local current_swap=$(free -g | grep Swap | awk '{print $2}')
    echo "$current_swap"
}

# Convert GB to MB for dd command
gb_to_mb() {
    echo $(($1 * 1024))
}

# Create swap file
create_swap_file() {
    local swap_file=$1
    local swap_size_mb=$2
    
    print_info "Creating swap file: $swap_file (${swap_size_mb}MB)..."
    
    if [ -f "$swap_file" ]; then
        print_warning "Swap file already exists at $swap_file"
        read -p "Overwrite existing swap? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Operation cancelled"
            return 1
        fi
        swapoff "$swap_file" 2>/dev/null || print_warning "Could not deactivate existing swap"
        rm -f "$swap_file"
    fi
    
    # Create swap file using fallocate if available, otherwise dd
    if command -v fallocate &> /dev/null; then
        print_info "Using fallocate for faster allocation..."
        if ! fallocate -l "${swap_size_mb}M" "$swap_file"; then
            print_error "fallocate failed, trying dd instead..."
            if ! dd if=/dev/zero of="$swap_file" bs=1M count="$swap_size_mb"; then
                print_error "Failed to create swap file"
                return 1
            fi
        fi
    else
        print_info "Using dd to create swap file..."
        if ! dd if=/dev/zero of="$swap_file" bs=1M count="$swap_size_mb"; then
            print_error "Failed to create swap file"
            return 1
        fi
    fi
    
    print_info "Setting permissions..."
    chmod 600 "$swap_file" || { print_error "Failed to set permissions"; return 1; }
    
    print_info "Formatting as swap..."
    if ! mkswap "$swap_file"; then
        print_error "Failed to format swap file"
        return 1
    fi
    
    print_info "Activating swap..."
    if ! swapon "$swap_file"; then
        print_error "Failed to activate swap"
        return 1
    fi
    
    print_success "Swap file created and activated"
}

# Make swap permanent in /etc/fstab
make_swap_permanent() {
    local swap_file=$1
    
    if grep -q "$swap_file" /etc/fstab; then
        print_warning "Swap file already in /etc/fstab"
        return 0
    fi
    
    echo "$swap_file none swap sw 0 0" >> /etc/fstab
    print_success "Swap file added to /etc/fstab for persistence"
}

# Display swap info
display_swap_info() {
    echo -e "\n${BLUE}Current Swap Information:${NC}"
    free -h | grep -E "^Swap|^Total"
}

# Main menu
main() {
    print_header "Swap Manager"
    
    check_root
    
    local current_ram=$(get_ram_size)
    local current_swap=$(check_existing_swap)
    local recommended_swap=$(calculate_recommended_swap "$current_ram")
    local ram_gb=$((current_ram / 1024 / 1024))
    
    print_info "Current System RAM: ${ram_gb}GB"
    print_info "Current Swap: ${current_swap}GB"
    print_info "Recommended Swap: ${recommended_swap}GB"
    
    echo ""
    echo "Select an option:"
    echo "1) Create swap with recommended size (${recommended_swap}GB)"
    echo "2) Create swap with custom size"
    echo "3) View current swap info"
    echo "4) Remove swap file"
    echo "5) Exit"
    echo ""
    
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            create_swap_with_size "$recommended_swap"
            ;;
        2)
            echo ""
            read -p "Enter desired swap size in GB: " custom_swap
            if ! [[ "$custom_swap" =~ ^[0-9]+$ ]]; then
                print_error "Invalid input. Please enter a positive whole number."
                return 1
            fi
            if [ "$custom_swap" -le 0 ]; then
                print_error "Swap size must be greater than 0"
                return 1
            fi
            create_swap_with_size "$custom_swap"
            ;;
        3)
            display_swap_info
            ;;
        4)
            remove_swap
            ;;
        5)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option"
            return 1
            ;;
    esac
}

# Create swap with specified size
create_swap_with_size() {
    local swap_size_gb=$1
    local swap_file="/swapfile"
    
    print_header "Creating Swap Space"
    
    echo -e "\n${YELLOW}Configuration:${NC}"
    print_info "Swap file location: $swap_file"
    print_info "Swap size: ${swap_size_gb}GB"
    
    read -p $'\nProceed with swap creation? (y/n): ' -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Operation cancelled"
        exit 0
    fi
    
    local swap_size_mb=$(gb_to_mb "$swap_size_gb")
    
    create_swap_file "$swap_file" "$swap_size_mb"
    make_swap_permanent "$swap_file"
    
    echo ""
    display_swap_info
    print_success "Swap space creation completed!"
}

# Remove swap file
remove_swap() {
    local swap_file="/swapfile"
    
    if [ ! -f "$swap_file" ]; then
        print_error "Swap file not found at $swap_file"
        return 1
    fi
    
    print_warning "This will remove the swap file at $swap_file"
    read -p "Are you sure? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Operation cancelled"
        return 1
    fi
    
    swapoff "$swap_file" 2>/dev/null || true
    rm -f "$swap_file"
    sed -i "\|$swap_file|d" /etc/fstab
    
    print_success "Swap file removed"
    display_swap_info
}

# Run main function
main

