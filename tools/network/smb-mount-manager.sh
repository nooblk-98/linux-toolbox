#!/bin/bash

# SMB/CIFS Mount Manager
# Description: Script to manage SMB/CIFS drive mounting with temporary and permanent options
# Author: Linux Toolbox
# Version: 1.0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FSTAB_FILE="/etc/fstab"
CREDENTIALS_DIR="/etc/samba/credentials"
MOUNT_BASE_DIR="/mnt/smb"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}         SMB/CIFS Mount Manager${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Function to install required packages
install_dependencies() {
    print_status "Checking and installing required packages..."
    
    # Check if cifs-utils is installed
    if ! command -v mount.cifs &> /dev/null; then
        print_status "Installing cifs-utils..."
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y cifs-utils
        elif command -v yum &> /dev/null; then
            yum install -y cifs-utils
        elif command -v dnf &> /dev/null; then
            dnf install -y cifs-utils
        elif command -v pacman &> /dev/null; then
            pacman -S --noconfirm cifs-utils
        else
            print_error "Package manager not supported. Please install cifs-utils manually."
            exit 1
        fi
    else
        print_status "cifs-utils is already installed"
    fi
}

# Function to create credentials file
create_credentials() {
    local cred_file="$1"
    local username="$2"
    local password="$3"
    local domain="$4"
    
    # Create credentials directory if it doesn't exist
    mkdir -p "$CREDENTIALS_DIR"
    
    # Create credentials file
    cat > "$cred_file" << EOF
username=$username
password=$password
EOF
    
    # Add domain if provided
    if [[ -n "$domain" ]]; then
        echo "domain=$domain" >> "$cred_file"
    fi
    
    # Set secure permissions
    chmod 600 "$cred_file"
    chown root:root "$cred_file"
    
    print_status "Credentials file created: $cred_file"
}

# Function to mount SMB share temporarily
mount_temporary() {
    local server="$1"
    local share="$2"
    local mount_point="$3"
    local username="$4"
    local password="$5"
    local domain="$6"
    local options="$7"
    
    # Create mount point if it doesn't exist
    mkdir -p "$mount_point"
    
    # Build mount command
    local mount_cmd="mount -t cifs //$server/$share $mount_point"
    
    if [[ -n "$username" ]]; then
        mount_cmd="$mount_cmd -o username=$username"
        if [[ -n "$password" ]]; then
            mount_cmd="$mount_cmd,password=$password"
        fi
        if [[ -n "$domain" ]]; then
            mount_cmd="$mount_cmd,domain=$domain"
        fi
    else
        mount_cmd="$mount_cmd -o guest"
    fi
    
    # Add additional options
    if [[ -n "$options" ]]; then
        mount_cmd="$mount_cmd,$options"
    fi
    
    # Execute mount command
    print_status "Mounting //$server/$share to $mount_point"
    if eval "$mount_cmd"; then
        print_status "Successfully mounted SMB share"
        echo "Mount point: $mount_point"
        echo "To unmount: umount $mount_point"
    else
        print_error "Failed to mount SMB share"
        return 1
    fi
}

# Function to add permanent mount
mount_permanent() {
    local server="$1"
    local share="$2"
    local mount_point="$3"
    local username="$4"
    local password="$5"
    local domain="$6"
    local options="$7"
    local mount_name="$8"
    
    # Create mount point if it doesn't exist
    mkdir -p "$mount_point"
    
    # Create credentials file
    local cred_file="$CREDENTIALS_DIR/${mount_name}.cred"
    if [[ -n "$username" ]]; then
        create_credentials "$cred_file" "$username" "$password" "$domain"
        local fstab_options="credentials=$cred_file,uid=1000,gid=1000,iocharset=utf8,file_mode=0777,dir_mode=0777"
    else
        local fstab_options="guest,uid=1000,gid=1000,iocharset=utf8,file_mode=0777,dir_mode=0777"
    fi
    
    # Add custom options
    if [[ -n "$options" ]]; then
        fstab_options="$fstab_options,$options"
    fi
    
    # Add entry to fstab
    local fstab_entry="//$server/$share $mount_point cifs $fstab_options 0 0"
    
    # Check if entry already exists
    if grep -q "//$server/$share" "$FSTAB_FILE"; then
        print_warning "Mount entry already exists in fstab"
        return 1
    fi
    
    # Add comment and entry to fstab
    echo "" >> "$FSTAB_FILE"
    echo "# SMB Mount: $mount_name" >> "$FSTAB_FILE"
    echo "$fstab_entry" >> "$FSTAB_FILE"
    
    # Test mount
    print_status "Testing permanent mount..."
    if mount "$mount_point"; then
        print_status "Permanent mount added successfully"
        echo "Mount point: $mount_point"
        echo "Added to fstab for automatic mounting on boot"
    else
        print_error "Failed to mount. Removing fstab entry..."
        # Remove the added entries
        sed -i '/# SMB Mount: '"$mount_name"'/,+1d' "$FSTAB_FILE"
        return 1
    fi
}

# Function to remove mount
remove_mount() {
    local mount_point="$1"
    
    # Unmount if currently mounted
    if mountpoint -q "$mount_point"; then
        print_status "Unmounting $mount_point"
        umount "$mount_point"
    fi
    
    # Remove from fstab
    if grep -q "$mount_point" "$FSTAB_FILE"; then
        print_status "Removing from fstab..."
        # Create backup
        cp "$FSTAB_FILE" "$FSTAB_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Remove the mount entry and its comment
        sed -i "\|$mount_point|{
            # Find the line with the mount point
            N
            # If the previous line is a comment, include it in deletion
            s|^# SMB Mount:.*\n.*$mount_point.*||
            # If no comment, just delete the mount line
            t end
            s|.*$mount_point.*||
            :end
        }" "$FSTAB_FILE"
        
        # Also try alternative approach
        grep -v "$mount_point" "$FSTAB_FILE" > /tmp/fstab.tmp && mv /tmp/fstab.tmp "$FSTAB_FILE"
        
        print_status "Removed from fstab"
    fi
    
    # Remove mount point directory if empty
    if [[ -d "$mount_point" ]]; then
        if rmdir "$mount_point" 2>/dev/null; then
            print_status "Removed empty mount point directory"
        else
            print_warning "Mount point directory not empty, keeping it"
        fi
    fi
    
    print_status "Mount removed successfully"
}

# Function to list current SMB mounts
list_mounts() {
    print_status "Current SMB/CIFS mounts:"
    echo ""
    
    # Show currently mounted SMB shares
    echo "Currently mounted:"
    mount | grep cifs | while read line; do
        echo "  $line"
    done
    
    echo ""
    echo "Permanent mounts in fstab:"
    grep -E "^\s*//" "$FSTAB_FILE" | grep cifs | while read line; do
        echo "  $line"
    done
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTION]

SMB/CIFS Mount Manager Options:
  temp-mount    Mount SMB share temporarily
  perm-mount    Add permanent SMB mount (auto-mount on boot)
  remove        Remove SMB mount
  list          List current SMB mounts
  install-deps  Install required dependencies
  help          Show this help message

Examples:
  $0 temp-mount
  $0 perm-mount
  $0 remove
  $0 list

EOF
}

# Function for interactive temporary mount
interactive_temp_mount() {
    echo ""
    print_status "Setting up temporary SMB mount"
    echo ""
    
    read -p "Enter SMB server IP/hostname: " server
    read -p "Enter share name: " share
    read -p "Enter mount point [$MOUNT_BASE_DIR/$share]: " mount_point
    mount_point=${mount_point:-"$MOUNT_BASE_DIR/$share"}
    
    read -p "Enter username (leave empty for guest access): " username
    if [[ -n "$username" ]]; then
        read -s -p "Enter password: " password
        echo ""
        read -p "Enter domain (optional): " domain
    fi
    
    read -p "Enter additional mount options (optional): " options
    
    mount_temporary "$server" "$share" "$mount_point" "$username" "$password" "$domain" "$options"
}

# Function for interactive permanent mount
interactive_perm_mount() {
    echo ""
    print_status "Setting up permanent SMB mount"
    echo ""
    
    read -p "Enter SMB server IP/hostname: " server
    read -p "Enter share name: " share
    read -p "Enter mount point [$MOUNT_BASE_DIR/$share]: " mount_point
    mount_point=${mount_point:-"$MOUNT_BASE_DIR/$share"}
    
    read -p "Enter mount name for identification: " mount_name
    mount_name=${mount_name:-"$share"}
    
    read -p "Enter username (leave empty for guest access): " username
    if [[ -n "$username" ]]; then
        read -s -p "Enter password: " password
        echo ""
        read -p "Enter domain (optional): " domain
    fi
    
    read -p "Enter additional mount options (optional): " options
    
    mount_permanent "$server" "$share" "$mount_point" "$username" "$password" "$domain" "$options" "$mount_name"
}

# Function for interactive remove mount
interactive_remove_mount() {
    echo ""
    print_status "Remove SMB mount"
    echo ""
    
    # Show current mounts
    list_mounts
    echo ""
    
    read -p "Enter mount point to remove: " mount_point
    
    if [[ -z "$mount_point" ]]; then
        print_error "Mount point cannot be empty"
        return 1
    fi
    
    read -p "Are you sure you want to remove mount $mount_point? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        remove_mount "$mount_point"
    else
        print_status "Operation cancelled"
    fi
}

# Main menu
main_menu() {
    while true; do
        print_header
        echo ""
        echo "Select an option:"
        echo "1) Mount SMB share temporarily"
        echo "2) Add permanent SMB mount"
        echo "3) Remove SMB mount"
        echo "4) List current mounts"
        echo "5) Install dependencies"
        echo "6) Exit"
        echo ""
        read -p "Enter your choice [1-6]: " choice
        
        case $choice in
            1)
                interactive_temp_mount
                ;;
            2)
                interactive_perm_mount
                ;;
            3)
                interactive_remove_mount
                ;;
            4)
                list_mounts
                ;;
            5)
                install_dependencies
                ;;
            6)
                print_status "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Main script logic
main() {
    case "${1:-}" in
        "temp-mount")
            check_root
            interactive_temp_mount
            ;;
        "perm-mount")
            check_root
            interactive_perm_mount
            ;;
        "remove")
            check_root
            interactive_remove_mount
            ;;
        "list")
            list_mounts
            ;;
        "install-deps")
            check_root
            install_dependencies
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        "")
            check_root
            main_menu
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"