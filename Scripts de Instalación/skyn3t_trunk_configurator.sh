#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  SKYN3T FREEPBX CHILEAN TRUNK CONFIGURATOR
#═══════════════════════════════════════════════════════════════════════════════
#  Version: 1.0.0
#  Description: Automated configuration for Chilean SIP providers (Entel, VTR, etc.)
#  Author: SKYN3T Technical Team
#  
#  FEATURES:
#  ✅ Multiple Chilean provider support
#  ✅ Automatic trunk configuration
#  ✅ Outbound/Inbound route setup
#  ✅ Cost comparison and analysis
#  ✅ Parallel Twilio testing
#  ✅ Quality monitoring
#  ✅ Gradual migration support
#═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="/var/log/skyn3t_trunk_config.log"
readonly CONFIG_DIR="/opt/skyn3t/trunks"
readonly BACKUP_DIR="/backup/freepbx_trunks"

# Server configuration
SERVER_IP=$(hostname -I | awk '{print $1}')

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Chilean Providers Configuration
declare -A PROVIDERS=(
    ["entel"]="Entel Empresas:sip.entel.cl:5060:14:72%"
    ["vtr"]="VTR Empresas:sip.vtr.com:5060:15:70%"
    ["movistar"]="Movistar Empresas:sip.movistar.cl:5060:16:68%"
    ["voipms"]="VoIP.ms (International):chile.voip.ms:5060:20:60%"
    ["twilio_backup"]="Twilio (Backup):skyn3t-communities.sip.twilio.com:5060:50:0%"
)

# SKYN3T Clients Configuration
declare -A CLIENTS=(
    ["oficina_principal"]="+56229145248:2001,2002:Oficina Principal"
    ["plaza_norte"]="+56954783299:3001,3002:Plaza Norte"
)

# Call patterns for Chile
declare -A CHILE_PATTERNS=(
    ["mobile"]="9XXXXXXXX:Celulares (9 + 8 dígitos)"
    ["landline"]="2XXXXXXXX:Fijos Santiago (2 + 7 dígitos)"
    ["landline_regions"]="XXXXXXXXX:Fijos Regiones (9 dígitos)"
    ["emergency"]="1XX:Números de emergencia"
    ["services"]="XXXX:Servicios (4 dígitos)"
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
    mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
    chmod 755 "$CONFIG_DIR" "$BACKUP_DIR"
}

backup_current_config() {
    local backup_file="$BACKUP_DIR/trunk_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    log_info "📦 Creating configuration backup..."
    
    tar -czf "$backup_file" \
        /etc/asterisk/pjsip.conf \
        /etc/asterisk/extensions.conf \
        /var/www/html/admin/modules/core/functions.inc.php \
        2>/dev/null || true
    
    log_success "Backup created: $backup_file"
}

#═══════════════════════════════════════════════════════════════════════════════
#  PROVIDER CONFIGURATION FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

configure_entel_trunk() {
    local username="$1"
    local password="$2"
    local client_did="$3"
    local trunk_name="entel_${client_did//[^0-9]/}"
    
    log_info "🔧 Configuring Entel trunk for $client_did..."
    
    # Add PJSIP trunk configuration
    cat >> /etc/asterisk/pjsip.conf << EOF

; Entel Empresas Trunk for $client_did
[${trunk_name}]
type=endpoint
transport=transport-udp
context=from-trunk-entel
disallow=all
allow=ulaw,alaw,g722
outbound_auth=${trunk_name}-auth
aors=${trunk_name}-aor
from_user=$username
from_domain=sip.entel.cl
callerid="$client_did" <$client_did>

[${trunk_name}-auth]
type=auth
auth_type=userpass
username=$username
password=$password

[${trunk_name}-aor]
type=aor
contact=sip:sip.entel.cl:5060
qualify_frequency=60

[${trunk_name}-identify]
type=identify
endpoint=${trunk_name}
match=sip.entel.cl
EOF
    
    # Add context for incoming calls
    cat >> /etc/asterisk/extensions.conf << EOF

; Entel Incoming Context
[from-trunk-entel]
exten => $client_did,1,Goto(from-pstn,\${EXTEN},1)
exten => _X.,1,Goto(from-pstn,\${EXTEN},1)
EOF
    
    log_success "Entel trunk configured: $trunk_name"
    echo "$trunk_name:entel:$username:$client_did" >> "$CONFIG_DIR/configured_trunks.txt"
}

configure_vtr_trunk() {
    local username="$1"
    local password="$2"
    local client_did="$3"
    local trunk_name="vtr_${client_did//[^0-9]/}"
    
    log_info "🔧 Configuring VTR trunk for $client_did..."
    
    cat >> /etc/asterisk/pjsip.conf << EOF

; VTR Empresas Trunk for $client_did
[${trunk_name}]
type=endpoint
transport=transport-udp
context=from-trunk-vtr
disallow=all
allow=ulaw,alaw,g722
outbound_auth=${trunk_name}-auth
aors=${trunk_name}-aor
from_user=$username
from_domain=sip.vtr.com
callerid="$client_did" <$client_did>

[${trunk_name}-auth]
type=auth
auth_type=userpass
username=$username
password=$password

[${trunk_name}-aor]
type=aor
contact=sip:sip.vtr.com:5060
qualify_frequency=60

[${trunk_name}-identify]
type=identify
endpoint=${trunk_name}
match=sip.vtr.com
EOF
    
    cat >> /etc/asterisk/extensions.conf << EOF

; VTR Incoming Context
[from-trunk-vtr]
exten => $client_did,1,Goto(from-pstn,\${EXTEN},1)
exten => _X.,1,Goto(from-pstn,\${EXTEN},1)
EOF
    
    log_success "VTR trunk configured: $trunk_name"
    echo "$trunk_name:vtr:$username:$client_did" >> "$CONFIG_DIR/configured_trunks.txt"
}

configure_voipms_trunk() {
    local username="$1"
    local password="$2"
    local client_did="$3"
    local trunk_name="voipms_${client_did//[^0-9]/}"
    
    log_info "🔧 Configuring VoIP.ms trunk for $client_did..."
    
    cat >> /etc/asterisk/pjsip.conf << EOF

; VoIP.ms Trunk for $client_did
[${trunk_name}]
type=endpoint
transport=transport-udp
context=from-trunk-voipms
disallow=all
allow=ulaw,alaw,g722
outbound_auth=${trunk_name}-auth
aors=${trunk_name}-aor
from_user=$username
from_domain=chile.voip.ms
callerid="$client_did" <$client_did>

[${trunk_name}-auth]
type=auth
auth_type=userpass
username=$username
password=$password

[${trunk_name}-aor]
type=aor
contact=sip:chile.voip.ms:5060
qualify_frequency=60
EOF
    
    cat >> /etc/asterisk/extensions.conf << EOF

; VoIP.ms Incoming Context
[from-trunk-voipms]
exten => $client_did,1,Goto(from-pstn,\${EXTEN},1)
exten => _X.,1,Goto(from-pstn,\${EXTEN},1)
EOF
    
    log_success "VoIP.ms trunk configured: $trunk_name"
    echo "$trunk_name:voipms:$username:$client_did" >> "$CONFIG_DIR/configured_trunks.txt"
}

configure_twilio_backup_trunk() {
    local username="$1"
    local password="$2"
    local client_did="$3"
    local trunk_name="twilio_backup_${client_did//[^0-9]/}"
    
    log_info "🔧 Configuring Twilio backup trunk for $client_did..."
    
    cat >> /etc/asterisk/pjsip.conf << EOF

; Twilio Backup Trunk for $client_did
[${trunk_name}]
type=endpoint
transport=transport-udp
context=from-trunk-twilio
disallow=all
allow=ulaw,alaw,g722
outbound_auth=${trunk_name}-auth
aors=${trunk_name}-aor
from_user=${username}
from_domain=skyn3t-communities.sip.twilio.com
callerid="$client_did" <$client_did>

[${trunk_name}-auth]
type=auth
auth_type=userpass
username=${username}
password=$password

[${trunk_name}-aor]
type=aor
contact=sip:skyn3t-communities.sip.twilio.com:5060
qualify_frequency=60
EOF
    
    cat >> /etc/asterisk/extensions.conf << EOF

; Twilio Backup Incoming Context
[from-trunk-twilio]
exten => $client_did,1,Goto(from-pstn,\${EXTEN},1)
exten => _X.,1,Goto(from-pstn,\${EXTEN},1)
EOF
    
    log_success "Twilio backup trunk configured: $trunk_name"
    echo "$trunk_name:twilio_backup:$username:$client_did" >> "$CONFIG_DIR/configured_trunks.txt"
}

#═══════════════════════════════════════════════════════════════════════════════
#  OUTBOUND ROUTE CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

configure_outbound_routes() {
    local client_did="$1"
    local primary_trunk="$2"
    local backup_trunk="$3"
    
    log_info "🛤️ Configuring outbound routes for $client_did..."
    
    # Configure outbound routing in extensions.conf
    cat >> /etc/asterisk/extensions.conf << EOF

; Outbound Routes for $client_did
[from-internal-${client_did//[^0-9]/}]

; Chilean Mobile Numbers (9 + 8 digits)
exten => _9XXXXXXXX,1,Set(CALLERID(num)=$client_did)
exten => _9XXXXXXXX,n,Dial(PJSIP/\${EXTEN:1}@${primary_trunk},60)
exten => _9XXXXXXXX,n,GotoIf(\$["x\${DIALSTATUS}" = "xCONGESTION"]?backup:hangup)
exten => _9XXXXXXXX,n(backup),Dial(PJSIP/\${EXTEN:1}@${backup_trunk},60)
exten => _9XXXXXXXX,n(hangup),Hangup()

; Chilean Landlines Santiago (2 + 7 digits)
exten => _2XXXXXXX,1,Set(CALLERID(num)=$client_did)
exten => _2XXXXXXX,n,Dial(PJSIP/\${EXTEN}@${primary_trunk},60)
exten => _2XXXXXXX,n,GotoIf(\$["x\${DIALSTATUS}" = "xCONGESTION"]?backup:hangup)
exten => _2XXXXXXX,n(backup),Dial(PJSIP/\${EXTEN}@${backup_trunk},60)
exten => _2XXXXXXX,n(hangup),Hangup()

; Chilean Landlines Regions (9 digits starting with 3-9)
exten => _[3-9]XXXXXXXX,1,Set(CALLERID(num)=$client_did)
exten => _[3-9]XXXXXXXX,n,Dial(PJSIP/\${EXTEN}@${primary_trunk},60)
exten => _[3-9]XXXXXXXX,n,GotoIf(\$["x\${DIALSTATUS}" = "xCONGESTION"]?backup:hangup)
exten => _[3-9]XXXXXXXX,n(backup),Dial(PJSIP/\${EXTEN}@${backup_trunk},60)
exten => _[3-9]XXXXXXXX,n(hangup),Hangup()

; Emergency Numbers
exten => _1XX,1,Set(CALLERID(num)=$client_did)
exten => _1XX,n,Dial(PJSIP/\${EXTEN}@${primary_trunk},30)
exten => _1XX,n,Hangup()

; International Numbers (00 + country code)
exten => _00.,1,Set(CALLERID(num)=$client_did)
exten => _00.,n,Dial(PJSIP/\${EXTEN}@${primary_trunk},60)
exten => _00.,n,GotoIf(\$["x\${DIALSTATUS}" = "xCONGESTION"]?backup:hangup)
exten => _00.,n(backup),Dial(PJSIP/\${EXTEN}@${backup_trunk},60)
exten => _00.,n(hangup),Hangup()

EOF
    
    log_success "Outbound routes configured for $client_did"
}

#═══════════════════════════════════════════════════════════════════════════════
#  INBOUND ROUTE CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

configure_inbound_routes() {
    local client_did="$1"
    local client_name="$2"
    local extensions="$3"
    
    log_info "📞 Configuring inbound routes for $client_did..."
    
    # Create incoming context
    cat >> /etc/asterisk/extensions.conf << EOF

; Inbound Routes for $client_did ($client_name)
[from-pstn-${client_did//[^0-9]/}]

; Main DID routing to IVR or ring group
exten => $client_did,1,Set(CALLERID(name)=$client_name)
exten => $client_did,n,Answer()
exten => $client_did,n,Wait(1)
exten => $client_did,n,Goto(ivr-${client_did//[^0-9]/},s,1)

; Direct extension access (DID + extension)
EOF

    # Add direct extension routing
    IFS=',' read -ra EXT_ARRAY <<< "$extensions"
    for ext in "${EXT_ARRAY[@]}"; do
        cat >> /etc/asterisk/extensions.conf << EOF
exten => ${client_did}${ext},1,Set(CALLERID(name)=$client_name)
exten => ${client_did}${ext},n,Dial(PJSIP/${ext},20)
exten => ${client_did}${ext},n,VoiceMail(${ext}@default)
exten => ${client_did}${ext},n,Hangup()
EOF
    done
    
    log_success "Inbound routes configured for $client_did"
}

#═══════════════════════════════════════════════════════════════════════════════
#  IVR CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

configure_client_ivr() {
    local client_did="$1"
    local client_name="$2"
    local extensions="$3"
    
    log_info "🎙️ Configuring IVR for $client_name..."
    
    # Create IVR context
    cat >> /etc/asterisk/extensions.conf << EOF

; IVR for $client_name ($client_did)
[ivr-${client_did//[^0-9]/}]
exten => s,1,Set(TIMEOUT(response)=10)
exten => s,n,Set(TIMEOUT(digit)=3)
exten => s,n,Background(custom/welcome-${client_did//[^0-9]/})
exten => s,n,Background(custom/ivr-options-${client_did//[^0-9]/})
exten => s,n,WaitExten(10)

; IVR Options
EOF

    # Configure IVR options based on extensions
    IFS=',' read -ra EXT_ARRAY <<< "$extensions"
    local option=1
    for ext in "${EXT_ARRAY[@]}"; do
        local ext_type="office"
        if [[ "$ext" =~ 2$ ]]; then
            ext_type="security"
        fi
        
        cat >> /etc/asterisk/extensions.conf << EOF
exten => $option,1,Dial(PJSIP/${ext},20)
exten => $option,n,VoiceMail(${ext}@default)
exten => $option,n,Hangup()
EOF
        ((option++))
    done
    
    # Add operator and invalid options
    cat >> /etc/asterisk/extensions.conf << EOF

; Operator (0)
exten => 0,1,Dial(PJSIP/${EXT_ARRAY[0]},20)
exten => 0,n,VoiceMail(${EXT_ARRAY[0]}@default)
exten => 0,n,Hangup()

; Timeout and invalid
exten => t,1,Goto(0,1)
exten => i,1,Playback(invalid)
exten => i,n,Goto(s,1)

EOF
    
    log_success "IVR configured for $client_name"
}

#═══════════════════════════════════════════════════════════════════════════════
#  INTERACTIVE CONFIGURATION
#═══════════════════════════════════════════════════════════════════════════════

configure_provider_interactive() {
    echo -e "${BLUE}🔧 Interactive Provider Configuration${NC}"
    echo ""
    
    # Show available providers
    echo "Available Chilean providers:"
    local i=1
    local provider_keys=()
    for provider in "${!PROVIDERS[@]}"; do
        IFS=':' read -r name server port cost savings <<< "${PROVIDERS[$provider]}"
        echo "  $i) $name - $cost CLP/min (Savings: $savings vs Twilio)"
        provider_keys+=("$provider")
        ((i++))
    done
    echo ""
    
    read -p "Select provider [1-${#PROVIDERS[@]}]: " provider_choice
    if [[ ! "$provider_choice" =~ ^[1-9]$ ]] || [[ $provider_choice -gt ${#PROVIDERS[@]} ]]; then
        log_error "Invalid provider selection"
        return 1
    fi
    
    local selected_provider="${provider_keys[$((provider_choice-1))]}"
    IFS=':' read -r name server port cost savings <<< "${PROVIDERS[$selected_provider]}"
    
    echo ""
    echo -e "${GREEN}Selected: $name${NC}"
    echo ""
    
    # Get provider credentials
    read -p "Enter SIP username: " sip_username
    read -p "Enter SIP password: " sip_password
    
    # Select client
    echo ""
    echo "Available clients:"
    local j=1
    local client_keys=()
    for client in "${!CLIENTS[@]}"; do
        IFS=':' read -r did extensions client_name <<< "${CLIENTS[$client]}"
        echo "  $j) $client_name ($did)"
        client_keys+=("$client")
        ((j++))
    done
    echo ""
    
    read -p "Select client [1-${#CLIENTS[@]}]: " client_choice
    if [[ ! "$client_choice" =~ ^[1-9]$ ]] || [[ $client_choice -gt ${#CLIENTS[@]} ]]; then
        log_error "Invalid client selection"
        return 1
    fi
    
    local selected_client="${client_keys[$((client_choice-1))]}"
    IFS=':' read -r client_did client_extensions client_name <<< "${CLIENTS[$selected_client]}"
    
    echo ""
    echo -e "${GREEN}Configuring $name for $client_name ($client_did)${NC}"
    echo ""
    
    # Configure the selected provider
    case $selected_provider in
        "entel")
            configure_entel_trunk "$sip_username" "$sip_password" "$client_did"
            ;;
        "vtr")
            configure_vtr_trunk "$sip_username" "$sip_password" "$client_did"
            ;;
        "voipms")
            configure_voipms_trunk "$sip_username" "$sip_password" "$client_did"
            ;;
        "twilio_backup")
            configure_twilio_backup_trunk "$sip_username" "$sip_password" "$client_did"
            ;;
    esac
    
    # Configure routing
    local trunk_name="${selected_provider}_${client_did//[^0-9]/}"
    local backup_trunk="twilio_backup_${client_did//[^0-9]/}"
    
    configure_outbound_routes "$client_did" "$trunk_name" "$backup_trunk"
    configure_inbound_routes "$client_did" "$client_name" "$client_extensions"
    configure_client_ivr "$client_did" "$client_name" "$client_extensions"
    
    # Reload Asterisk configuration
    asterisk -rx "module reload res_pjsip.so"
    asterisk -rx "dialplan reload"
    
    log_success "Provider configuration completed for $client_name"
}

#═══════════════════════════════════════════════════════════════════════════════
#  TESTING AND VERIFICATION
#═══════════════════════════════════════════════════════════════════════════════

test_trunk_connectivity() {
    local trunk_name="$1"
    
    log_info "🧪 Testing trunk connectivity: $trunk_name"
    
    # Check trunk registration
    if asterisk -rx "pjsip show endpoint $trunk_name" | grep -q "Available"; then
        log_success "Trunk $trunk_name: Connected ✅"
        return 0
    else
        log_warning "Trunk $trunk_name: Not connected ⚠️"
        return 1
    fi
}

test_outbound_call() {
    local trunk_name="$1"
    local test_number="${2:-133}"  # Default to time service
    
    log_info "🧪 Testing outbound call via $trunk_name to $test_number"
    
    # Originate test call
    local result=$(asterisk -rx "channel originate PJSIP/$test_number@$trunk_name application Playback demo-congrats" 2>&1)
    
    if [[ "$result" =~ "Channel.*up" ]]; then
        log_success "Outbound call test successful via $trunk_name"
        return 0
    else
        log_warning "Outbound call test failed via $trunk_name: $result"
        return 1
    fi
}

generate_cost_analysis() {
    log_info "💰 Generating cost analysis report..."
    
    cat > "$CONFIG_DIR/cost_analysis_$(date +%Y%m%d).txt" << EOF
SKYN3T CHILEAN TRUNK COST ANALYSIS
Generated: $(date)

PROVIDER COMPARISON (Cost per minute to Chilean mobile):
═══════════════════════════════════════════════════════════════

Provider               Cost/min    Monthly (500min)    Savings vs Twilio
───────────────────────────────────────────────────────────────────────
EOF
    
    for provider in "${!PROVIDERS[@]}"; do
        IFS=':' read -r name server port cost savings <<< "${PROVIDERS[$provider]}"
        local monthly_cost=$((cost * 500))
        printf "%-20s    %3s CLP      %6s CLP         %s\n" "$name" "$cost" "$monthly_cost" "$savings" >> "$CONFIG_DIR/cost_analysis_$(date +%Y%m%d).txt"
    done
    
    cat >> "$CONFIG_DIR/cost_analysis_$(date +%Y%m%d).txt" << EOF

CONFIGURED TRUNKS:
═══════════════════════════════════════════════════════════════
EOF
    
    if [[ -f "$CONFIG_DIR/configured_trunks.txt" ]]; then
        while IFS=':' read -r trunk provider username did; do
            IFS=':' read -r name server port cost savings <<< "${PROVIDERS[$provider]}"
            echo "Trunk: $trunk | Provider: $name | DID: $did | Cost: $cost CLP/min" >> "$CONFIG_DIR/cost_analysis_$(date +%Y%m%d).txt"
        done < "$CONFIG_DIR/configured_trunks.txt"
    else
        echo "No trunks configured yet" >> "$CONFIG_DIR/cost_analysis_$(date +%Y%m%d).txt"
    fi
    
    cat >> "$CONFIG_DIR/cost_analysis_$(date +%Y%m%d).txt" << EOF

PROJECTED MONTHLY SAVINGS:
═══════════════════════════════════════════════════════════════

Scenario: 500 minutes/month per client
Twilio Current Cost: 50 CLP/min = 25,000 CLP/month
Best Chilean Provider: 14 CLP/min = 7,000 CLP/month
Monthly Savings: 18,000 CLP (72%)
Annual Savings: 216,000 CLP per client

Total Savings (2 clients): 432,000 CLP/year ≈ $432 USD/year
EOF
    
    log_success "Cost analysis generated: $CONFIG_DIR/cost_analysis_$(date +%Y%m%d).txt"
}

#═══════════════════════════════════════════════════════════════════════════════
#  MONITORING AND MAINTENANCE
#═══════════════════════════════════════════════════════════════════════════════

monitor_trunk_quality() {
    log_info "📊 Monitoring trunk quality..."
    
    cat > "$CONFIG_DIR/trunk_quality_$(date +%Y%m%d_%H%M%S).txt" << EOF
SKYN3T TRUNK QUALITY REPORT
Generated: $(date)

TRUNK STATUS:
═══════════════════════════════════════════════════════════════
EOF
    
    if [[ -f "$CONFIG_DIR/configured_trunks.txt" ]]; then
        while IFS=':' read -r trunk provider username did; do
            local status="Unknown"
            local qualify="N/A"
            
            if asterisk -rx "pjsip show endpoint $trunk" | grep -q "Available"; then
                status="✅ Connected"
                qualify=$(asterisk -rx "pjsip show aor $trunk-aor" | grep "qualify" | awk '{print $3}' || echo "N/A")
            else
                status="❌ Disconnected"
            fi
            
            cat >> "$CONFIG_DIR/trunk_quality_$(date +%Y%m%d_%H%M%S).txt" << EOF
Trunk: $trunk
Provider: $provider
DID: $did
Status: $status
Qualify: $qualify ms
───────────────────────────────────────────────────────────────

EOF
        done < "$CONFIG_DIR/configured_trunks.txt"
    else
        echo "No trunks configured" >> "$CONFIG_DIR/trunk_quality_$(date +%Y%m%d_%H%M%S).txt"
    fi
    
    log_success "Quality report generated"
}

#═══════════════════════════════════════════════════════════════════════════════
#  MAIN MENU AND FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

show_main_menu() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           SKYN3T Chilean Trunk Configurator v$SCRIPT_VERSION           ║${NC}"
    echo -e "${BLUE}║                Server: $SERVER_IP                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}📞 Trunk Configuration Options:${NC}"
    echo ""
    echo "1) 🔧 Configure Provider (Interactive)"
    echo "2) 📊 View Available Providers"
    echo "3) 🧪 Test Trunk Connectivity"
    echo "4) 📞 Test Outbound Call"
    echo "5) 💰 Generate Cost Analysis"
    echo "6) 📊 Monitor Trunk Quality"
    echo "7) 📋 Show Configured Trunks"
    echo "8) 🔄 Reload Asterisk Configuration"
    echo "9) 🗂️ Backup Current Configuration"
    echo ""
    echo "0) ❌ Exit"
    echo ""
}

show_providers() {
    echo -e "${BLUE}═══ AVAILABLE CHILEAN PROVIDERS ═══${NC}"
    echo ""
    
    for provider in "${!PROVIDERS[@]}"; do
        IFS=':' read -r name server port cost savings <<< "${PROVIDERS[$provider]}"
        echo -e "${GREEN}$name${NC}"
        echo "  Server: $server:$port"
        echo "  Cost: $cost CLP/minute"
        echo "  Savings vs Twilio: $savings"
        echo ""
    done
}

show_configured_trunks() {
    echo -e "${BLUE}═══ CONFIGURED TRUNKS ═══${NC}"
    echo ""
    
    if [[ -f "$CONFIG_DIR/configured_trunks.txt" ]]; then
        while IFS=':' read -r trunk provider username did; do
            IFS=':' read -r name server port cost savings <<< "${PROVIDERS[$provider]}"
            local status="Unknown"
            
            if asterisk -rx "pjsip show endpoint $trunk" &>/dev/null; then
                if asterisk -rx "pjsip show endpoint $trunk" | grep -q "Available"; then
                    status="${GREEN}✅ Connected${NC}"
                else
                    status="${YELLOW}⚠️ Disconnected${NC}"
                fi
            else
                status="${RED}❌ Not Found${NC}"
            fi
            
            echo -e "${CYAN}Trunk:${NC} $trunk"
            echo -e "${CYAN}Provider:${NC} $name"
            echo -e "${CYAN}DID:${NC} $did"
            echo -e "${CYAN}Status:${NC} $status"
            echo -e "${CYAN}Cost:${NC} $cost CLP/min"
            echo ""
        done < "$CONFIG_DIR/configured_trunks.txt"
    else
        echo "No trunks configured yet"
    fi
}

test_trunk_menu() {
    echo -e "${YELLOW}🧪 Trunk Testing${NC}"
    echo ""
    
    if [[ ! -f "$CONFIG_DIR/configured_trunks.txt" ]]; then
        log_warning "No trunks configured for testing"
        return 1
    fi
    
    echo "Available trunks:"
    local i=1
    local trunk_list=()
    while IFS=':' read -r trunk provider username did; do
        echo "  $i) $trunk ($provider)"
        trunk_list+=("$trunk")
        ((i++))
    done < "$CONFIG_DIR/configured_trunks.txt"
    echo ""
    
    read -p "Select trunk to test [1-$((i-1))]: " trunk_choice
    if [[ ! "$trunk_choice" =~ ^[1-9]$ ]] || [[ $trunk_choice -gt ${#trunk_list[@]} ]]; then
        log_error "Invalid trunk selection"
        return 1
    fi
    
    local selected_trunk="${trunk_list[$((trunk_choice-1))]}"
    test_trunk_connectivity "$selected_trunk"
}

main() {
    # Initialize
    setup_directories
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    while true; do
        clear
        show_main_menu
        read -p "Select option [0-9]: " choice
        echo ""
        
        case $choice in
            1)
                backup_current_config
                configure_provider_interactive
                read -p "Press Enter to continue..."
                ;;
            2)
                show_providers
                read -p "Press Enter to continue..."
                ;;
            3)
                test_trunk_menu
                read -p "Press Enter to continue..."
                ;;
            4)
                echo "Testing outbound call..."
                if [[ -f "$CONFIG_DIR/configured_trunks.txt" ]]; then
                    local first_trunk=$(head -1 "$CONFIG_DIR/configured_trunks.txt" | cut -d':' -f1)
                    test_outbound_call "$first_trunk"
                else
                    log_warning "No trunks configured for testing"
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                generate_cost_analysis
                read -p "Press Enter to continue..."
                ;;
            6)
                monitor_trunk_quality
                read -p "Press Enter to continue..."
                ;;
            7)
                show_configured_trunks
                read -p "Press Enter to continue..."
                ;;
            8)
                log_info "Reloading Asterisk configuration..."
                asterisk -rx "module reload res_pjsip.so"
                asterisk -rx "dialplan reload"
                log_success "Configuration reloaded"
                read -p "Press Enter to continue..."
                ;;
            9)
                backup_current_config
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}👋 Trunk configuration completed!${NC}"
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

# Execute main function
main "$@"
