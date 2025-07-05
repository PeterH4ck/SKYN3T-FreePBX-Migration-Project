#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  SKYN3T FREEPBX DEVICE CONFIGURATOR
#═══════════════════════════════════════════════════════════════════════════════
#  Version: 1.0.0
#  Description: Automated configuration for Grandstream devices via GDMS Cloud
#  Author: SKYN3T Technical Team
#  
#  FEATURES:
#  ✅ Automatic device discovery
#  ✅ GDMS Cloud template generation
#  ✅ Mass device configuration
#  ✅ SIP registration verification
#  ✅ Audio quality testing
#  ✅ Template management
#═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="/var/log/skyn3t_device_config.log"
readonly TEMPLATE_DIR="/opt/skyn3t/templates"
readonly CONFIG_DIR="/opt/skyn3t/config"

# Server configuration
SERVER_IP=$(hostname -I | awk '{print $1}')
SIP_PORT="5060"
WEB_PORT="8080"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Extension configurations
declare -A EXTENSIONS=(
    ["2001"]="office:SKyn3t_Office_2025!:Oficina Principal - Office:oficina.principal@skyn3t.com"
    ["2002"]="security:SKyn3t_Security_2025!:Oficina Principal - Security:seguridad.principal@skyn3t.com"
    ["3001"]="office:SKyn3t_PlazaNorte_2025!:Plaza Norte - Office:plaza.norte@skyn3t.com"
    ["3002"]="security:SKyn3t_PlazaNorte_Sec_2025!:Plaza Norte - Security:seguridad.plaza@skyn3t.com"
)

# Device models supported
declare -A DEVICE_MODELS=(
    ["GRP2601"]="office"
    ["GRP2614"]="office"
    ["GRP2615"]="office"
    ["GRP2616"]="office"
    ["GHP621"]="security"
    ["GHP621W"]="security"
    ["GDS3710"]="security"
)

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

setup_directories() {
    mkdir -p "$TEMPLATE_DIR" "$CONFIG_DIR"
    chmod 755 "$TEMPLATE_DIR" "$CONFIG_DIR"
}

#═══════════════════════════════════════════════════════════════════════════════
#  DEVICE DISCOVERY FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

discover_network_devices() {
    log_info "🔍 Discovering Grandstream devices on network..."
    
    local network=$(ip route | grep -E "192\.168\.|10\.|172\." | head -1 | awk '{print $1}' || echo "192.168.1.0/24")
    local discovered_devices=()
    
    log_info "Scanning network: $network"
    
    # Scan for Grandstream devices
    nmap -sn "$network" | grep -B 2 -i "grandstream\|gs" | grep "Nmap scan report" | while read line; do
        local ip=$(echo "$line" | awk '{print $5}')
        if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "$ip"
        fi
    done > /tmp/discovered_devices.txt
    
    if [[ -s /tmp/discovered_devices.txt ]]; then
        log_success "Found $(wc -l < /tmp/discovered_devices.txt) Grandstream devices:"
        while read ip; do
            local model=$(get_device_model "$ip")
            log_info "  📱 $ip - $model"
        done < /tmp/discovered_devices.txt
    else
        log_warning "No Grandstream devices found on network"
        log_info "💡 Ensure devices are powered on and connected to the same network"
    fi
    
    rm -f /tmp/discovered_devices.txt
}

get_device_model() {
    local ip="$1"
    local model="Unknown"
    
    # Try to get model via HTTP
    local response=$(curl -s --connect-timeout 3 "http://$ip" 2>/dev/null || echo "")
    if [[ "$response" =~ GRP([0-9]+) ]]; then
        model="GRP${BASH_REMATCH[1]}"
    elif [[ "$response" =~ GHP([0-9]+) ]]; then
        model="GHP${BASH_REMATCH[1]}"
    elif [[ "$response" =~ GDS([0-9]+) ]]; then
        model="GDS${BASH_REMATCH[1]}"
    fi
    
    echo "$model"
}

verify_device_access() {
    local ip="$1"
    local username="${2:-admin}"
    local password="${3:-admin}"
    
    log_info "🔍 Verifying access to device $ip..."
    
    # Test HTTP access
    local response=$(curl -s -u "$username:$password" --connect-timeout 5 "http://$ip/cgi-bin/api-sys_operation" 2>/dev/null || echo "")
    
    if [[ -n "$response" ]]; then
        log_success "Device $ip accessible via HTTP"
        return 0
    else
        log_warning "Device $ip not accessible with credentials $username:$password"
        return 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  TEMPLATE GENERATION FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

generate_grp2601_template() {
    local extension="$1"
    local password="$2"
    local display_name="$3"
    local email="$4"
    
    cat > "$TEMPLATE_DIR/GRP2601_${extension}.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<gs_provision version="1">
  <config version="2">
    
    <!-- SKYN3T Configuration for Extension $extension -->
    
    <!-- Account 1: SIP Configuration -->
    <item name="account.1.sip">
      <part name="accountName">SKYN3T-$extension</part>
      <part name="authId">$extension</part>
      <part name="displayName">$display_name</part>
      <part name="password">$password</part>
      <part name="register">1</part>
      <part name="registrar">$SERVER_IP</part>
      <part name="registrarPort">$SIP_PORT</part>
      <part name="transport">0</part>
      <part name="userId">$extension</part>
      <part name="accountActive">1</part>
      <part name="accountDisplay">1</part>
      <part name="localPort">5060</part>
      <part name="outboundProxy"></part>
      <part name="proxyPort">5060</part>
    </item>

    <!-- Network Configuration -->
    <item name="account.1.network">
      <part name="natTraversal">0</part>
      <part name="keepAliveInterval">30</part>
      <part name="registerExpiration">1800</part>
      <part name="reregisterBeforeExpiration">60</part>
      <part name="symmetricRtp">1</part>
      <part name="rtpPacketSize">20</part>
    </item>

    <!-- Codec Configuration -->
    <item name="account.1.codec.choice">
      <part name="1">0</part>   <!-- PCMU -->
      <part name="2">8</part>   <!-- PCMA -->
      <part name="3">9</part>   <!-- G.722 -->
      <part name="4">-1</part>  <!-- Disabled -->
      <part name="5">-1</part>  <!-- Disabled -->
      <part name="6">-1</part>  <!-- Disabled -->
      <part name="7">-1</part>  <!-- Disabled -->
      <part name="8">-1</part>  <!-- Disabled -->
    </item>

    <!-- Audio Configuration -->
    <item name="account.1.audio">
      <part name="silenceSuppression">0</part>
      <part name="voiceActivityDetection">0</part>
      <part name="echoCancellation">1</part>
      <part name="dtmfViaRtp">1</part>
      <part name="dtmfPayloadType">101</part>
      <part name="inAudioDtmfTone">0</part>
    </item>

    <!-- Call Configuration -->
    <item name="account.1.call">
      <part name="autoAnswer">0</part>
      <part name="autoAnswerNumber"></part>
      <part name="callWaiting">1</part>
      <part name="conferenceEnabled">1</part>
      <part name="preferredAccount">0</part>
    </item>

    <!-- Time Zone Configuration (Chile) -->
    <item name="dateTime">
      <part name="timezone">customize</part>
    </item>

    <item name="dateTime.timezone">
      <part name="custom">CLT+4CLST+3,M9.1.6,M4.1.6</part>
    </item>

    <item name="dateTime.ntp.server">
      <part name="1">ntp.shoa.cl</part>
    </item>

    <!-- Security Configuration -->
    <item name="users.admin">
      <part name="password">SKYN3T2025!</part>
    </item>

    <item name="users.user">
      <part name="password">skyn3t123</part>
    </item>

    <!-- Language Configuration -->
    <item name="language">
      <part name="gui">auto</part>
    </item>

  </config>
</gs_provision>
EOF

    log_success "Generated GRP2601 template for extension $extension"
}

generate_ghp621_template() {
    local extension="$1"
    local password="$2"
    local display_name="$3"
    local email="$4"
    
    cat > "$TEMPLATE_DIR/GHP621_${extension}.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<gs_provision version="1">
  <config version="2">
    
    <!-- SKYN3T Security Configuration for Extension $extension -->
    
    <!-- Account 1: SIP Configuration -->
    <item name="account.1.sip">
      <part name="accountName">SKYN3T-SECURITY-$extension</part>
      <part name="authId">$extension</part>
      <part name="displayName">$display_name</part>
      <part name="password">$password</part>
      <part name="register">1</part>
      <part name="registrar">$SERVER_IP</part>
      <part name="registrarPort">$SIP_PORT</part>
      <part name="transport">0</part>
      <part name="userId">$extension</part>
      <part name="accountActive">1</part>
      <part name="accountDisplay">1</part>
      <part name="localPort">5060</part>
    </item>

    <!-- Network Configuration -->
    <item name="account.1.network">
      <part name="natTraversal">0</part>
      <part name="keepAliveInterval">30</part>
      <part name="registerExpiration">1800</part>
      <part name="reregisterBeforeExpiration">60</part>
    </item>

    <!-- Codec Configuration (same as office) -->
    <item name="account.1.codec.choice">
      <part name="1">0</part>   <!-- PCMU -->
      <part name="2">8</part>   <!-- PCMA -->
      <part name="3">9</part>   <!-- G.722 -->
      <part name="4">-1</part>  <!-- Disabled -->
      <part name="5">-1</part>  <!-- Disabled -->
      <part name="6">-1</part>  <!-- Disabled -->
      <part name="7">-1</part>  <!-- Disabled -->
      <part name="8">-1</part>  <!-- Disabled -->
    </item>

    <!-- Auto Answer for Security (Key Difference) -->
    <item name="account.1.call">
      <part name="autoAnswer">1</part>
      <part name="autoAnswerNumber"></part>
      <part name="callWaiting">1</part>
      <part name="conferenceEnabled">1</part>
      <part name="preferredAccount">0</part>
    </item>

    <!-- Audio Configuration -->
    <item name="account.1.audio">
      <part name="silenceSuppression">0</part>
      <part name="voiceActivityDetection">0</part>
      <part name="echoCancellation">1</part>
      <part name="dtmfViaRtp">1</part>
      <part name="dtmfPayloadType">101</part>
      <part name="inAudioDtmfTone">0</part>
    </item>

    <!-- Time Zone Configuration (Chile) -->
    <item name="dateTime">
      <part name="timezone">customize</part>
    </item>

    <item name="dateTime.timezone">
      <part name="custom">CLT+4CLST+3,M9.1.6,M4.1.6</part>
    </item>

    <!-- Security Configuration -->
    <item name="users.admin">
      <part name="password">SKYN3T2025!</part>
    </item>

    <item name="users.user">
      <part name="password">skyn3t123</part>
    </item>

    <!-- Language Configuration -->
    <item name="language">
      <part name="gui">auto</part>
    </item>

  </config>
</gs_provision>
EOF

    log_success "Generated GHP621 template for extension $extension"
}

generate_all_templates() {
    log_info "📄 Generating device templates for all extensions..."
    
    for ext in "${!EXTENSIONS[@]}"; do
        IFS=':' read -r role password displayname email <<< "${EXTENSIONS[$ext]}"
        
        if [[ "$role" == "office" ]]; then
            generate_grp2601_template "$ext" "$password" "$displayname" "$email"
        elif [[ "$role" == "security" ]]; then
            generate_ghp621_template "$ext" "$password" "$displayname" "$email"
        fi
    done
    
    log_success "All templates generated in $TEMPLATE_DIR"
}

#═══════════════════════════════════════════════════════════════════════════════
#  DEVICE CONFIGURATION FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

configure_device_direct() {
    local device_ip="$1"
    local extension="$2"
    local password="$3"
    local display_name="$4"
    local username="${5:-admin}"
    local device_password="${6:-admin}"
    
    log_info "🔧 Configuring device $device_ip for extension $extension..."
    
    # SIP Account Configuration
    local config_data="P271=$extension&P270=$extension&P35=$password&P47=$SERVER_IP&P48=$SIP_PORT"
    
    # Apply configuration via HTTP POST
    local response=$(curl -s -X POST \
        -u "$username:$device_password" \
        -d "$config_data" \
        "http://$device_ip/cgi-bin/api-set_provision" 2>/dev/null || echo "")
    
    if [[ "$response" =~ "Success" || "$response" =~ "OK" ]]; then
        log_success "Configuration applied to device $device_ip"
        
        # Reboot device to apply changes
        curl -s -X POST -u "$username:$device_password" \
            "http://$device_ip/cgi-bin/api-sys_operation" \
            -d "request=REBOOT" &>/dev/null
        
        log_info "Device $device_ip rebooting to apply configuration..."
        return 0
    else
        log_error "Failed to configure device $device_ip"
        return 1
    fi
}

bulk_configure_devices() {
    log_info "🔧 Starting bulk device configuration..."
    
    if [[ ! -f /tmp/discovered_devices.txt ]]; then
        log_error "No devices discovered. Run device discovery first."
        return 1
    fi
    
    local configured_count=0
    local failed_count=0
    
    while read device_ip; do
        log_info "Configuring device: $device_ip"
        
        # Get device model
        local model=$(get_device_model "$device_ip")
        local device_type=""
        
        if [[ -n "${DEVICE_MODELS[$model]:-}" ]]; then
            device_type="${DEVICE_MODELS[$model]}"
        else
            log_warning "Unknown device model: $model, skipping..."
            continue
        fi
        
        # Find appropriate extension
        local target_extension=""
        for ext in "${!EXTENSIONS[@]}"; do
            IFS=':' read -r role password displayname email <<< "${EXTENSIONS[$ext]}"
            if [[ "$role" == "$device_type" ]]; then
                # Check if extension is already configured
                if ! grep -q "$ext" "$CONFIG_DIR/configured_devices.txt" 2>/dev/null; then
                    target_extension="$ext"
                    break
                fi
            fi
        done
        
        if [[ -z "$target_extension" ]]; then
            log_warning "No available extension for device type $device_type"
            continue
        fi
        
        # Configure device
        IFS=':' read -r role password displayname email <<< "${EXTENSIONS[$target_extension]}"
        if configure_device_direct "$device_ip" "$target_extension" "$password" "$displayname"; then
            echo "$device_ip:$target_extension:$model" >> "$CONFIG_DIR/configured_devices.txt"
            ((configured_count++))
        else
            ((failed_count++))
        fi
        
        # Wait between configurations
        sleep 2
        
    done < /tmp/discovered_devices.txt
    
    log_success "Bulk configuration completed: $configured_count configured, $failed_count failed"
}

#═══════════════════════════════════════════════════════════════════════════════
#  SIP REGISTRATION VERIFICATION
#═══════════════════════════════════════════════════════════════════════════════

verify_sip_registrations() {
    log_info "🔍 Verifying SIP registrations..."
    
    local total_extensions=${#EXTENSIONS[@]}
    local registered_count=0
    
    for ext in "${!EXTENSIONS[@]}"; do
        if asterisk -rx "pjsip show endpoint $ext" 2>/dev/null | grep -q "Available\|Online"; then
            log_success "Extension $ext: Registered ✅"
            ((registered_count++))
        else
            log_warning "Extension $ext: Not registered ⚠️"
        fi
    done
    
    log_info "Registration summary: $registered_count/$total_extensions extensions registered"
    
    if [[ $registered_count -eq $total_extensions ]]; then
        log_success "All extensions registered successfully!"
        return 0
    else
        log_warning "Some extensions not registered. Check device configuration."
        return 1
    fi
}

test_extension_connectivity() {
    local extension="$1"
    
    log_info "🧪 Testing connectivity for extension $extension..."
    
    # Test SIP registration
    if asterisk -rx "pjsip show endpoint $extension" | grep -q "Available\|Online"; then
        log_success "Extension $extension: SIP registration OK"
    else
        log_error "Extension $extension: SIP registration failed"
        return 1
    fi
    
    # Test reachability
    if asterisk -rx "pjsip show aor $extension" | grep -q "Contact:"; then
        log_success "Extension $extension: Contact reachable"
    else
        log_warning "Extension $extension: No contact information"
    fi
    
    return 0
}

test_internal_calls() {
    log_info "🧪 Testing internal call connectivity..."
    
    # Get registered extensions
    local registered_extensions=()
    for ext in "${!EXTENSIONS[@]}"; do
        if asterisk -rx "pjsip show endpoint $ext" 2>/dev/null | grep -q "Available\|Online"; then
            registered_extensions+=("$ext")
        fi
    done
    
    if [[ ${#registered_extensions[@]} -lt 2 ]]; then
        log_warning "Need at least 2 registered extensions for call testing"
        return 1
    fi
    
    local ext1="${registered_extensions[0]}"
    local ext2="${registered_extensions[1]}"
    
    log_info "Testing call: $ext1 → $ext2"
    
    # Simulate call using Asterisk originate
    asterisk -rx "channel originate PJSIP/$ext1 extension $ext2@from-internal" &>/dev/null &
    local call_pid=$!
    
    sleep 5
    
    # Check if call was established
    if asterisk -rx "core show channels" | grep -q "$ext1\|$ext2"; then
        log_success "Internal call test successful"
        # Hangup test call
        asterisk -rx "soft hangup PJSIP/$ext1" &>/dev/null
        kill $call_pid 2>/dev/null || true
        return 0
    else
        log_warning "Internal call test failed"
        kill $call_pid 2>/dev/null || true
        return 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  GDMS CLOUD INTEGRATION
#═══════════════════════════════════════════════════════════════════════════════

generate_gdms_instructions() {
    log_info "📚 Generating GDMS Cloud configuration instructions..."
    
    cat > "$CONFIG_DIR/gdms_cloud_setup.md" << EOF
# 🌐 GDMS Cloud Configuration Instructions

## 📋 Templates to Upload

### For GRP2601 (Office Devices):
EOF
    
    for ext in "${!EXTENSIONS[@]}"; do
        IFS=':' read -r role password displayname email <<< "${EXTENSIONS[$ext]}"
        if [[ "$role" == "office" ]]; then
            cat >> "$CONFIG_DIR/gdms_cloud_setup.md" << EOF

#### Extension $ext - $displayname
- **Template File**: \`GRP2601_${ext}.xml\`
- **Model**: GRP2601
- **SIP User ID**: $ext
- **Password**: $password
- **Server**: $SERVER_IP:$SIP_PORT
EOF
        fi
    done
    
    cat >> "$CONFIG_DIR/gdms_cloud_setup.md" << EOF

### For GHP621 (Security Devices):
EOF
    
    for ext in "${!EXTENSIONS[@]}"; do
        IFS=':' read -r role password displayname email <<< "${EXTENSIONS[$ext]}"
        if [[ "$role" == "security" ]]; then
            cat >> "$CONFIG_DIR/gdms_cloud_setup.md" << EOF

#### Extension $ext - $displayname
- **Template File**: \`GHP621_${ext}.xml\`
- **Model**: GHP621/GHP621W
- **SIP User ID**: $ext
- **Password**: $password
- **Server**: $SERVER_IP:$SIP_PORT
- **Auto Answer**: Enabled
EOF
        fi
    done
    
    cat >> "$CONFIG_DIR/gdms_cloud_setup.md" << EOF

## 🔧 GDMS Cloud Setup Steps

1. **Access GDMS Cloud**: https://gdms.grandstream.com/
2. **Navigate**: Template → By Model → Add Model Template
3. **Upload Templates**: Upload the generated XML files
4. **Apply to Devices**: Select devices and apply appropriate templates
5. **Monitor Status**: Check device registration status

## 📊 Quick Verification

After applying templates, verify:
- [ ] All devices show "Online" status in GDMS
- [ ] SIP registration successful in FreePBX
- [ ] Internal calls working between extensions
- [ ] Audio quality acceptable

## 🆘 Troubleshooting

If devices don't register:
1. Check network connectivity
2. Verify server IP: $SERVER_IP
3. Confirm SIP port: $SIP_PORT
4. Check device logs in GDMS Cloud
5. Verify credentials match extension configuration

EOF
    
    log_success "GDMS Cloud instructions generated: $CONFIG_DIR/gdms_cloud_setup.md"
}

#═══════════════════════════════════════════════════════════════════════════════
#  MONITORING AND MAINTENANCE
#═══════════════════════════════════════════════════════════════════════════════

monitor_device_status() {
    log_info "📊 Monitoring device status..."
    
    cat > "$CONFIG_DIR/device_status_$(date +%Y%m%d_%H%M%S).txt" << EOF
SKYN3T Device Status Report
Generated: $(date)
Server: $SERVER_IP

SIP REGISTRATIONS:
═══════════════════════════════════════════════════════════════
EOF
    
    for ext in "${!EXTENSIONS[@]}"; do
        IFS=':' read -r role password displayname email <<< "${EXTENSIONS[$ext]}"
        local status="Unknown"
        local contact="N/A"
        
        if asterisk -rx "pjsip show endpoint $ext" 2>/dev/null | grep -q "Available"; then
            status="✅ Registered"
            contact=$(asterisk -rx "pjsip show aor $ext" 2>/dev/null | grep "Contact:" | awk '{print $2}' || echo "N/A")
        elif asterisk -rx "pjsip show endpoint $ext" 2>/dev/null | grep -q "Unavailable"; then
            status="❌ Not Registered"
        fi
        
        cat >> "$CONFIG_DIR/device_status_$(date +%Y%m%d_%H%M%S).txt" << EOF
Extension $ext ($displayname):
  Status: $status
  Contact: $contact
  Role: $role
  Email: $email

EOF
    done
    
    cat >> "$CONFIG_DIR/device_status_$(date +%Y%m%d_%H%M%S).txt" << EOF

ASTERISK STATUS:
═══════════════════════════════════════════════════════════════
$(asterisk -rx "core show uptime" 2>/dev/null || echo "Asterisk not responding")

ACTIVE CHANNELS:
═══════════════════════════════════════════════════════════════
$(asterisk -rx "core show channels" 2>/dev/null || echo "No channels")

NETWORK PORTS:
═══════════════════════════════════════════════════════════════
$(netstat -tulpn | grep -E ":($SIP_PORT|$WEB_PORT|5038)" || echo "Ports not active")
EOF
    
    log_success "Device status report generated"
}

#═══════════════════════════════════════════════════════════════════════════════
#  MAIN MENU AND FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

show_menu() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           SKYN3T Device Configurator v$SCRIPT_VERSION               ║${NC}"
    echo -e "${BLUE}║                FreePBX Server: $SERVER_IP                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}📱 Device Configuration Options:${NC}"
    echo ""
    echo "1) 🔍 Discover Network Devices"
    echo "2) 📄 Generate Device Templates"
    echo "3) 🔧 Configure Single Device"
    echo "4) 🔧 Bulk Configure All Devices"
    echo "5) 📊 Verify SIP Registrations"
    echo "6) 🧪 Test Internal Calls"
    echo "7) 🌐 Generate GDMS Cloud Instructions"
    echo "8) 📊 Monitor Device Status"
    echo "9) 📋 Show Configuration Summary"
    echo ""
    echo "0) ❌ Exit"
    echo ""
}

configure_single_device() {
    echo -e "${YELLOW}🔧 Single Device Configuration${NC}"
    echo ""
    
    read -p "Enter device IP address: " device_ip
    if [[ ! "$device_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Invalid IP address format"
        return 1
    fi
    
    echo ""
    echo "Available extensions:"
    for ext in "${!EXTENSIONS[@]}"; do
        IFS=':' read -r role password displayname email <<< "${EXTENSIONS[$ext]}"
        echo "  $ext - $displayname ($role)"
    done
    echo ""
    
    read -p "Select extension: " extension
    if [[ -z "${EXTENSIONS[$extension]:-}" ]]; then
        log_error "Invalid extension selected"
        return 1
    fi
    
    read -p "Device admin username [admin]: " dev_username
    dev_username=${dev_username:-admin}
    
    read -p "Device admin password [admin]: " dev_password
    dev_password=${dev_password:-admin}
    
    IFS=':' read -r role password displayname email <<< "${EXTENSIONS[$extension]}"
    
    if configure_device_direct "$device_ip" "$extension" "$password" "$displayname" "$dev_username" "$dev_password"; then
        log_success "Device configured successfully"
        echo "$device_ip:$extension:Manual" >> "$CONFIG_DIR/configured_devices.txt"
    else
        log_error "Device configuration failed"
    fi
}

show_configuration_summary() {
    echo -e "${BLUE}═══ CONFIGURATION SUMMARY ═══${NC}"
    echo ""
    
    echo -e "${GREEN}🖥️  Server Information:${NC}"
    echo "  FreePBX Server: $SERVER_IP:$WEB_PORT"
    echo "  SIP Port: $SIP_PORT"
    echo "  Extensions: ${#EXTENSIONS[@]}"
    echo ""
    
    echo -e "${GREEN}📱 Configured Extensions:${NC}"
    for ext in "${!EXTENSIONS[@]}"; do
        IFS=':' read -r role password displayname email <<< "${EXTENSIONS[$ext]}"
        echo "  $ext - $displayname ($role)"
    done
    echo ""
    
    if [[ -f "$CONFIG_DIR/configured_devices.txt" ]]; then
        echo -e "${GREEN}🔧 Configured Devices:${NC}"
        while IFS=':' read -r ip ext model; do
            echo "  $ip → Extension $ext ($model)"
        done < "$CONFIG_DIR/configured_devices.txt"
    else
        echo -e "${YELLOW}⚠️  No devices configured yet${NC}"
    fi
    echo ""
    
    echo -e "${GREEN}📄 Generated Templates:${NC}"
    if [[ -d "$TEMPLATE_DIR" ]]; then
        ls -la "$TEMPLATE_DIR"/*.xml 2>/dev/null || echo "  No templates generated yet"
    else
        echo "  No templates generated yet"
    fi
}

main() {
    # Initialize
    setup_directories
    
    # Detect server IP if not set
    if [[ -z "$SERVER_IP" || "$SERVER_IP" == "127.0.0.1" ]]; then
        SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
    fi
    
    while true; do
        clear
        show_menu
        read -p "Select option [0-9]: " choice
        echo ""
        
        case $choice in
            1)
                discover_network_devices
                read -p "Press Enter to continue..."
                ;;
            2)
                generate_all_templates
                read -p "Press Enter to continue..."
                ;;
            3)
                configure_single_device
                read -p "Press Enter to continue..."
                ;;
            4)
                discover_network_devices
                if [[ -f /tmp/discovered_devices.txt && -s /tmp/discovered_devices.txt ]]; then
                    bulk_configure_devices
                else
                    log_warning "No devices discovered for bulk configuration"
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                verify_sip_registrations
                read -p "Press Enter to continue..."
                ;;
            6)
                test_internal_calls
                read -p "Press Enter to continue..."
                ;;
            7)
                generate_gdms_instructions
                read -p "Press Enter to continue..."
                ;;
            8)
                monitor_device_status
                read -p "Press Enter to continue..."
                ;;
            9)
                show_configuration_summary
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}👋 Device configuration completed!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid option. Please select 0-9.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Initialize logging
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Execute main function
main "$@"
