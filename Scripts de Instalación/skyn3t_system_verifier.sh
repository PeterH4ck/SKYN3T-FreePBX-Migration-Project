#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  SKYN3T FreePBX SYSTEM VERIFIER & HEALTH CHECK
#═══════════════════════════════════════════════════════════════════════════════
#  Version: 1.0.0
#  Description: Comprehensive system verification and health monitoring
#  Usage: bash verify_system.sh [--detailed] [--fix] [--report]
#═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="/var/log/skyn3t_verification.log"
readonly REPORT_DIR="/backup/freepbx_install/reports"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNING_CHECKS=0
FAILED_CHECKS=0

# Flags
DETAILED_OUTPUT=false
AUTO_FIX=false
GENERATE_REPORT=false

#═══════════════════════════════════════════════════════════════════════════════
#  UTILITY FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [$level] $message" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "${BLUE}$*${NC}"; }
log_success() { log "SUCCESS" "${GREEN}✅ $*${NC}"; }
log_warning() { log "WARNING" "${YELLOW}⚠️ $*${NC}"; }
log_error() { log "ERROR" "${RED}❌ $*${NC}"; }
log_debug() { log "DEBUG" "${CYAN}🔍 $*${NC}"; }

check_start() {
    local description="$1"
    ((TOTAL_CHECKS++))
    if $DETAILED_OUTPUT; then
        echo -e "${CYAN}🔍 Checking: $description${NC}"
    fi
}

check_pass() {
    local description="$1"
    ((PASSED_CHECKS++))
    log_success "$description"
}

check_warning() {
    local description="$1"
    local details="${2:-}"
    ((WARNING_CHECKS++))
    log_warning "$description"
    if [[ -n "$details" ]] && $DETAILED_OUTPUT; then
        echo -e "   ${YELLOW}Details: $details${NC}"
    fi
}

check_fail() {
    local description="$1"
    local details="${2:-}"
    local fix_command="${3:-}"
    ((FAILED_CHECKS++))
    log_error "$description"
    if [[ -n "$details" ]] && $DETAILED_OUTPUT; then
        echo -e "   ${RED}Details: $details${NC}"
    fi
    if [[ -n "$fix_command" ]] && $DETAILED_OUTPUT; then
        echo -e "   ${BLUE}Fix: $fix_command${NC}"
        if $AUTO_FIX; then
            echo -e "   ${YELLOW}Attempting automatic fix...${NC}"
            eval "$fix_command" || echo -e "   ${RED}Auto-fix failed${NC}"
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  SYSTEM VERIFICATION FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

verify_system_requirements() {
    echo -e "${BLUE}═══ SYSTEM REQUIREMENTS VERIFICATION ═══${NC}"
    
    # Operating System
    check_start "Operating System compatibility"
    if grep -q "Ubuntu" /etc/os-release; then
        local ubuntu_version=$(lsb_release -r | awk '{print $2}')
        if [[ "$ubuntu_version" == "22.04" ]]; then
            check_pass "Ubuntu 22.04 LTS detected"
        else
            check_warning "Ubuntu $ubuntu_version detected" "Ubuntu 22.04 LTS is recommended"
        fi
    else
        check_warning "Non-Ubuntu system detected" "$(lsb_release -d | cut -f2)"
    fi
    
    # Architecture
    check_start "System architecture"
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        check_pass "x86_64 architecture supported"
    else
        check_fail "Unsupported architecture: $arch" "x86_64 required"
    fi
    
    # Memory
    check_start "Available memory"
    local memory_mb=$(free -m | awk 'NR==2{print $2}')
    if [[ $memory_mb -ge 4096 ]]; then
        check_pass "Memory: ${memory_mb}MB (Excellent)"
    elif [[ $memory_mb -ge 2048 ]]; then
        check_pass "Memory: ${memory_mb}MB (Good)"
    elif [[ $memory_mb -ge 1024 ]]; then
        check_warning "Memory: ${memory_mb}MB (Minimum)" "2GB+ recommended for production"
    else
        check_fail "Memory: ${memory_mb}MB (Insufficient)" "Minimum 1GB required" "Consider upgrading memory"
    fi
    
    # Disk Space
    check_start "Available disk space"
    local disk_gb=$(df / | awk 'NR==2{print int($4/1024/1024)}')
    if [[ $disk_gb -ge 50 ]]; then
        check_pass "Disk Space: ${disk_gb}GB (Excellent)"
    elif [[ $disk_gb -ge 20 ]]; then
        check_pass "Disk Space: ${disk_gb}GB (Good)"
    elif [[ $disk_gb -ge 10 ]]; then
        check_warning "Disk Space: ${disk_gb}GB (Minimum)" "20GB+ recommended for logs and backups"
    else
        check_fail "Disk Space: ${disk_gb}GB (Insufficient)" "Minimum 10GB required" "Clean up disk space or add storage"
    fi
    
    # CPU Cores
    check_start "CPU cores"
    local cpu_cores=$(nproc)
    if [[ $cpu_cores -ge 4 ]]; then
        check_pass "CPU Cores: $cpu_cores (Excellent)"
    elif [[ $cpu_cores -ge 2 ]]; then
        check_pass "CPU Cores: $cpu_cores (Good)"
    else
        check_warning "CPU Cores: $cpu_cores (Minimum)" "2+ cores recommended for production"
    fi
}

verify_services() {
    echo -e "${BLUE}═══ SERVICES VERIFICATION ═══${NC}"
    
    local services=("apache2" "mariadb" "asterisk")
    
    for service in "${services[@]}"; do
        check_start "$service service status"
        if systemctl is-active --quiet "$service"; then
            local uptime=$(systemctl show "$service" --property=ActiveEnterTimestamp --value)
            check_pass "$service is running (since $uptime)"
        else
            check_fail "$service is not running" "Service should be active" "systemctl start $service"
        fi
        
        check_start "$service service auto-start"
        if systemctl is-enabled --quiet "$service"; then
            check_pass "$service auto-start enabled"
        else
            check_warning "$service auto-start disabled" "Service won't start on boot" "systemctl enable $service"
        fi
    done
}

verify_network_ports() {
    echo -e "${BLUE}═══ NETWORK PORTS VERIFICATION ═══${NC}"
    
    local ports=(
        "8080:Apache Web Server"
        "5060:Asterisk SIP"
        "5038:Asterisk Manager"
        "3306:MariaDB Database"
    )
    
    for port_info in "${ports[@]}"; do
        IFS=':' read -r port service <<< "$port_info"
        check_start "$service port $port"
        
        if netstat -tulpn 2>/dev/null | grep -q ":$port "; then
            local process=$(netstat -tulpn 2>/dev/null | grep ":$port " | awk '{print $7}' | head -1)
            check_pass "$service listening on port $port ($process)"
        else
            check_fail "$service not listening on port $port" "Port should be active" "Check service configuration"
        fi
    done
    
    # Check for port conflicts
    check_start "Port conflicts"
    local conflicts=0
    for port in 80 443 8080 5060 5038 3306; do
        local count=$(netstat -tulpn 2>/dev/null | grep -c ":$port " || true)
        if [[ $count -gt 1 ]]; then
            check_warning "Multiple services on port $port" "$count services detected"
            ((conflicts++))
        fi
    done
    
    if [[ $conflicts -eq 0 ]]; then
        check_pass "No port conflicts detected"
    fi
}

verify_asterisk_configuration() {
    echo -e "${BLUE}═══ ASTERISK CONFIGURATION VERIFICATION ═══${NC}"
    
    # Asterisk version
    check_start "Asterisk version"
    if command -v asterisk &> /dev/null; then
        local ast_version=$(asterisk -rx "core show version" 2>/dev/null | head -1 || echo "Unknown")
        if [[ "$ast_version" =~ "Asterisk 20" ]]; then
            check_pass "Asterisk 20 LTS detected: $ast_version"
        else
            check_warning "Non-LTS Asterisk version" "$ast_version"
        fi
    else
        check_fail "Asterisk not installed" "Asterisk binary not found"
    fi
    
    # PJSIP endpoints
    check_start "PJSIP endpoints"
    local endpoint_count=$(asterisk -rx "pjsip show endpoints" 2>/dev/null | grep -c "Endpoint:" || echo "0")
    if [[ $endpoint_count -gt 0 ]]; then
        check_pass "$endpoint_count PJSIP endpoints configured"
    else
        check_warning "No PJSIP endpoints found" "Extensions may not be configured"
    fi
    
    # Asterisk modules
    check_start "Critical Asterisk modules"
    local critical_modules=("res_pjsip.so" "chan_pjsip.so" "app_dial.so" "app_voicemail.so")
    local missing_modules=()
    
    for module in "${critical_modules[@]}"; do
        if ! asterisk -rx "module show like $module" 2>/dev/null | grep -q "Running"; then
            missing_modules+=("$module")
        fi
    done
    
    if [[ ${#missing_modules[@]} -eq 0 ]]; then
        check_pass "All critical modules loaded"
    else
        check_fail "Missing modules: ${missing_modules[*]}" "Critical modules not loaded" "module load <module_name>"
    fi
    
    # Dialplan
    check_start "Dialplan configuration"
    local context_count=$(asterisk -rx "dialplan show" 2>/dev/null | grep -c "Context" || echo "0")
    if [[ $context_count -gt 0 ]]; then
        check_pass "$context_count dialplan contexts configured"
    else
        check_warning "No dialplan contexts found" "Call routing may not work"
    fi
    
    # Manager interface
    check_start "Asterisk Manager interface"
    if asterisk -rx "manager show users" 2>/dev/null | grep -q "freepbxuser\|admin"; then
        check_pass "Manager interface configured"
    else
        check_fail "Manager interface not configured" "FreePBX communication may fail" "Check manager.conf"
    fi
}

verify_freepbx_installation() {
    echo -e "${BLUE}═══ FREEPBX INSTALLATION VERIFICATION ═══${NC}"
    
    # FreePBX files
    check_start "FreePBX installation files"
    if [[ -d "/var/www/html/admin" && -f "/etc/freepbx.conf" ]]; then
        check_pass "FreePBX files present"
    else
        check_fail "FreePBX files missing" "Installation may be incomplete"
    fi
    
    # FreePBX configuration
    check_start "FreePBX configuration"
    if [[ -f "/etc/freepbx.conf" && -f "/etc/amportal.conf" ]]; then
        check_pass "FreePBX configuration files present"
    else
        check_fail "FreePBX configuration missing" "Configuration files not found"
    fi
    
    # Web interface accessibility
    check_start "FreePBX web interface"
    local web_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/admin/ 2>/dev/null || echo "000")
    if [[ "$web_response" == "200" ]]; then
        check_pass "Web interface accessible (HTTP 200)"
    elif [[ "$web_response" == "302" || "$web_response" == "301" ]]; then
        check_pass "Web interface accessible (HTTP $web_response - redirect)"
    else
        check_fail "Web interface not accessible" "HTTP response: $web_response" "Check Apache configuration"
    fi
    
    # FreePBX database connection
    check_start "FreePBX database connection"
    if mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' -e "USE freepbx_skyn3t; SELECT COUNT(*) FROM information_schema.tables;" &>/dev/null; then
        local table_count=$(mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' -e "USE freepbx_skyn3t; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='freepbx_skyn3t';" -s -N 2>/dev/null)
        check_pass "Database connection working ($table_count tables)"
    else
        check_fail "Database connection failed" "Cannot connect to FreePBX database" "Check database credentials"
    fi
    
    # FreePBX modules
    check_start "FreePBX modules"
    local module_count=$(sudo -u asterisk fwconsole ma list 2>/dev/null | grep -c "Enabled" || echo "0")
    if [[ $module_count -gt 10 ]]; then
        check_pass "$module_count FreePBX modules enabled"
    elif [[ $module_count -gt 0 ]]; then
        check_warning "$module_count FreePBX modules enabled" "Some modules may be missing"
    else
        check_fail "No FreePBX modules enabled" "FreePBX may not be properly installed"
    fi
}

verify_php_configuration() {
    echo -e "${BLUE}═══ PHP CONFIGURATION VERIFICATION ═══${NC}"
    
    # PHP version
    check_start "PHP version"
    local php_version=$(php -v | head -1 | awk '{print $2}' || echo "Unknown")
    if [[ "$php_version" =~ ^7\.4 ]]; then
        check_pass "PHP 7.4 installed: $php_version"
    elif [[ "$php_version" =~ ^7\. ]]; then
        check_warning "PHP 7.x installed: $php_version" "PHP 7.4 recommended for FreePBX"
    else
        check_fail "Incompatible PHP version: $php_version" "PHP 7.4 required for FreePBX 16.0"
    fi
    
    # PHP extensions
    check_start "Required PHP extensions"
    local required_extensions=("mysql" "xml" "zip" "curl" "mbstring" "gd" "json")
    local missing_extensions=()
    
    for ext in "${required_extensions[@]}"; do
        if ! php -m | grep -q "^$ext$"; then
            missing_extensions+=("$ext")
        fi
    done
    
    if [[ ${#missing_extensions[@]} -eq 0 ]]; then
        check_pass "All required PHP extensions present"
    else
        check_fail "Missing PHP extensions: ${missing_extensions[*]}" "FreePBX may not function properly" "apt install php7.4-{mysql,xml,zip,curl,mbstring,gd}"
    fi
    
    # PHP configuration
    check_start "PHP memory limit"
    local memory_limit=$(php -r "echo ini_get('memory_limit');" 2>/dev/null || echo "Unknown")
    local memory_value=$(echo "$memory_limit" | sed 's/M$//' | sed 's/G$/000/')
    if [[ "$memory_value" -ge 256 ]]; then
        check_pass "PHP memory limit: $memory_limit"
    else
        check_warning "PHP memory limit: $memory_limit" "256M recommended" "Increase memory_limit in php.ini"
    fi
    
    # PHP session configuration
    check_start "PHP session configuration"
    if [[ -d "/var/lib/asterisk/sessions" ]]; then
        local session_perms=$(stat -c "%a" /var/lib/asterisk/sessions 2>/dev/null || echo "000")
        if [[ "$session_perms" =~ ^[67][67][57]$ ]]; then
            check_pass "PHP sessions directory properly configured"
        else
            check_warning "PHP sessions directory permissions: $session_perms" "Should be 775 or similar"
        fi
    else
        check_fail "PHP sessions directory missing" "/var/lib/asterisk/sessions not found" "mkdir -p /var/lib/asterisk/sessions && chown asterisk:www-data /var/lib/asterisk/sessions"
    fi
}

verify_database_configuration() {
    echo -e "${BLUE}═══ DATABASE CONFIGURATION VERIFICATION ═══${NC}"
    
    # MariaDB version
    check_start "MariaDB version"
    local db_version=$(mysql --version | awk '{print $5}' | sed 's/,$//' || echo "Unknown")
    if [[ "$db_version" =~ ^10\.[6-9] ]]; then
        check_pass "MariaDB version: $db_version"
    elif [[ "$db_version" =~ ^10\. ]]; then
        check_warning "MariaDB version: $db_version" "10.6+ recommended"
    else
        check_warning "Database version: $db_version" "MariaDB 10.6+ recommended"
    fi
    
    # Database connectivity
    check_start "Database root connection"
    if mysql -u root -p'FreePBX_Root_2025!' -e "SELECT 1;" &>/dev/null; then
        check_pass "Database root connection working"
    else
        check_fail "Database root connection failed" "Cannot connect as root" "Check root password"
    fi
    
    # FreePBX database
    check_start "FreePBX database"
    if mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' -e "USE freepbx_skyn3t; SELECT 1;" &>/dev/null; then
        check_pass "FreePBX database accessible"
    else
        check_fail "FreePBX database not accessible" "Database or user may not exist" "Check database configuration"
    fi
    
    # Database size and tables
    check_start "Database tables"
    local table_count=$(mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' -e "USE freepbx_skyn3t; SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='freepbx_skyn3t';" -s -N 2>/dev/null || echo "0")
    if [[ $table_count -gt 50 ]]; then
        check_pass "Database tables: $table_count (Complete installation)"
    elif [[ $table_count -gt 20 ]]; then
        check_warning "Database tables: $table_count (Partial installation)"
    else
        check_fail "Database tables: $table_count (Incomplete installation)" "FreePBX installation may be incomplete"
    fi
}

verify_security_configuration() {
    echo -e "${BLUE}═══ SECURITY CONFIGURATION VERIFICATION ═══${NC}"
    
    # File permissions
    check_start "Critical file permissions"
    local permission_issues=()
    
    # Check /etc/asterisk permissions
    if [[ -d "/etc/asterisk" ]]; then
        local asterisk_owner=$(stat -c "%U:%G" /etc/asterisk 2>/dev/null || echo "unknown")
        if [[ "$asterisk_owner" == "asterisk:asterisk" ]]; then
            check_pass "Asterisk configuration ownership correct"
        else
            permission_issues+=("/etc/asterisk ownership: $asterisk_owner")
        fi
    fi
    
    # Check FreePBX web directory permissions
    if [[ -d "/var/www/html/admin" ]]; then
        local web_owner=$(stat -c "%U:%G" /var/www/html/admin 2>/dev/null || echo "unknown")
        if [[ "$web_owner" =~ asterisk:.*data ]]; then
            check_pass "FreePBX web directory ownership correct"
        else
            permission_issues+=("/var/www/html/admin ownership: $web_owner")
        fi
    fi
    
    if [[ ${#permission_issues[@]} -gt 0 ]]; then
        check_warning "Permission issues found" "${permission_issues[*]}" "Run fwconsole chown"
    fi
    
    # Firewall status
    check_start "Firewall configuration"
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status 2>/dev/null | head -1 || echo "unknown")
        if [[ "$ufw_status" =~ "active" ]]; then
            check_pass "UFW firewall active"
        else
            check_warning "UFW firewall inactive" "Consider enabling firewall for production"
        fi
    else
        check_warning "UFW not installed" "Consider installing firewall for production"
    fi
    
    # Default passwords
    check_start "Default password usage"
    local default_passwords=()
    
    # Check if admin user exists with default password
    if mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' -e "USE freepbx_skyn3t; SELECT username FROM userman_users WHERE username='admin';" -s -N 2>/dev/null | grep -q "admin"; then
        default_passwords+=("Default admin user exists")
    fi
    
    if [[ ${#default_passwords[@]} -gt 0 ]]; then
        check_warning "Default passwords detected" "${default_passwords[*]}" "Change default passwords"
    else
        check_pass "No obvious default passwords detected"
    fi
}

verify_extensions_configuration() {
    echo -e "${BLUE}═══ EXTENSIONS CONFIGURATION VERIFICATION ═══${NC}"
    
    # SKYN3T extensions
    check_start "SKYN3T extensions"
    local extensions=("2001" "2002" "3001" "3002")
    local configured_extensions=()
    local missing_extensions=()
    
    for ext in "${extensions[@]}"; do
        if asterisk -rx "pjsip show endpoint $ext" 2>/dev/null | grep -q "Endpoint.*$ext"; then
            configured_extensions+=("$ext")
        else
            missing_extensions+=("$ext")
        fi
    done
    
    if [[ ${#configured_extensions[@]} -eq ${#extensions[@]} ]]; then
        check_pass "All SKYN3T extensions configured: ${configured_extensions[*]}"
    elif [[ ${#configured_extensions[@]} -gt 0 ]]; then
        check_warning "Partial extension configuration" "Configured: ${configured_extensions[*]}, Missing: ${missing_extensions[*]}"
    else
        check_fail "No SKYN3T extensions configured" "Extensions not found" "Run extension creation script"
    fi
    
    # Extension authentication
    check_start "Extension authentication"
    local auth_configured=0
    for ext in "${configured_extensions[@]}"; do
        if asterisk -rx "pjsip show auth $ext" 2>/dev/null | grep -q "Auth.*$ext"; then
            ((auth_configured++))
        fi
    done
    
    if [[ $auth_configured -eq ${#configured_extensions[@]} ]]; then
        check_pass "All extensions have authentication configured"
    else
        check_warning "Missing authentication for some extensions" "$((${#configured_extensions[@]} - auth_configured)) extensions missing auth"
    fi
    
    # Voicemail configuration
    check_start "Voicemail configuration"
    if [[ -f "/etc/asterisk/voicemail.conf" ]]; then
        local vm_count=$(grep -c "^[0-9]" /etc/asterisk/voicemail.conf 2>/dev/null || echo "0")
        if [[ $vm_count -gt 0 ]]; then
            check_pass "Voicemail configured for $vm_count extensions"
        else
            check_warning "No voicemail boxes configured" "Voicemail may not work"
        fi
    else
        check_warning "Voicemail configuration file missing" "voicemail.conf not found"
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  PERFORMANCE AND MONITORING
#═══════════════════════════════════════════════════════════════════════════════

verify_performance() {
    echo -e "${BLUE}═══ PERFORMANCE VERIFICATION ═══${NC}"
    
    # System load
    check_start "System load average"
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,$//')
    local cpu_cores=$(nproc)
    local load_threshold=$(echo "$cpu_cores * 0.8" | bc -l)
    
    if (( $(echo "$load_avg < $load_threshold" | bc -l) )); then
        check_pass "System load: $load_avg (${cpu_cores} cores available)"
    else
        check_warning "High system load: $load_avg" "Load above 80% of CPU capacity"
    fi
    
    # Memory usage
    check_start "Memory usage"
    local memory_used=$(free | awk 'NR==2{printf "%.1f", $3*100/$2 }')
    if (( $(echo "$memory_used < 80" | bc -l) )); then
        check_pass "Memory usage: ${memory_used}%"
    elif (( $(echo "$memory_used < 90" | bc -l) )); then
        check_warning "Memory usage: ${memory_used}%" "Memory usage above 80%"
    else
        check_fail "Memory usage: ${memory_used}%" "Critical memory usage" "Consider adding more RAM"
    fi
    
    # Disk usage
    check_start "Disk usage"
    local disk_used=$(df / | awk 'NR==2{print $5}' | sed 's/%$//')
    if [[ $disk_used -lt 80 ]]; then
        check_pass "Disk usage: ${disk_used}%"
    elif [[ $disk_used -lt 90 ]]; then
        check_warning "Disk usage: ${disk_used}%" "Disk usage above 80%"
    else
        check_fail "Disk usage: ${disk_used}%" "Critical disk usage" "Clean up disk space"
    fi
    
    # Process count
    check_start "Running processes"
    local process_count=$(ps aux | wc -l)
    if [[ $process_count -lt 200 ]]; then
        check_pass "Running processes: $process_count"
    elif [[ $process_count -lt 300 ]]; then
        check_warning "Running processes: $process_count" "High process count"
    else
        check_warning "Running processes: $process_count" "Very high process count"
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  REPORTING AND SUMMARY
#═══════════════════════════════════════════════════════════════════════════════

generate_summary_report() {
    local report_file="$REPORT_DIR/system_verification_$(date +%Y%m%d_%H%M%S).txt"
    mkdir -p "$REPORT_DIR"
    
    cat > "$report_file" << EOF
═══════════════════════════════════════════════════════════════════════════════
 SKYN3T FreePBX SYSTEM VERIFICATION REPORT
═══════════════════════════════════════════════════════════════════════════════
 Report Date: $(date)
 Script Version: $SCRIPT_VERSION
 System: $(hostname) - $(uname -a)
 
VERIFICATION SUMMARY:
─────────────────────────────────────────────────────────────────────────────
 Total Checks: $TOTAL_CHECKS
 ✅ Passed: $PASSED_CHECKS
 ⚠️  Warnings: $WARNING_CHECKS
 ❌ Failed: $FAILED_CHECKS
 
 Success Rate: $(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))%
 
SYSTEM STATUS:
─────────────────────────────────────────────────────────────────────────────
EOF
    
    # System information
    echo " Operating System: $(lsb_release -d | cut -f2)" >> "$report_file"
    echo " Kernel: $(uname -r)" >> "$report_file"
    echo " Architecture: $(uname -m)" >> "$report_file"
    echo " Memory: $(free -h | awk 'NR==2{print $2}') total, $(free -h | awk 'NR==2{print $3}') used" >> "$report_file"
    echo " Disk Space: $(df -h / | awk 'NR==2{print $2}') total, $(df -h / | awk 'NR==2{print $3}') used" >> "$report_file"
    echo " Load Average: $(uptime | awk -F'load average:' '{print $2}')" >> "$report_file"
    echo " Uptime: $(uptime -p)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Service status
    echo "SERVICE STATUS:" >> "$report_file"
    echo "─────────────────────────────────────────────────────────────────────────────" >> "$report_file"
    for service in apache2 mariadb asterisk; do
        local status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
        local enabled=$(systemctl is-enabled "$service" 2>/dev/null || echo "disabled")
        echo " $service: $status ($enabled)" >> "$report_file"
    done
    echo "" >> "$report_file"
    
    # Network ports
    echo "NETWORK PORTS:" >> "$report_file"
    echo "─────────────────────────────────────────────────────────────────────────────" >> "$report_file"
    netstat -tulpn 2>/dev/null | grep -E ":(8080|5060|5038|3306) " | while read line; do
        echo " $line" >> "$report_file"
    done
    echo "" >> "$report_file"
    
    # Asterisk information
    if command -v asterisk &> /dev/null; then
        echo "ASTERISK STATUS:" >> "$report_file"
        echo "─────────────────────────────────────────────────────────────────────────────" >> "$report_file"
        echo " Version: $(asterisk -rx "core show version" 2>/dev/null | head -1 || echo "Unknown")" >> "$report_file"
        echo " Uptime: $(asterisk -rx "core show uptime" 2>/dev/null | grep "System uptime" || echo "Unknown")" >> "$report_file"
        echo " Endpoints: $(asterisk -rx "pjsip show endpoints" 2>/dev/null | grep -c "Endpoint:" || echo "0")" >> "$report_file"
        echo " Channels: $(asterisk -rx "core show channels" 2>/dev/null | grep "active channel" || echo "Unknown")" >> "$report_file"
        echo "" >> "$report_file"
    fi
    
    # Recommendations
    echo "RECOMMENDATIONS:" >> "$report_file"
    echo "─────────────────────────────────────────────────────────────────────────────" >> "$report_file"
    if [[ $FAILED_CHECKS -gt 0 ]]; then
        echo " ❌ $FAILED_CHECKS critical issues need immediate attention" >> "$report_file"
        echo " 🔧 Run with --fix flag to attempt automatic fixes" >> "$report_file"
    fi
    if [[ $WARNING_CHECKS -gt 0 ]]; then
        echo " ⚠️  $WARNING_CHECKS warnings should be reviewed" >> "$report_file"
    fi
    if [[ $FAILED_CHECKS -eq 0 && $WARNING_CHECKS -eq 0 ]]; then
        echo " ✅ System is running optimally" >> "$report_file"
        echo " 🎯 Ready for production use" >> "$report_file"
    fi
    echo "" >> "$report_file"
    
    echo "For detailed logs, see: $LOG_FILE" >> "$report_file"
    echo "═══════════════════════════════════════════════════════════════════════════════" >> "$report_file"
    
    chmod 644 "$report_file"
    echo "$report_file"
}

show_summary() {
    echo ""
    echo -e "${WHITE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                         VERIFICATION SUMMARY                                 ${NC}"
    echo -e "${WHITE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "📊 Total Checks: ${BLUE}$TOTAL_CHECKS${NC}"
    echo -e "✅ Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "⚠️  Warnings: ${YELLOW}$WARNING_CHECKS${NC}"
    echo -e "❌ Failed: ${RED}$FAILED_CHECKS${NC}"
    echo ""
    
    local success_rate=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))
    echo -e "📈 Success Rate: "
    if [[ $success_rate -ge 90 ]]; then
        echo -e "${GREEN}$success_rate%${NC} - Excellent"
    elif [[ $success_rate -ge 80 ]]; then
        echo -e "${YELLOW}$success_rate%${NC} - Good"
    elif [[ $success_rate -ge 70 ]]; then
        echo -e "${YELLOW}$success_rate%${NC} - Fair"
    else
        echo -e "${RED}$success_rate%${NC} - Poor"
    fi
    echo ""
    
    # Overall status
    if [[ $FAILED_CHECKS -eq 0 && $WARNING_CHECKS -eq 0 ]]; then
        echo -e "${GREEN}🎉 SYSTEM STATUS: EXCELLENT${NC}"
        echo -e "${GREEN}✅ All checks passed - System ready for production${NC}"
    elif [[ $FAILED_CHECKS -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  SYSTEM STATUS: GOOD WITH WARNINGS${NC}"
        echo -e "${YELLOW}⚠️  $WARNING_CHECKS warnings found - Review recommended${NC}"
    else
        echo -e "${RED}❌ SYSTEM STATUS: ISSUES DETECTED${NC}"
        echo -e "${RED}❌ $FAILED_CHECKS critical issues require attention${NC}"
    fi
    
    echo ""
    
    if $GENERATE_REPORT; then
        local report_file=$(generate_summary_report)
        echo -e "${BLUE}📋 Detailed report generated: $report_file${NC}"
    fi
    
    echo -e "${WHITE}═══════════════════════════════════════════════════════════════════════════════${NC}"
}

#═══════════════════════════════════════════════════════════════════════════════
#  MAIN FUNCTION
#═══════════════════════════════════════════════════════════════════════════════

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --detailed|-d)
                DETAILED_OUTPUT=true
                shift
                ;;
            --fix|-f)
                AUTO_FIX=true
                shift
                ;;
            --report|-r)
                GENERATE_REPORT=true
                shift
                ;;
            --help|-h)
                echo "SKYN3T FreePBX System Verifier v$SCRIPT_VERSION"
                echo ""
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --detailed, -d    Show detailed output for all checks"
                echo "  --fix, -f         Attempt automatic fixes for failed checks"
                echo "  --report, -r      Generate detailed report file"
                echo "  --help, -h        Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                Basic verification"
                echo "  $0 --detailed     Detailed verification with full output"
                echo "  $0 --fix          Verification with automatic fixes"
                echo "  $0 -d -r          Detailed verification with report generation"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Initialize
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          SKYN3T FreePBX System Verifier v$SCRIPT_VERSION               ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if $AUTO_FIX; then
        echo -e "${YELLOW}🔧 Auto-fix mode enabled - Will attempt to resolve issues${NC}"
        echo ""
    fi
    
    if $DETAILED_OUTPUT; then
        echo -e "${CYAN}🔍 Detailed output mode enabled${NC}"
        echo ""
    fi
    
    # Run all verification functions
    verify_system_requirements
    echo ""
    verify_services
    echo ""
    verify_network_ports
    echo ""
    verify_asterisk_configuration
    echo ""
    verify_freepbx_installation
    echo ""
    verify_php_configuration
    echo ""
    verify_database_configuration
    echo ""
    verify_security_configuration
    echo ""
    verify_extensions_configuration
    echo ""
    verify_performance
    
    # Show summary
    show_summary
}

# Execute main function
main "$@"
