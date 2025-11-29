#!/bin/bash
# Certbot Manager - All-in-One SSL Certificate Management Tool
# Combines: installation, obtaining, renewal, domain management, and auto-renewal

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Global variables
PM=""
HAS_NGINX=0
HAS_APACHE=0
SERVER=""

# Detect system configuration
detect_system() {
    # Detect package manager
    if command -v apt-get >/dev/null 2>&1; then
        PM="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PM="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PM="yum"
    fi
    
    # Detect web server
    if command -v nginx >/dev/null 2>&1; then 
        HAS_NGINX=1
        SERVER="nginx"
    fi
    if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then 
        HAS_APACHE=1
        if [ -z "$SERVER" ]; then
            SERVER="apache"
        fi
    fi
}

# Show banner
show_banner() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}🔒 Certbot Manager - SSL Made Easy${NC}     ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Show system info
    echo -e "${BLUE}System Information:${NC}"
    echo -e "  Package Manager: ${YELLOW}${PM:-unknown}${NC}"
    [[ $HAS_NGINX -eq 1 ]] && echo -e "  Web Server: ${GREEN}Nginx ✓${NC}"
    [[ $HAS_APACHE -eq 1 ]] && echo -e "  Web Server: ${GREEN}Apache ✓${NC}"
    
    # Check Certbot status
    if command -v certbot >/dev/null 2>&1; then
        echo -e "  Certbot: ${GREEN}Installed ✓${NC} ($(certbot --version 2>/dev/null | head -1))"
    else
        echo -e "  Certbot: ${RED}Not Installed ✗${NC}"
    fi
    echo ""
}

# Install Certbot
install_certbot() {
    echo -e "${BLUE}═══ Installing Certbot ═══${NC}\n"
    
    if command -v certbot >/dev/null 2>&1; then
        echo -e "${GREEN}Certbot is already installed!${NC}"
        echo -e "Version: $(certbot --version 2>/dev/null)"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${YELLOW}Installing Certbot via snap (recommended method)...${NC}\n"
    
    # Install snapd if missing
    if ! command -v snap >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing snapd...${NC}"
        case "$PM" in
            apt)
                sudo apt-get update && sudo apt-get install -y snapd
                ;;
            dnf|yum)
                sudo "$PM" install -y snapd
                ;;
            *)
                echo -e "${RED}No known package manager to install snapd.${NC}"
                read -p "Press Enter to continue..."
                return
                ;;
        esac
    fi
    
    # Install Certbot
    sudo systemctl enable --now snapd.socket
    sudo snap install core; sudo snap refresh core
    sudo snap install --classic certbot
    sudo ln -sf /snap/bin/certbot /usr/local/bin/certbot
    
    # Install web server plugins
    if [ "$HAS_NGINX" -eq 1 ]; then
        echo -e "\n${YELLOW}Installing Nginx plugin...${NC}"
        if [ "$PM" = "apt" ]; then
            sudo apt-get install -y python3-certbot-nginx 2>/dev/null || true
        elif [ "$PM" = "dnf" ] || [ "$PM" = "yum" ]; then
            sudo "$PM" install -y python3-certbot-nginx 2>/dev/null || true
        fi
    fi
    
    if [ "$HAS_APACHE" -eq 1 ]; then
        echo -e "${YELLOW}Installing Apache plugin...${NC}"
        if [ "$PM" = "apt" ]; then
            sudo apt-get install -y python3-certbot-apache 2>/dev/null || true
        elif [ "$PM" = "dnf" ] || [ "$PM" = "yum" ]; then
            sudo "$PM" install -y python3-certbot-apache 2>/dev/null || true
        fi
    fi
    
    echo -e "\n${GREEN}✓ Certbot installation completed!${NC}"
    read -p "Press Enter to continue..."
}

# Obtain new certificate
obtain_certificate() {
    echo -e "${BLUE}═══ Obtain SSL Certificate ═══${NC}\n"
    
    if ! command -v certbot >/dev/null 2>&1; then
        echo -e "${RED}Certbot is not installed. Please install it first.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Get domains
    echo -e "${YELLOW}Enter domain(s) for the certificate:${NC}"
    echo -e "${CYAN}(Separate multiple domains with commas)${NC}"
    read -p "Domains: " DOMAINS_INPUT
    
    # Get email
    read -p "Email address: " EMAIL
    
    # Build domain arguments
    domain_args=""
    IFS=',' read -r -a DOMAINS <<< "$DOMAINS_INPUT"
    for domain in "${DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs) # trim whitespace
        if [ -n "$domain" ]; then
            domain_args="$domain_args -d $domain"
        fi
    done
    
    # Select method
    echo -e "\n${YELLOW}Select certificate obtaining method:${NC}"
    echo "1. Automatic (recommended - uses web server plugin)"
    echo "2. Standalone (temporarily stops web server)"
    echo "3. Webroot (manual webroot path)"
    echo "4. DNS challenge (manual DNS records)"
    read -p "Choice [1-4]: " method_choice
    
    case $method_choice in
        1)
            if [ "$SERVER" = "nginx" ]; then
                echo -e "\n${BLUE}Using Nginx plugin...${NC}"
                sudo certbot --nginx $domain_args --email "$EMAIL" --agree-tos --redirect --non-interactive
            elif [ "$SERVER" = "apache" ]; then
                echo -e "\n${BLUE}Using Apache plugin...${NC}"
                sudo certbot --apache $domain_args --email "$EMAIL" --agree-tos --redirect --non-interactive
            else
                echo -e "${RED}No supported web server detected!${NC}"
                read -p "Press Enter to continue..."
                return
            fi
            ;;
        2)
            echo -e "\n${YELLOW}Stopping web servers...${NC}"
            sudo systemctl stop nginx apache2 httpd 2>/dev/null
            sudo certbot certonly --standalone $domain_args --email "$EMAIL" --agree-tos --non-interactive
            echo -e "${YELLOW}Starting web servers...${NC}"
            sudo systemctl start nginx apache2 httpd 2>/dev/null
            ;;
        3)
            read -p "Enter webroot path (e.g., /var/www/html): " WEBROOT
            sudo certbot certonly --webroot -w "$WEBROOT" $domain_args --email "$EMAIL" --agree-tos --non-interactive
            ;;
        4)
            echo -e "\n${BLUE}Using DNS challenge (manual)...${NC}"
            sudo certbot certonly --manual --preferred-challenges dns $domain_args --email "$EMAIL" --agree-tos
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            read -p "Press Enter to continue..."
            return
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}✓ Certificate obtained successfully!${NC}"
        
        # Offer auto-renewal setup
        read -p "Enable automatic renewal? (y/n): " AUTORENEW
        if [[ "$AUTORENEW" =~ ^[Yy]$ ]]; then
            setup_auto_renewal_silent
        fi
    else
        echo -e "\n${RED}✗ Failed to obtain certificate.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Renew certificates
renew_certificates() {
    echo -e "${BLUE}═══ Renew SSL Certificates ═══${NC}\n"
    
    if ! command -v certbot >/dev/null 2>&1; then
        echo -e "${RED}Certbot is not installed.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${YELLOW}Select renewal method:${NC}"
    echo "1. Standard renewal (all certificates)"
    echo "2. Dry run (test renewal without actually renewing)"
    [[ $HAS_NGINX -eq 1 ]] && echo "3. Nginx plugin renewal"
    [[ $HAS_APACHE -eq 1 ]] && echo "4. Apache plugin renewal"
    echo "5. Standalone mode (stops web server temporarily)"
    echo "6. Force renewal (even if not due)"
    read -p "Choice: " method_choice
    
    case $method_choice in
        1)
            echo -e "\n${BLUE}Running standard renewal...${NC}"
            sudo certbot renew
            ;;
        2)
            echo -e "\n${BLUE}Running dry run...${NC}"
            sudo certbot renew --dry-run
            ;;
        3)
            if [ "$HAS_NGINX" -eq 1 ]; then
                echo -e "\n${BLUE}Renewing with Nginx plugin...${NC}"
                sudo certbot renew --nginx
            else
                echo -e "${RED}Nginx not found!${NC}"
            fi
            ;;
        4)
            if [ "$HAS_APACHE" -eq 1 ]; then
                echo -e "\n${BLUE}Renewing with Apache plugin...${NC}"
                sudo certbot renew --apache
            else
                echo -e "${RED}Apache not found!${NC}"
            fi
            ;;
        5)
            echo -e "\n${YELLOW}Stopping web servers...${NC}"
            sudo systemctl stop nginx apache2 httpd 2>/dev/null
            sudo certbot renew --standalone
            echo -e "${YELLOW}Starting web servers...${NC}"
            sudo systemctl start nginx apache2 httpd 2>/dev/null
            ;;
        6)
            echo -e "\n${BLUE}Force renewing all certificates...${NC}"
            sudo certbot renew --force-renewal
            ;;
        *)
            echo -e "${RED}Invalid choice!${NC}"
            ;;
    esac
    
    echo -e "\n${GREEN}Renewal process completed.${NC}"
    read -p "Press Enter to continue..."
}

# List certificates
list_certificates() {
    echo -e "${BLUE}═══ Installed SSL Certificates ═══${NC}\n"
    
    if ! command -v certbot >/dev/null 2>&1; then
        echo -e "${RED}Certbot is not installed.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    sudo certbot certificates
    
    echo ""
    read -p "Press Enter to continue..."
}

# Delete certificate
delete_certificate() {
    echo -e "${BLUE}═══ Delete SSL Certificate ═══${NC}\n"
    
    if ! command -v certbot >/dev/null 2>&1; then
        echo -e "${RED}Certbot is not installed.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${YELLOW}Available certificates:${NC}\n"
    sudo certbot certificates
    
    echo -e "\n${RED}WARNING: This will permanently delete the certificate!${NC}"
    read -p "Enter certificate name to delete: " CERT_NAME
    
    if [ -z "$CERT_NAME" ]; then
        echo -e "${RED}No certificate name provided.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -p "Are you sure you want to delete '$CERT_NAME'? (yes/no): " CONFIRM
    if [ "$CONFIRM" = "yes" ]; then
        sudo certbot delete --cert-name "$CERT_NAME"
        echo -e "${GREEN}Certificate deleted.${NC}"
    else
        echo -e "${YELLOW}Deletion cancelled.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Expand certificate (add domains)
expand_certificate() {
    echo -e "${BLUE}═══ Expand Certificate (Add Domains) ═══${NC}\n"
    
    if ! command -v certbot >/dev/null 2>&1; then
        echo -e "${RED}Certbot is not installed.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${YELLOW}Available certificates:${NC}\n"
    sudo certbot certificates
    
    read -p "\nEnter certificate name to expand: " CERT_NAME
    read -p "Enter additional domains (comma-separated): " NEW_DOMAINS
    
    # Build domain arguments
    domain_args=""
    IFS=',' read -r -a DOMAINS <<< "$NEW_DOMAINS"
    for domain in "${DOMAINS[@]}"; do
        domain=$(echo "$domain" | xargs)
        if [ -n "$domain" ]; then
            domain_args="$domain_args -d $domain"
        fi
    done
    
    if [ "$SERVER" = "nginx" ]; then
        sudo certbot --nginx --cert-name "$CERT_NAME" $domain_args --expand
    elif [ "$SERVER" = "apache" ]; then
        sudo certbot --apache --cert-name "$CERT_NAME" $domain_args --expand
    else
        echo -e "${RED}No supported web server detected!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}✓ Certificate expanded successfully!${NC}"
    else
        echo -e "\n${RED}✗ Failed to expand certificate.${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Setup auto-renewal (silent for internal use)
setup_auto_renewal_silent() {
    CRON_CMD="certbot renew --quiet"
    if ! crontab -l 2>/dev/null | grep -q "$CRON_CMD"; then
        (crontab -l 2>/dev/null; echo "0 3 * * * $CRON_CMD") | crontab -
        echo -e "${GREEN}✓ Auto-renewal enabled (daily at 3:00 AM)${NC}"
    fi
}

# Manage auto-renewal
manage_auto_renewal() {
    echo -e "${BLUE}═══ Auto-Renewal Configuration ═══${NC}\n"
    
    CRON_CMD="certbot renew --quiet"
    
    # Check current status
    if crontab -l 2>/dev/null | grep -q "$CRON_CMD"; then
        echo -e "${GREEN}Auto-renewal is currently: ENABLED ✓${NC}"
        echo -e "${CYAN}Current schedule:${NC}"
        crontab -l 2>/dev/null | grep "$CRON_CMD"
        echo ""
        echo "1. Disable auto-renewal"
        echo "2. Change schedule"
        echo "0. Back"
        read -p "Choice: " choice
        
        case $choice in
            1)
                crontab -l 2>/dev/null | grep -v "$CRON_CMD" | crontab -
                echo -e "${YELLOW}Auto-renewal disabled.${NC}"
                ;;
            2)
                echo -e "\n${YELLOW}Enter new schedule:${NC}"
                read -p "Minute (0-59): " minute
                read -p "Hour (0-23): " hour
                read -p "Day of month (1-31, or *): " day
                read -p "Month (1-12, or *): " month
                read -p "Day of week (0-7, or *): " weekday
                
                crontab -l 2>/dev/null | grep -v "$CRON_CMD" | crontab -
                (crontab -l 2>/dev/null; echo "$minute $hour $day $month $weekday $CRON_CMD") | crontab -
                echo -e "${GREEN}Schedule updated!${NC}"
                ;;
        esac
    else
        echo -e "${RED}Auto-renewal is currently: DISABLED ✗${NC}\n"
        echo "1. Enable auto-renewal (daily at 3:00 AM)"
        echo "2. Enable with custom schedule"
        echo "0. Back"
        read -p "Choice: " choice
        
        case $choice in
            1)
                (crontab -l 2>/dev/null; echo "0 3 * * * $CRON_CMD") | crontab -
                echo -e "${GREEN}✓ Auto-renewal enabled (daily at 3:00 AM)${NC}"
                ;;
            2)
                echo -e "\n${YELLOW}Enter custom schedule:${NC}"
                read -p "Minute (0-59): " minute
                read -p "Hour (0-23): " hour
                read -p "Day of month (1-31, or *): " day
                read -p "Month (1-12, or *): " month
                read -p "Day of week (0-7, or *): " weekday
                
                (crontab -l 2>/dev/null; echo "$minute $hour $day $month $weekday $CRON_CMD") | crontab -
                echo -e "${GREEN}✓ Auto-renewal enabled with custom schedule${NC}"
                ;;
        esac
    fi
    
    read -p "\nPress Enter to continue..."
}

# Test certificate
test_certificate() {
    echo -e "${BLUE}═══ Test SSL Certificate ═══${NC}\n"
    
    read -p "Enter domain to test: " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}No domain provided.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "\n${YELLOW}Testing SSL certificate for $DOMAIN...${NC}\n"
    
    # Test with openssl
    echo -e "${CYAN}Certificate details:${NC}"
    echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -dates -subject -issuer
    
    echo -e "\n${CYAN}Certificate chain:${NC}"
    echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | grep -A 2 "Certificate chain"
    
    # Test with SSL Labs (if curl available)
    if command -v curl >/dev/null 2>&1; then
        echo -e "\n${CYAN}For detailed analysis, visit:${NC}"
        echo -e "${BLUE}https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN${NC}"
    fi
    
    read -p "\nPress Enter to continue..."
}

# Main menu
main_menu() {
    while true; do
        show_banner
        
        echo -e "${YELLOW}Main Menu:${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${GREEN}1.${NC} Install Certbot"
        echo -e "${GREEN}2.${NC} Obtain New Certificate"
        echo -e "${GREEN}3.${NC} Renew Certificates"
        echo -e "${GREEN}4.${NC} List Certificates"
        echo -e "${GREEN}5.${NC} Expand Certificate (Add Domains)"
        echo -e "${GREEN}6.${NC} Delete Certificate"
        echo -e "${GREEN}7.${NC} Manage Auto-Renewal"
        echo -e "${GREEN}8.${NC} Test Certificate"
        echo -e "${RED}0.${NC} Exit"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        read -p "Select option [0-8]: " choice
        
        case $choice in
            1) install_certbot ;;
            2) obtain_certificate ;;
            3) renew_certificates ;;
            4) list_certificates ;;
            5) expand_certificate ;;
            6) delete_certificate ;;
            7) manage_auto_renewal ;;
            8) test_certificate ;;
            0) 
                echo -e "\n${GREEN}Thank you for using Certbot Manager!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main execution
detect_system
main_menu
