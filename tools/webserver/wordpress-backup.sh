#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}WordPress Backup Tool${NC}"
echo "============================="

# Get WordPress path
read -p "Enter WordPress site path (e.g., /var/www/html/wordpress): " wp_path

# Validate WordPress path
if [ ! -d "$wp_path" ]; then
    echo -e "${RED}Error: WordPress path does not exist!${NC}"
    exit 1
fi

if [ ! -f "$wp_path/wp-config.php" ]; then
    echo -e "${RED}Error: wp-config.php not found in $wp_path!${NC}"
    exit 1
fi

# Extract database details from wp-config.php
echo -e "${YELLOW}Reading database configuration...${NC}"

db_name=$(grep "DB_NAME" "$wp_path/wp-config.php" | cut -d "'" -f 4)
db_user=$(grep "DB_USER" "$wp_path/wp-config.php" | cut -d "'" -f 4)
db_pass=$(grep "DB_PASSWORD" "$wp_path/wp-config.php" | cut -d "'" -f 4)
db_host=$(grep "DB_HOST" "$wp_path/wp-config.php" | cut -d "'" -f 4)

if [ -z "$db_name" ] || [ -z "$db_user" ]; then
    echo -e "${RED}Error: Could not extract database details from wp-config.php!${NC}"
    exit 1
fi

echo -e "${GREEN}Database Name: ${NC}$db_name"
echo -e "${GREEN}Database User: ${NC}$db_user"
echo -e "${GREEN}Database Host: ${NC}$db_host"

# Create backup directory with timestamp
backup_timestamp=$(date +"%Y%m%d_%H%M%S")
site_name=$(basename "$wp_path")
backup_dir="$wp_path/${site_name}_backup_$backup_timestamp"
mkdir -p "$backup_dir"

echo -e "${YELLOW}Creating backup in: $backup_dir${NC}"

# Create database dump
echo -e "${YELLOW}Creating database dump...${NC}"
if [ -n "$db_pass" ]; then
    mysqldump -h "$db_host" -u "$db_user" -p"$db_pass" "$db_name" > "$backup_dir/${site_name}_database_$backup_timestamp.sql"
else
    mysqldump -h "$db_host" -u "$db_user" "$db_name" > "$backup_dir/${site_name}_database_$backup_timestamp.sql"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database dump created${NC}"
else
    echo -e "${RED}✗ Database dump failed${NC}"
    read -p "Continue with file backup only? (y/n): " continue_backup
    if [[ ! "$continue_backup" =~ ^[Yy]$ ]]; then
        rm -rf "$backup_dir"
        exit 1
    fi
fi

# Copy WordPress files (excluding backup directory)
echo -e "${YELLOW}Copying WordPress files...${NC}"
rsync -av --exclude="${site_name}_backup_*" "$wp_path/" "$backup_dir/wordpress_files/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ WordPress files copied${NC}"
else
    echo -e "${RED}✗ WordPress files copy failed${NC}"
fi

# Create ZIP archive
echo -e "${YELLOW}Creating ZIP archive...${NC}"
cd "$wp_path"
zip_file="${site_name}_backup_$backup_timestamp.zip"
zip -r "$zip_file" "${site_name}_backup_$backup_timestamp/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ ZIP archive created: $wp_path/$zip_file${NC}"
    # Remove temporary backup directory
    rm -rf "$backup_dir"
else
    echo -e "${RED}✗ ZIP archive creation failed${NC}"
fi

# Show backup information
echo ""
echo -e "${BLUE}Backup Summary:${NC}"
echo "================================"
echo -e "Site: ${GREEN}$site_name${NC}"
echo -e "Path: ${GREEN}$wp_path${NC}"
echo -e "Backup File: ${GREEN}$wp_path/$zip_file${NC}"
echo -e "Database: ${GREEN}$db_name${NC}"
if [ -f "$wp_path/$zip_file" ]; then
    backup_size=$(du -h "$wp_path/$zip_file" | cut -f1)
    echo -e "Size: ${GREEN}$backup_size${NC}"
fi
echo -e "Created: ${GREEN}$(date)${NC}"

read -p "Press Enter to continue..."
