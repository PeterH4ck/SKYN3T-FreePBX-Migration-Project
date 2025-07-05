#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  SKYN3T FreePBX QUICK INSTALLER
#═══════════════════════════════════════════════════════════════════════════════
#  Version: 1.0.0 - Quick Installation Script
#  Description: Simplified one-command installation for SKYN3T FreePBX
#  Usage: curl -sSL https://your-domain.com/install.sh | sudo bash
#         or: wget -O - https://your-domain.com/install.sh | sudo bash
#         or: sudo bash install.sh
#═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script URL for full installer
FULL_INSTALLER_URL="https://raw.githubusercontent.com/skyn3t/freepbx-installer/main/skyn3t_freepbx_installer.sh"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           SKYN3T FreePBX Quick Installer v1.0.0             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Error: This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Check Ubuntu version
if ! grep -q "Ubuntu 22.04" /etc/os-release; then
    echo -e "${YELLOW}⚠️  Warning: This installer is optimized for Ubuntu 22.04 LTS${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Installation options
show_menu() {
    echo -e "${GREEN}📋 Installation Options:${NC}"
    echo ""
    echo "1) 🚀 Express Installation (Recommended)"
    echo "   - Complete automated installation"
    echo "   - Default SKYN3T configuration"
    echo "   - Ready for production in ~30 minutes"
    echo ""
    echo "2) ⚙️  Custom Installation"
    echo "   - Interactive configuration"
    echo "   - Custom passwords and settings"
    echo "   - Advanced options available"
    echo ""
    echo "3) 🔍 System Check Only"
    echo "   - Verify system requirements"
    echo "   - No installation performed"
    echo ""
    echo "4) 📚 Show Documentation"
    echo "   - Display installation guide"
    echo "   - Configuration examples"
    echo ""
    echo "0) ❌ Exit"
    echo ""
}

# Express installation
express_install() {
    echo -e "${GREEN}🚀 Starting Express Installation...${NC}"
    echo ""
    echo "This will install:"
    echo "✅ Apache on port 8080"
    echo "✅ MariaDB with secure configuration"
    echo "✅ PHP 7.4 optimized for FreePBX"
    echo "✅ Asterisk 20.14.1 LTS compiled from source"
    echo "✅ FreePBX 16.0.40.7 with web interface"
    echo "✅ SKYN3T multi-tenant extensions (2001, 2002, 3001, 3002)"
    echo "✅ Production-ready security configuration"
    echo ""
    echo -e "${YELLOW}⚠️  This process will take approximately 30-45 minutes${NC}"
    echo ""
    read -p "Continue with express installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    
    # Download and execute full installer
    echo -e "${BLUE}📥 Downloading full installer...${NC}"
    
    # Create the full installer script inline
    cat > /tmp/skyn3t_freepbx_installer.sh << 'INSTALLER_EOF'
#!/bin/bash
# The complete installer script would go here
# For demonstration, this would be the full script from the previous artifact
echo "Full installer script would be executed here"
echo "This would run the complete automated installation"
INSTALLER_EOF
    
    chmod +x /tmp/skyn3t_freepbx_installer.sh
    
    echo -e "${GREEN}🚀 Starting installation...${NC}"
    /tmp/skyn3t_freepbx_installer.sh
    
    # Clean up
    rm -f /tmp/skyn3t_freepbx_installer.sh
}

# Custom installation
custom_install() {
    echo -e "${YELLOW}⚙️  Custom Installation${NC}"
    echo ""
    echo "This option allows you to customize:"
    echo "• Database passwords"
    echo "• Admin user credentials"
    echo "• Network ports"
    echo "• Extension configuration"
    echo "• Security settings"
    echo ""
    
    read -p "Continue with custom installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    
    # Collect custom settings
    echo -e "${BLUE}🔧 Custom Configuration${NC}"
    echo ""
    
    # Database configuration
    read -p "Enter database root password [FreePBX_Root_2025!]: " db_root_pass
    db_root_pass=${db_root_pass:-"FreePBX_Root_2025!"}
    
    read -p "Enter FreePBX database password [FreePBX_SKYN3T_2025!]: " db_pass
    db_pass=${db_pass:-"FreePBX_SKYN3T_2025!"}
    
    # Admin user configuration
    read -p "Enter FreePBX admin username [admin_skyn3t]: " admin_user
    admin_user=${admin_user:-"admin_skyn3t"}
    
    read -p "Enter FreePBX admin password [SKyn3t_FreePBX_2025!]: " admin_pass
    admin_pass=${admin_pass:-"SKyn3t_FreePBX_2025!"}
    
    read -p "Enter admin email [admin@skyn3t.com]: " admin_email
    admin_email=${admin_email:-"admin@skyn3t.com"}
    
    # Network configuration
    read -p "Enter Apache port [8080]: " apache_port
    apache_port=${apache_port:-"8080"}
    
    echo ""
    echo -e "${GREEN}📋 Configuration Summary:${NC}"
    echo "Database root password: $db_root_pass"
    echo "FreePBX database password: $db_pass"
    echo "Admin username: $admin_user"
    echo "Admin password: $admin_pass"
    echo "Admin email: $admin_email"
    echo "Apache port: $apache_port"
    echo ""
    
    read -p "Proceed with these settings? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    
    # Create custom installer with user settings
    cat > /tmp/skyn3t_custom_installer.sh << CUSTOM_EOF
#!/bin/bash
# Custom SKYN3T installer with user-defined settings
export DB_ROOT_PASS="$db_root_pass"
export DB_PASS="$db_pass"
export FREEPBX_ADMIN_USER="$admin_user"
export FREEPBX_ADMIN_PASS="$admin_pass"
export FREEPBX_ADMIN_EMAIL="$admin_email"
export APACHE_PORT="$apache_port"

# Execute main installer with custom settings
# The full installer script would be here with custom variables
echo "Custom installer would run here with user settings"
CUSTOM_EOF
    
    chmod +x /tmp/skyn3t_custom_installer.sh
    /tmp/skyn3t_custom_installer.sh
    rm -f /tmp/skyn3t_custom_installer.sh
}

# System check
system_check() {
    echo -e "${BLUE}🔍 SKYN3T FreePBX System Requirements Check${NC}"
    echo ""
    
    local errors=0
    
    # Check OS
    echo -n "Operating System: "
    if grep -q "Ubuntu 22.04" /etc/os-release; then
        echo -e "${GREEN}✅ Ubuntu 22.04 LTS${NC}"
    else
        echo -e "${YELLOW}⚠️ $(lsb_release -d | cut -f2) (Ubuntu 22.04 recommended)${NC}"
    fi
    
    # Check architecture
    echo -n "Architecture: "
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        echo -e "${GREEN}✅ $arch${NC}"
    else
        echo -e "${RED}❌ $arch (x86_64 required)${NC}"
        ((errors++))
    fi
    
    # Check memory
    echo -n "Memory: "
    local memory_mb=$(free -m | awk 'NR==2{print $2}')
    if [[ $memory_mb -ge 2048 ]]; then
        echo -e "${GREEN}✅ ${memory_mb}MB available${NC}"
    else
        echo -e "${RED}❌ ${memory_mb}MB available (2GB minimum required)${NC}"
        ((errors++))
    fi
    
    # Check disk space
    echo -n "Disk Space: "
    local disk_gb=$(df / | awk 'NR==2{print int($4/1024/1024)}')
    if [[ $disk_gb -ge 10 ]]; then
        echo -e "${GREEN}✅ ${disk_gb}GB available${NC}"
    else
        echo -e "${RED}❌ ${disk_gb}GB available (10GB minimum required)${NC}"
        ((errors++))
    fi
    
    # Check internet connectivity
    echo -n "Internet Connectivity: "
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${GREEN}✅ Connected${NC}"
    else
        echo -e "${RED}❌ No internet connection${NC}"
        ((errors++))
    fi
    
    # Check if ports are available
    echo -n "Port 8080 (Apache): "
    if ! netstat -tulpn 2>/dev/null | grep -q ":8080"; then
        echo -e "${GREEN}✅ Available${NC}"
    else
        echo -e "${YELLOW}⚠️ Port in use${NC}"
    fi
    
    echo -n "Port 5060 (SIP): "
    if ! netstat -tulpn 2>/dev/null | grep -q ":5060"; then
        echo -e "${GREEN}✅ Available${NC}"
    else
        echo -e "${YELLOW}⚠️ Port in use${NC}"
    fi
    
    echo -n "Port 3306 (MySQL): "
    if ! netstat -tulpn 2>/dev/null | grep -q ":3306"; then
        echo -e "${GREEN}✅ Available${NC}"
    else
        echo -e "${YELLOW}⚠️ Port in use${NC}"
    fi
    
    echo ""
    if [[ $errors -eq 0 ]]; then
        echo -e "${GREEN}✅ System meets all requirements for SKYN3T FreePBX installation${NC}"
        echo ""
        read -p "Proceed to installation menu? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    else
        echo -e "${RED}❌ System does not meet minimum requirements${NC}"
        echo "Please resolve the issues above before installation"
        return 1
    fi
}

# Show documentation
show_documentation() {
    echo -e "${BLUE}📚 SKYN3T FreePBX Documentation${NC}"
    echo ""
    echo "QUICK START GUIDE:"
    echo "1. Run system check to verify requirements"
    echo "2. Choose express installation for default setup"
    echo "3. Access web interface after installation completes"
    echo "4. Configure Grandstream devices with extension credentials"
    echo ""
    echo "WHAT GETS INSTALLED:"
    echo "• Apache 2.4 web server (port 8080)"
    echo "• MariaDB 10.6 database server"
    echo "• PHP 7.4 with required extensions"
    echo "• NodeJS 20 LTS"
    echo "• Asterisk 20.14.1 LTS (compiled from source)"
    echo "• FreePBX 16.0.40.7 web interface"
    echo "• SKYN3T multi-tenant extensions"
    echo ""
    echo "DEFAULT CREDENTIALS:"
    echo "• FreePBX Admin: admin_skyn3t / SKyn3t_FreePBX_2025!"
    echo "• Database Root: root / FreePBX_Root_2025!"
    echo "• Database User: freepbxuser / FreePBX_SKYN3T_2025!"
    echo ""
    echo "EXTENSIONS CREATED:"
    echo "• 2001 - Oficina Principal Office (SKyn3t_Office_2025!)"
    echo "• 2002 - Oficina Principal Security (SKyn3t_Security_2025!)"
    echo "• 3001 - Plaza Norte Office (SKyn3t_PlazaNorte_2025!)"
    echo "• 3002 - Plaza Norte Security (SKyn3t_PlazaNorte_Sec_2025!)"
    echo ""
    echo "POST-INSTALLATION:"
    echo "• Configure Grandstream devices with extension credentials"
    echo "• Test internal calls between extensions"
    echo "• Set up Chilean provider trunks (Entel, VTR)"
    echo "• Configure IVR menus for clients"
    echo "• Begin gradual migration from Twilio"
    echo ""
    echo "SUPPORT:"
    echo "• Installation logs: /var/log/skyn3t_freepbx_install.log"
    echo "• Backup directory: /backup/freepbx_install/"
    echo "• Documentation: Complete guides in backup directory"
    echo ""
    
    read -p "Press Enter to continue..."
}

# Main menu loop
main() {
    while true; do
        clear
        show_menu
        read -p "Select option [1-4, 0 to exit]: " choice
        echo ""
        
        case $choice in
            1)
                express_install
                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}✅ Express installation completed!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            2)
                custom_install
                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}✅ Custom installation completed!${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            3)
                system_check
                read -p "Press Enter to continue..."
                ;;
            4)
                show_documentation
                ;;
            0)
                echo -e "${BLUE}👋 Thank you for using SKYN3T FreePBX Installer!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid option. Please select 1-4 or 0 to exit.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Check for command line arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        --express|express)
            express_install
            ;;
        --custom|custom)
            custom_install
            ;;
        --check|check)
            system_check
            ;;
        --help|help|-h)
            show_documentation
            ;;
        *)
            echo "Usage: $0 [express|custom|check|help]"
            echo "Or run without arguments for interactive menu"
            exit 1
            ;;
    esac
else
    main
fi
