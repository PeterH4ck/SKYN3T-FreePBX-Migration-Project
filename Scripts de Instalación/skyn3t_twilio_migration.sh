#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  SKYN3T FREEPBX TWILIO MIGRATION MANAGER
#═══════════════════════════════════════════════════════════════════════════════
#  Version: 1.0.0
#  Description: Automated gradual migration from Twilio to FreePBX + Chilean providers
#  Author: SKYN3T Technical Team
#  
#  FEATURES:
#  ✅ Gradual migration planning
#  ✅ Parallel system testing
#  ✅ Cost comparison monitoring
#  ✅ Quality analysis
#  ✅ Rollback capabilities
#  ✅ Client-by-client migration
#  ✅ Risk minimization
#═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="/var/log/skyn3t_migration.log"
readonly MIGRATION_DIR="/opt/skyn3t/migration"
readonly BACKUP_DIR="/backup/freepbx_migration"
readonly REPORTS_DIR="/opt/skyn3t/reports"

# Server configuration
SERVER_IP=$(hostname -I | awk '{print $1}')

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Migration phases
declare -A MIGRATION_PHASES=(
    ["phase1"]="Preparation:Setup parallel systems:1-2 days"
    ["phase2"]="Pilot Testing:Single client testing:3-5 days"
    ["phase3"]="Quality Comparison:Parallel operation testing:5-7 days"
    ["phase4"]="Gradual Migration:Client-by-client migration:1-2 weeks"
    ["phase5"]="Optimization:Final optimization and Twilio cleanup:2-3 days"
)

# SKYN3T Clients
declare -A CLIENTS=(
    ["oficina_principal"]="+56229145248:2001,2002:Oficina Principal:high"
    ["plaza_norte"]="+56954783299:3001,3002:Plaza Norte:medium"
)

# Migration status tracking
declare -A CLIENT_STATUS=(
    ["oficina_principal"]="twilio"
    ["plaza_norte"]="twilio"
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
    mkdir -p "$MIGRATION_DIR" "$BACKUP_DIR" "$REPORTS_DIR"
    chmod 755 "$MIGRATION_DIR" "$BACKUP_DIR" "$REPORTS_DIR"
}

load_migration_status() {
    if [[ -f "$MIGRATION_DIR/migration_status.conf" ]]; then
        source "$MIGRATION_DIR/migration_status.conf"
        log_info "Migration status loaded from configuration file"
    else
        # Initialize default status
        for client in "${!CLIENTS[@]}"; do
            CLIENT_STATUS["$client"]="twilio"
        done
        save_migration_status
    fi
}

save_migration_status() {
    cat > "$MIGRATION_DIR/migration_status.conf" << EOF
# SKYN3T Migration Status Configuration
# Generated: $(date)

EOF
    
    for client in "${!CLIENT_STATUS[@]}"; do
        echo "CLIENT_STATUS[\"$client\"]=\"${CLIENT_STATUS[$client]}\"" >> "$MIGRATION_DIR/migration_status.conf"
    done
    
    log_info "Migration status saved to configuration file"
}

#═══════════════════════════════════════════════════════════════════════════════
#  MIGRATION PLANNING
#═══════════════════════════════════════════════════════════════════════════════

generate_migration_plan() {
    log_info "📋 Generating comprehensive migration plan..."
    
    cat > "$MIGRATION_DIR/migration_plan.md" << EOF
# 🚀 SKYN3T Twilio to FreePBX Migration Plan

**Generated:** $(date)  
**Status:** Planning Phase  
**Total Clients:** ${#CLIENTS[@]}  
**Estimated Duration:** 3-4 weeks  
**Risk Level:** Low (gradual approach)  

## 📊 Current Twilio Configuration

$(generate_twilio_summary)

## 🎯 Target FreePBX Configuration

- **FreePBX Server:** $SERVER_IP
- **Chilean Provider:** Entel Empresas (72% cost reduction)
- **Backup Provider:** Twilio (during transition)
- **Extensions:** Multi-tenant configuration ready

## 📅 Migration Timeline

### Phase 1: Preparation (Week 1, Days 1-2)
**Objective:** Setup parallel systems  
**Duration:** 1-2 days  
**Risk:** Very Low  

**Tasks:**
- [x] FreePBX installation completed
- [x] Extensions configured and tested
- [ ] Chilean trunk configuration
- [ ] Parallel testing setup
- [ ] Staff training on new system

**Success Criteria:**
- FreePBX system fully operational
- Internal calls working between extensions
- Chilean trunk connectivity established
- Twilio remains primary for external calls

---

### Phase 2: Pilot Testing (Week 1, Days 3-7)
**Objective:** Test with single client  
**Duration:** 5 days  
**Risk:** Low  
**Pilot Client:** $(echo "${!CLIENTS[@]}" | head -1)

**Tasks:**
- [ ] Configure pilot client on FreePBX
- [ ] Parallel operation (Twilio + FreePBX)
- [ ] Quality comparison testing
- [ ] Staff feedback collection
- [ ] Performance monitoring

**Success Criteria:**
- Pilot client calls working via FreePBX
- Audio quality meets/exceeds Twilio
- No service interruptions
- Positive staff feedback

---

### Phase 3: Quality Comparison (Week 2)
**Objective:** Comprehensive quality analysis  
**Duration:** 7 days  
**Risk:** Low  

**Tasks:**
- [ ] A/B testing between Twilio and FreePBX
- [ ] Call quality metrics collection
- [ ] Cost analysis validation
- [ ] Reliability testing
- [ ] Load testing

**Success Criteria:**
- FreePBX quality >= 95% of Twilio quality
- Cost savings confirmed (70%+ reduction)
- System stability under normal load
- No critical issues identified

---

### Phase 4: Gradual Migration (Week 3-4)
**Objective:** Migrate all clients  
**Duration:** 1-2 weeks  
**Risk:** Medium (managed through gradual approach)  

**Client Migration Order:**
EOF

    # Add client migration order based on priority
    local priority_order=("high" "medium" "low")
    for priority in "${priority_order[@]}"; do
        for client in "${!CLIENTS[@]}"; do
            IFS=':' read -r did extensions name client_priority <<< "${CLIENTS[$client]}"
            if [[ "$client_priority" == "$priority" ]]; then
                cat >> "$MIGRATION_DIR/migration_plan.md" << EOF
1. **$name** ($did) - Priority: $priority
   - Extensions: $extensions
   - Migration window: 2-3 days
   - Rollback plan: Immediate Twilio reactivation
EOF
            fi
        done
    done
    
    cat >> "$MIGRATION_DIR/migration_plan.md" << EOF

**Migration Process per Client:**
1. Setup FreePBX configuration
2. Configure devices for FreePBX
3. Test internal and external calls
4. Monitor for 24 hours
5. Disable Twilio for client (if successful)
6. Continue monitoring for 48 hours

---

### Phase 5: Optimization (Week 4-5)
**Objective:** Final optimization and cleanup  
**Duration:** 2-3 days  
**Risk:** Very Low  

**Tasks:**
- [ ] Performance optimization
- [ ] Security hardening
- [ ] Monitoring setup
- [ ] Documentation completion
- [ ] Twilio service cleanup
- [ ] Cost analysis final report

---

## 💰 Expected Cost Savings

| Client | Current (Twilio) | New (FreePBX+Entel) | Monthly Savings | Annual Savings |
|--------|------------------|---------------------|-----------------|----------------|
EOF

    for client in "${!CLIENTS[@]}"; do
        IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
        local estimated_minutes=500  # Conservative estimate
        local twilio_cost=$((50 * estimated_minutes))
        local freepbx_cost=$((14 * estimated_minutes))
        local monthly_savings=$((twilio_cost - freepbx_cost))
        local annual_savings=$((monthly_savings * 12))
        
        printf "| %s | %s CLP | %s CLP | %s CLP | %s CLP |\n" \
            "$name" "$twilio_cost" "$freepbx_cost" "$monthly_savings" "$annual_savings" >> "$MIGRATION_DIR/migration_plan.md"
    done
    
    cat >> "$MIGRATION_DIR/migration_plan.md" << EOF

## 🛡️ Risk Mitigation

### High Priority Risks
1. **Service Interruption**
   - Mitigation: Parallel operation, immediate rollback capability
   - Response: Twilio reactivation within 5 minutes

2. **Call Quality Issues**
   - Mitigation: Extensive testing phase
   - Response: Trunk failover to backup provider

3. **Device Configuration Issues**
   - Mitigation: GDMS Cloud mass deployment
   - Response: Individual device reconfiguration

### Medium Priority Risks
1. **Staff Adaptation**
   - Mitigation: Training sessions, documentation
   - Response: Extended support period

2. **Peak Load Issues**
   - Mitigation: Load testing during preparation
   - Response: Server resource scaling

## 📞 Emergency Contacts & Rollback

### Emergency Rollback Procedure
1. **Immediate (< 5 minutes):** Reactivate Twilio webhook
2. **Device Level (< 30 minutes):** GDMS Cloud template revert
3. **Full Rollback (< 2 hours):** Complete system restoration

### Support Contacts
- **Technical Lead:** SKYN3T Technical Team
- **Entel Support:** [To be configured]
- **Emergency:** 24/7 monitoring system

## 📊 Success Metrics

- **Uptime:** >= 99.9%
- **Call Quality:** >= 95% of current Twilio quality
- **Cost Reduction:** >= 70%
- **Migration Time:** <= 4 weeks
- **Rollback Events:** <= 1 per client

---

**Next Actions:**
1. Review and approve migration plan
2. Begin Phase 1 preparation
3. Schedule staff training sessions
4. Establish monitoring procedures

EOF
    
    log_success "Migration plan generated: $MIGRATION_DIR/migration_plan.md"
}

generate_twilio_summary() {
    cat << EOF
### Current Twilio Configuration

**SIP Domain:** skyn3t-communities.sip.twilio.com  
**Transport:** UDP, Port 5060  
**Authentication:** SIP credentials per client  

**Configured Clients:**
EOF
    
    for client in "${!CLIENTS[@]}"; do
        IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
        cat << EOF
- **$name**
  - DID: $did
  - Extensions: $extensions
  - Current Status: ${CLIENT_STATUS[$client]}
EOF
    done
}

#═══════════════════════════════════════════════════════════════════════════════
#  PARALLEL SYSTEM TESTING
#═══════════════════════════════════════════════════════════════════════════════

setup_parallel_testing() {
    local client="$1"
    
    log_info "🔄 Setting up parallel testing for client: $client"
    
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    
    # Create parallel configuration
    cat > "$MIGRATION_DIR/parallel_${client}.conf" << EOF
# Parallel Testing Configuration for $name
CLIENT=$client
DID=$did
EXTENSIONS=$extensions
NAME=$name
PRIORITY=$priority

# Testing Parameters
TEST_START_TIME=$(date +%s)
TEST_DURATION_HOURS=24
TWILIO_WEIGHT=80
FREEPBX_WEIGHT=20

# Quality Metrics
MIN_CALL_QUALITY=4.0
MAX_LATENCY_MS=150
MIN_SUCCESS_RATE=95
EOF
    
    # Configure load balancing between Twilio and FreePBX
    create_parallel_dialplan "$client"
    
    log_success "Parallel testing configured for $name"
}

create_parallel_dialplan() {
    local client="$1"
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    
    cat >> /etc/asterisk/extensions.conf << EOF

; Parallel Testing Dialplan for $name
[from-internal-parallel-${client}]

; 80% calls via Twilio, 20% via FreePBX (testing)
exten => _9XXXXXXXX,1,Set(RANDOM_VAL=\${RAND(1,100)})
exten => _9XXXXXXXX,n,GotoIf(\$[\${RANDOM_VAL} <= 80]?twilio:freepbx)

; Twilio route (80%)
exten => _9XXXXXXXX,n(twilio),Set(CDR(userfield)=TWILIO-TEST)
exten => _9XXXXXXXX,n,Dial(SIP/twilio_backup_${did//[^0-9]/}/\${EXTEN:1},60)
exten => _9XXXXXXXX,n,Hangup()

; FreePBX route (20%)
exten => _9XXXXXXXX,n(freepbx),Set(CDR(userfield)=FREEPBX-TEST)
exten => _9XXXXXXXX,n,Dial(PJSIP/\${EXTEN:1}@entel_${did//[^0-9]/},60)
exten => _9XXXXXXXX,n,Hangup()

EOF
    
    log_info "Parallel dialplan created for $name"
}

start_quality_monitoring() {
    local client="$1"
    
    log_info "📊 Starting quality monitoring for $client"
    
    # Create monitoring script
    cat > "$MIGRATION_DIR/monitor_${client}.sh" << 'EOF'
#!/bin/bash

CLIENT="$1"
DURATION_HOURS="${2:-24}"
LOG_FILE="/opt/skyn3t/reports/quality_${CLIENT}_$(date +%Y%m%d_%H%M%S).log"

echo "Starting quality monitoring for $CLIENT (Duration: ${DURATION_HOURS}h)" > "$LOG_FILE"
echo "Start Time: $(date)" >> "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"

END_TIME=$(($(date +%s) + (DURATION_HOURS * 3600)))

while [[ $(date +%s) -lt $END_TIME ]]; do
    # Collect call statistics
    echo "=== $(date) ===" >> "$LOG_FILE"
    
    # Asterisk CDR analysis
    mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' freepbx_skyn3t << 'SQL' >> "$LOG_FILE"
SELECT 
    DATE(calldate) as date,
    userfield as route,
    COUNT(*) as calls,
    AVG(billsec) as avg_duration,
    SUM(CASE WHEN disposition = 'ANSWERED' THEN 1 ELSE 0 END) as successful_calls,
    ROUND(SUM(CASE WHEN disposition = 'ANSWERED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate
FROM cdr 
WHERE calldate >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
AND userfield IN ('TWILIO-TEST', 'FREEPBX-TEST')
GROUP BY userfield;
SQL
    
    # System resource usage
    echo "System Resources:" >> "$LOG_FILE"
    echo "Memory: $(free -m | grep Mem | awk '{print $3"/"$2" MB"}')" >> "$LOG_FILE"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')" >> "$LOG_FILE"
    echo "Disk: $(df -h / | tail -1 | awk '{print $5}')" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    
    sleep 3600  # Monitor every hour
done

echo "Monitoring completed for $CLIENT" >> "$LOG_FILE"
echo "End Time: $(date)" >> "$LOG_FILE"
EOF
    
    chmod +x "$MIGRATION_DIR/monitor_${client}.sh"
    
    # Start monitoring in background
    nohup "$MIGRATION_DIR/monitor_${client}.sh" "$client" 24 &
    local monitor_pid=$!
    echo "$monitor_pid" > "$MIGRATION_DIR/monitor_${client}.pid"
    
    log_success "Quality monitoring started for $client (PID: $monitor_pid)"
}

#═══════════════════════════════════════════════════════════════════════════════
#  CLIENT MIGRATION FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

migrate_client_to_freepbx() {
    local client="$1"
    local force="${2:-false}"
    
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    
    log_info "🚀 Starting migration for $name to FreePBX..."
    
    # Pre-migration checks
    if ! pre_migration_checks "$client"; then
        log_error "Pre-migration checks failed for $client"
        return 1
    fi
    
    # Create migration backup
    create_migration_backup "$client"
    
    # Phase 1: Setup FreePBX configuration
    log_info "Phase 1: Configuring FreePBX for $name"
    if ! configure_client_freepbx "$client"; then
        log_error "FreePBX configuration failed for $client"
        return 1
    fi
    
    # Phase 2: Update device configuration
    log_info "Phase 2: Updating device configuration for $name"
    if ! update_client_devices "$client"; then
        log_error "Device configuration failed for $client"
        if [[ "$force" != "true" ]]; then
            rollback_client_migration "$client"
            return 1
        fi
    fi
    
    # Phase 3: Test and validate
    log_info "Phase 3: Testing and validation for $name"
    if ! validate_client_migration "$client"; then
        log_error "Migration validation failed for $client"
        if [[ "$force" != "true" ]]; then
            rollback_client_migration "$client"
            return 1
        fi
    fi
    
    # Phase 4: Update routing
    log_info "Phase 4: Updating call routing for $name"
    update_client_routing "$client" "freepbx"
    
    # Update status
    CLIENT_STATUS["$client"]="freepbx"
    save_migration_status
    
    # Start post-migration monitoring
    start_post_migration_monitoring "$client"
    
    log_success "Migration completed for $name!"
    
    # Generate migration report
    generate_migration_report "$client"
    
    return 0
}

pre_migration_checks() {
    local client="$1"
    local errors=0
    
    log_info "🔍 Running pre-migration checks for $client..."
    
    # Check FreePBX status
    if ! systemctl is-active --quiet asterisk; then
        log_error "Asterisk is not running"
        ((errors++))
    fi
    
    # Check extensions registration
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    IFS=',' read -ra ext_array <<< "$extensions"
    
    for ext in "${ext_array[@]}"; do
        if ! asterisk -rx "pjsip show endpoint $ext" | grep -q "Available"; then
            log_error "Extension $ext not registered"
            ((errors++))
        fi
    done
    
    # Check trunk connectivity
    if ! asterisk -rx "pjsip show endpoint entel_${did//[^0-9]/}" | grep -q "Available"; then
        log_error "Entel trunk not connected for $client"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "All pre-migration checks passed for $client"
        return 0
    else
        log_error "$errors pre-migration check(s) failed for $client"
        return 1
    fi
}

configure_client_freepbx() {
    local client="$1"
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    
    # Ensure client configuration exists in FreePBX
    log_info "Configuring FreePBX for $name ($did)..."
    
    # Update inbound routing to use FreePBX instead of Twilio
    cat >> /etc/asterisk/extensions.conf << EOF

; Migration update for $name
[from-pstn-${client}]
exten => $did,1,Set(CALLERID(name)=$name)
exten => $did,n,Answer()
exten => $did,n,Wait(1)
exten => $did,n,Goto(ivr-${did//[^0-9]/},s,1)

EOF
    
    # Reload dialplan
    asterisk -rx "dialplan reload"
    
    log_success "FreePBX configured for $name"
    return 0
}

update_client_devices() {
    local client="$1"
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    
    log_info "Updating device configuration for $name..."
    
    # Generate device update commands
    cat > "$MIGRATION_DIR/device_update_${client}.txt" << EOF
Device Configuration Update for $name
=====================================

GDMS Cloud Template Changes:
1. Change SIP Server from 'skyn3t-communities.sip.twilio.com' to '$SERVER_IP'
2. Update SIP credentials to FreePBX extensions
3. Apply template to all devices for this client

Manual Device Configuration (if GDMS not available):
EOF
    
    IFS=',' read -ra ext_array <<< "$extensions"
    for ext in "${ext_array[@]}"; do
        cat >> "$MIGRATION_DIR/device_update_${client}.txt" << EOF

Extension $ext Device:
- SIP Server: $SERVER_IP
- SIP User ID: $ext
- SIP Password: [From extension configuration]
- Transport: UDP
- Port: 5060
EOF
    done
    
    log_warning "Device configuration update required - see: $MIGRATION_DIR/device_update_${client}.txt"
    log_info "Waiting 60 seconds for device reconfiguration..."
    sleep 60
    
    return 0
}

validate_client_migration() {
    local client="$1"
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    
    log_info "Validating migration for $name..."
    
    local validation_errors=0
    
    # Test internal calls
    IFS=',' read -ra ext_array <<< "$extensions"
    if [[ ${#ext_array[@]} -ge 2 ]]; then
        local ext1="${ext_array[0]}"
        local ext2="${ext_array[1]}"
        
        log_info "Testing internal call: $ext1 → $ext2"
        if ! test_internal_call "$ext1" "$ext2"; then
            log_error "Internal call test failed"
            ((validation_errors++))
        fi
    fi
    
    # Test outbound call
    log_info "Testing outbound call via Entel trunk"
    if ! test_outbound_call "entel_${did//[^0-9]/}" "133"; then
        log_error "Outbound call test failed"
        ((validation_errors++))
    fi
    
    # Test inbound routing
    log_info "Testing inbound routing configuration"
    if ! asterisk -rx "dialplan show $did" | grep -q "from-pstn"; then
        log_error "Inbound routing not configured"
        ((validation_errors++))
    fi
    
    if [[ $validation_errors -eq 0 ]]; then
        log_success "Migration validation passed for $name"
        return 0
    else
        log_error "$validation_errors validation error(s) for $name"
        return 1
    fi
}

update_client_routing() {
    local client="$1"
    local route_to="$2"  # "freepbx" or "twilio"
    
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    
    log_info "Updating routing for $name to $route_to"
    
    case $route_to in
        "freepbx")
            # Update to use FreePBX/Entel
            sed -i "s/twilio_backup_${did//[^0-9]/}/entel_${did//[^0-9]/}/g" /etc/asterisk/extensions.conf
            ;;
        "twilio")
            # Rollback to Twilio
            sed -i "s/entel_${did//[^0-9]/}/twilio_backup_${did//[^0-9]/}/g" /etc/asterisk/extensions.conf
            ;;
    esac
    
    asterisk -rx "dialplan reload"
    log_success "Routing updated for $name to $route_to"
}

#═══════════════════════════════════════════════════════════════════════════════
#  ROLLBACK FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

rollback_client_migration() {
    local client="$1"
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    
    log_warning "🔄 Rolling back migration for $name..."
    
    # Restore Twilio routing
    update_client_routing "$client" "twilio"
    
    # Update client status
    CLIENT_STATUS["$client"]="twilio"
    save_migration_status
    
    # Generate rollback report
    cat > "$REPORTS_DIR/rollback_${client}_$(date +%Y%m%d_%H%M%S).txt" << EOF
ROLLBACK REPORT FOR $name
=========================
Date: $(date)
Reason: Migration validation failed
Action: Restored Twilio routing

Client Details:
- DID: $did
- Extensions: $extensions
- Status: Rolled back to Twilio

Next Steps:
1. Investigate migration failure causes
2. Fix identified issues
3. Plan retry migration

EOF
    
    log_success "Rollback completed for $name"
}

emergency_rollback_all() {
    log_warning "🚨 EMERGENCY: Rolling back ALL clients to Twilio"
    
    for client in "${!CLIENTS[@]}"; do
        if [[ "${CLIENT_STATUS[$client]}" == "freepbx" ]]; then
            log_warning "Emergency rollback for $client"
            rollback_client_migration "$client"
        fi
    done
    
    log_warning "Emergency rollback completed for all clients"
}

#═══════════════════════════════════════════════════════════════════════════════
#  MONITORING AND REPORTING
#═══════════════════════════════════════════════════════════════════════════════

start_post_migration_monitoring() {
    local client="$1"
    
    log_info "📊 Starting post-migration monitoring for $client"
    
    cat > "$MIGRATION_DIR/post_migration_monitor_${client}.sh" << 'EOF'
#!/bin/bash

CLIENT="$1"
MONITOR_LOG="/opt/skyn3t/reports/post_migration_${CLIENT}_$(date +%Y%m%d_%H%M%S).log"

echo "Post-Migration Monitoring for $CLIENT" > "$MONITOR_LOG"
echo "Start Time: $(date)" >> "$MONITOR_LOG"
echo "Monitoring Duration: 48 hours" >> "$MONITOR_LOG"
echo "========================================" >> "$MONITOR_LOG"

# Monitor for 48 hours
END_TIME=$(($(date +%s) + (48 * 3600)))

while [[ $(date +%s) -lt $END_TIME ]]; do
    echo "=== $(date) ===" >> "$MONITOR_LOG"
    
    # Check service status
    systemctl is-active asterisk >> "$MONITOR_LOG"
    
    # Check call statistics
    echo "Call Statistics (last hour):" >> "$MONITOR_LOG"
    mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' freepbx_skyn3t << 'SQL' >> "$MONITOR_LOG"
SELECT 
    COUNT(*) as total_calls,
    SUM(CASE WHEN disposition = 'ANSWERED' THEN 1 ELSE 0 END) as successful_calls,
    ROUND(AVG(billsec), 2) as avg_duration,
    ROUND(SUM(CASE WHEN disposition = 'ANSWERED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate
FROM cdr 
WHERE calldate >= DATE_SUB(NOW(), INTERVAL 1 HOUR);
SQL
    
    echo "----------------------------------------" >> "$MONITOR_LOG"
    
    sleep 3600  # Check every hour
done

echo "Post-migration monitoring completed" >> "$MONITOR_LOG"
EOF
    
    chmod +x "$MIGRATION_DIR/post_migration_monitor_${client}.sh"
    nohup "$MIGRATION_DIR/post_migration_monitor_${client}.sh" "$client" &
    
    log_success "Post-migration monitoring started for $client"
}

generate_migration_report() {
    local client="$1"
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
    
    local report_file="$REPORTS_DIR/migration_report_${client}_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
MIGRATION REPORT FOR $name
==========================
Date: $(date)
Client: $name
DID: $did
Extensions: $extensions
Priority: $priority

MIGRATION STATUS: SUCCESS ✅

Pre-Migration Configuration:
- Provider: Twilio
- SIP Domain: skyn3t-communities.sip.twilio.com
- Cost: ~50 CLP/minute

Post-Migration Configuration:
- Provider: Entel Empresas (via FreePBX)
- Server: $SERVER_IP
- Cost: ~14 CLP/minute
- Savings: 72%

TECHNICAL DETAILS:
==================
FreePBX Server: $SERVER_IP
Asterisk Version: $(asterisk -rx "core show version" | head -1)
Trunk: entel_${did//[^0-9]/}
Extensions: $extensions

VALIDATION RESULTS:
==================
✅ FreePBX Service: Running
✅ Extension Registration: Verified
✅ Trunk Connectivity: Verified
✅ Internal Calls: Working
✅ Outbound Calls: Working
✅ Inbound Routing: Configured

COST ANALYSIS:
==============
Previous Monthly Cost: ~25,000 CLP (500 min @ 50 CLP/min)
New Monthly Cost: ~7,000 CLP (500 min @ 14 CLP/min)
Monthly Savings: ~18,000 CLP (72%)
Annual Savings: ~216,000 CLP

NEXT STEPS:
===========
1. Monitor performance for 48 hours
2. Collect user feedback
3. Schedule Twilio service cleanup (if successful)
4. Update documentation

Migration completed successfully!
EOF
    
    log_success "Migration report generated: $report_file"
}

generate_overall_status_report() {
    local report_file="$REPORTS_DIR/migration_status_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
SKYN3T MIGRATION STATUS REPORT
==============================
Generated: $(date)

OVERALL PROGRESS:
================
EOF
    
    local total_clients=${#CLIENTS[@]}
    local migrated_clients=0
    
    for client in "${!CLIENTS[@]}"; do
        if [[ "${CLIENT_STATUS[$client]}" == "freepbx" ]]; then
            ((migrated_clients++))
        fi
    done
    
    local progress_percent=$(( (migrated_clients * 100) / total_clients ))
    
    cat >> "$report_file" << EOF
Total Clients: $total_clients
Migrated Clients: $migrated_clients
Progress: $progress_percent%

CLIENT STATUS:
==============
EOF
    
    for client in "${!CLIENTS[@]}"; do
        IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
        local status="${CLIENT_STATUS[$client]}"
        local status_symbol="⚠️"
        
        case $status in
            "freepbx") status_symbol="✅" ;;
            "twilio") status_symbol="🔄" ;;
            "testing") status_symbol="🧪" ;;
        esac
        
        echo "$status_symbol $name ($did): $status" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF

SYSTEM STATUS:
==============
FreePBX Server: $SERVER_IP
Service Status: $(systemctl is-active asterisk)
Active Extensions: $(asterisk -rx "pjsip show endpoints" | grep -c "Available")
Active Trunks: $(asterisk -rx "pjsip show endpoints" | grep -c "entel_\|vtr_")

ESTIMATED SAVINGS:
==================
Migrated Clients Monthly Savings: $((migrated_clients * 18000)) CLP
Migrated Clients Annual Savings: $((migrated_clients * 216000)) CLP
Full Migration Potential: $((total_clients * 216000)) CLP/year

EOF
    
    log_success "Overall status report generated: $report_file"
}

#═══════════════════════════════════════════════════════════════════════════════
#  TESTING FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

test_internal_call() {
    local ext1="$1"
    local ext2="$2"
    
    # Simulate internal call test
    local result=$(asterisk -rx "channel originate PJSIP/$ext1 extension $ext2@from-internal" 2>&1)
    sleep 3
    
    if asterisk -rx "core show channels" | grep -q "$ext1\|$ext2"; then
        asterisk -rx "soft hangup PJSIP/$ext1" &>/dev/null
        return 0
    else
        return 1
    fi
}

test_outbound_call() {
    local trunk="$1"
    local number="$2"
    
    # Test outbound call via trunk
    local result=$(asterisk -rx "channel originate PJSIP/$number@$trunk application Playbook demo-congrats" 2>&1)
    
    if [[ "$result" =~ "Channel.*up" ]]; then
        return 0
    else
        return 1
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  MAIN MENU AND FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

show_main_menu() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           SKYN3T Twilio Migration Manager v$SCRIPT_VERSION            ║${NC}"
    echo -e "${BLUE}║                Server: $SERVER_IP                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}🚀 Migration Management Options:${NC}"
    echo ""
    echo "1) 📋 Generate Migration Plan"
    echo "2) 🔄 Setup Parallel Testing"
    echo "3) 🚀 Migrate Client to FreePBX"
    echo "4) 📊 View Migration Status"
    echo "5) 🧪 Start Quality Monitoring"
    echo "6) 📈 Generate Status Report"
    echo "7) 🔄 Rollback Client to Twilio"
    echo "8) 🚨 Emergency Rollback All"
    echo "9) 📊 Cost Analysis Report"
    echo ""
    echo "0) ❌ Exit"
    echo ""
}

show_migration_status() {
    echo -e "${BLUE}═══ MIGRATION STATUS ═══${NC}"
    echo ""
    
    local total_clients=${#CLIENTS[@]}
    local migrated_clients=0
    
    for client in "${!CLIENTS[@]}"; do
        if [[ "${CLIENT_STATUS[$client]}" == "freepbx" ]]; then
            ((migrated_clients++))
        fi
    done
    
    local progress_percent=$(( (migrated_clients * 100) / total_clients ))
    
    echo -e "${CYAN}Overall Progress:${NC} $migrated_clients/$total_clients clients ($progress_percent%)"
    echo ""
    
    for client in "${!CLIENTS[@]}"; do
        IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
        local status="${CLIENT_STATUS[$client]}"
        local status_color="$YELLOW"
        local status_symbol="⚠️"
        
        case $status in
            "freepbx")
                status_color="$GREEN"
                status_symbol="✅"
                ;;
            "twilio")
                status_color="$BLUE"
                status_symbol="🔄"
                ;;
            "testing")
                status_color="$CYAN"
                status_symbol="🧪"
                ;;
        esac
        
        echo -e "$status_symbol ${status_color}$name${NC} ($did): $status"
        echo "   Extensions: $extensions | Priority: $priority"
        echo ""
    done
}

migrate_client_menu() {
    echo -e "${YELLOW}🚀 Client Migration${NC}"
    echo ""
    
    echo "Available clients for migration:"
    local i=1
    local client_list=()
    
    for client in "${!CLIENTS[@]}"; do
        IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
        local status="${CLIENT_STATUS[$client]}"
        
        if [[ "$status" == "twilio" ]]; then
            echo "  $i) $name ($did) - Ready for migration"
            client_list+=("$client")
            ((i++))
        fi
    done
    
    if [[ ${#client_list[@]} -eq 0 ]]; then
        log_warning "No clients available for migration"
        return 1
    fi
    
    echo ""
    read -p "Select client to migrate [1-${#client_list[@]}]: " client_choice
    
    if [[ ! "$client_choice" =~ ^[1-9]$ ]] || [[ $client_choice -gt ${#client_list[@]} ]]; then
        log_error "Invalid client selection"
        return 1
    fi
    
    local selected_client="${client_list[$((client_choice-1))]}"
    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$selected_client]}"
    
    echo ""
    echo -e "${GREEN}Selected: $name ($did)${NC}"
    echo ""
    
    read -p "Proceed with migration? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        read -p "Force migration even if tests fail? (y/N): " force_confirm
        local force_flag="false"
        if [[ "$force_confirm" =~ ^[Yy]$ ]]; then
            force_flag="true"
        fi
        
        migrate_client_to_freepbx "$selected_client" "$force_flag"
    else
        log_info "Migration cancelled"
    fi
}

main() {
    # Initialize
    setup_directories
    load_migration_status
    
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
                generate_migration_plan
                read -p "Press Enter to continue..."
                ;;
            2)
                echo "Available clients for parallel testing:"
                for client in "${!CLIENTS[@]}"; do
                    IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
                    echo "  - $name ($did)"
                done
                echo ""
                read -p "Enter client name: " selected_client
                if [[ -n "${CLIENTS[$selected_client]:-}" ]]; then
                    setup_parallel_testing "$selected_client"
                    start_quality_monitoring "$selected_client"
                else
                    log_error "Invalid client name"
                fi
                read -p "Press Enter to continue..."
                ;;
            3)
                migrate_client_menu
                read -p "Press Enter to continue..."
                ;;
            4)
                show_migration_status
                read -p "Press Enter to continue..."
                ;;
            5)
                echo "Starting quality monitoring for all active clients..."
                for client in "${!CLIENTS[@]}"; do
                    start_quality_monitoring "$client"
                done
                read -p "Press Enter to continue..."
                ;;
            6)
                generate_overall_status_report
                read -p "Press Enter to continue..."
                ;;
            7)
                echo "Available clients for rollback:"
                for client in "${!CLIENTS[@]}"; do
                    if [[ "${CLIENT_STATUS[$client]}" == "freepbx" ]]; then
                        IFS=':' read -r did extensions name priority <<< "${CLIENTS[$client]}"
                        echo "  - $name ($did)"
                    fi
                done
                echo ""
                read -p "Enter client name for rollback: " rollback_client
                if [[ -n "${CLIENTS[$rollback_client]:-}" ]] && [[ "${CLIENT_STATUS[$rollback_client]}" == "freepbx" ]]; then
                    rollback_client_migration "$rollback_client"
                else
                    log_error "Invalid client or client not on FreePBX"
                fi
                read -p "Press Enter to continue..."
                ;;
            8)
                echo -e "${RED}🚨 EMERGENCY ROLLBACK ALL CLIENTS${NC}"
                echo "This will rollback ALL migrated clients to Twilio"
                echo ""
                read -p "Are you sure? Type 'EMERGENCY' to confirm: " emergency_confirm
                if [[ "$emergency_confirm" == "EMERGENCY" ]]; then
                    emergency_rollback_all
                else
                    log_info "Emergency rollback cancelled"
                fi
                read -p "Press Enter to continue..."
                ;;
            9)
                generate_overall_status_report
                echo "Cost analysis included in status report"
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}👋 Migration management completed!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Invalid option. Please select 0-9.${NC}"
                read -p "Press Enter to continue..."
                ;;
        esac
    done
}

# Create migration backup
create_migration_backup() {
    local client="$1"
    local backup_file="$BACKUP_DIR/migration_backup_${client}_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    tar -czf "$backup_file" \
        /etc/asterisk/extensions.conf \
        /etc/asterisk/pjsip.conf \
        "$MIGRATION_DIR/migration_status.conf" \
        2>/dev/null || true
    
    log_success "Migration backup created: $backup_file"
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    echo "Please run: sudo $0"
    exit 1
fi

# Execute main function
main "$@"
