#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}MariaDB 10 + phpMyAdmin Docker Installer${NC}"

# Ask for credentials
read -p "Enter MariaDB root password: " DB_ROOT_PASSWORD
read -p "Enter database name: " DB_NAME
read -p "Enter database user: " DB_USER
read -p "Enter database user password: " DB_USER_PASSWORD
read -p "Enter phpMyAdmin port (default 8080): " PHPMYADMIN_PORT
PHPMYADMIN_PORT=${PHPMYADMIN_PORT:-8080}

# Create /opt/db if not exists
sudo mkdir -p /opt/db/mariadb_data
sudo mkdir -p /opt/db/phpmyadmin_data

# Generate docker-compose.yml
cat <<EOF | sudo tee /opt/db/docker-compose.yml > /dev/null
version: '3.7'

services:
  mariadb:
    image: mariadb:10
    container_name: mariadb10
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_USER_PASSWORD}
    volumes:
      - /opt/db/mariadb_data:/var/lib/mysql
    ports:
      - "3306:3306"

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    restart: always
    environment:
      PMA_HOST: mariadb
      PMA_USER: ${DB_USER}
      PMA_PASSWORD: ${DB_USER_PASSWORD}
    ports:
      - "${PHPMYADMIN_PORT}:80"
    depends_on:
      - mariadb
EOF

echo -e "${GREEN}docker-compose.yml created at /opt/db/docker-compose.yml${NC}"

# Install Docker Compose if not present
if ! command -v docker-compose >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Start the stack
cd /opt/db
sudo docker-compose up -d

echo -e "${GREEN}MariaDB 10 and phpMyAdmin are running.${NC}"
echo -e "${YELLOW}phpMyAdmin is available at: http://$(hostname -I | awk '{print $1}'):${PHPMYADMIN_PORT}${NC}"
echo -e "${YELLOW}MariaDB data is stored in /opt/db/mariadb_data${NC}"
read -p "Press Enter to continue..."
