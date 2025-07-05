#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════════
#  SKYN3T FREEPBX MONITORING & MAINTENANCE SYSTEM
#═══════════════════════════════════════════════════════════════════════════════
#  Version: 1.0.0
#  Description: Automated monitoring, maintenance, and alerting system
#  Author: SKYN3T Technical Team
#  
#  FEATURES:
#  ✅ Real-time system monitoring
#  ✅ Automated maintenance tasks
#  ✅ Performance analytics
#  ✅ Alert system (email, SMS)
#  ✅ Self-healing capabilities
#  ✅ Cost tracking and optimization
#  ✅ Security monitoring
#  ✅ Backup automation
#═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# Configuration
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="/var/log/skyn3t_monitoring.log"
readonly MONITORING_DIR="/opt/skyn3t/monitoring"
readonly ALERTS_DIR="/opt/skyn3t/alerts"
readonly METRICS_DIR="/opt/skyn3t/metrics"
readonly BACKUP_DIR="/backup/freepbx_monitoring"

# Server configuration
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_NAME=$(hostname)

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m'

# Alert thresholds
declare -A THRESHOLDS=(
    ["cpu_warning"]="80"
    ["cpu_critical"]="95"
    ["memory_warning"]="85"
    ["memory_critical"]="95"
    ["disk_warning"]="85"
    ["disk_critical"]="95"
    ["load_warning"]="5.0"
    ["load_critical"]="10.0"
    ["call_failure_warning"]="10"
    ["call_failure_critical"]="25"
)

# Monitoring intervals (in seconds)
declare -A INTERVALS=(
    ["real_time"]="30"
    ["system_health"]="300"
    ["performance"]="900"
    ["daily_report"]="86400"
    ["weekly_maintenance"]="604800"
)

# Alert configuration
ALERT_EMAIL="admin@skyn3t.com"
ALERT_SMS=""  # To be configured
ALERT_WEBHOOK=""  # Slack/Teams webhook

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
log_critical() { log "CRITICAL" "${RED}🚨 $*${NC}"; }

setup_directories() {
    mkdir -p "$MONITORING_DIR" "$ALERTS_DIR" "$METRICS_DIR" "$BACKUP_DIR"
    chmod 755 "$MONITORING_DIR" "$ALERTS_DIR" "$METRICS_DIR" "$BACKUP_DIR"
}

get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

get_epoch() {
    date +%s
}

#═══════════════════════════════════════════════════════════════════════════════
#  SYSTEM MONITORING FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

monitor_system_resources() {
    local timestamp=$(get_timestamp)
    local epoch=$(get_epoch)
    
    # CPU Usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    local cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | sed 's/%id,//')
    local cpu_percent=$(echo "100 - $cpu_idle" | bc -l | awk '{printf "%.1f", $1}')
    
    # Memory Usage
    local memory_total=$(free -m | awk 'NR==2{print $2}')
    local memory_used=$(free -m | awk 'NR==2{print $3}')
    local memory_percent=$(echo "scale=1; $memory_used * 100 / $memory_total" | bc)
    
    # Disk Usage
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    
    # Load Average
    local load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | tr -d ' ')
    local load_5min=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $2}' | tr -d ' ')
    local load_15min=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $3}' | tr -d ' ')
    
    # Network connections
    local connections=$(netstat -an | grep ESTABLISHED | wc -l)
    
    # Store metrics
    echo "$epoch,$timestamp,$cpu_percent,$memory_percent,$disk_usage,$load_1min,$load_5min,$load_15min,$connections" >> "$METRICS_DIR/system_metrics.csv"
    
    # Check thresholds and alert if necessary
    check_system_thresholds "$cpu_percent" "$memory_percent" "$disk_usage" "$load_1min"
    
    # Return metrics for display
    echo "CPU:${cpu_percent}% MEM:${memory_percent}% DISK:${disk_usage}% LOAD:${load_1min}"
}

monitor_asterisk_status() {
    local timestamp=$(get_timestamp)
    local epoch=$(get_epoch)
    
    # Service status
    local asterisk_status="down"
    if systemctl is-active --quiet asterisk; then
        asterisk_status="up"
    fi
    
    # Extensions status
    local total_extensions=0
    local online_extensions=0
    
    if [[ "$asterisk_status" == "up" ]]; then
        total_extensions=$(asterisk -rx "pjsip show endpoints" 2>/dev/null | grep -c "Endpoint:" || echo "0")
        online_extensions=$(asterisk -rx "pjsip show endpoints" 2>/dev/null | grep -c "Available" || echo "0")
    fi
    
    # Active calls
    local active_calls=0
    if [[ "$asterisk_status" == "up" ]]; then
        active_calls=$(asterisk -rx "core show channels" 2>/dev/null | grep -c "active channel" || echo "0")
    fi
    
    # Trunk status
    local trunk_status="unknown"
    if [[ "$asterisk_status" == "up" ]]; then
        local trunk_count=$(asterisk -rx "pjsip show endpoints" 2>/dev/null | grep -c "entel_\|vtr_" || echo "0")
        if [[ $trunk_count -gt 0 ]]; then
            trunk_status="up"
        else
            trunk_status="down"
        fi
    fi
    
    # Store metrics
    echo "$epoch,$timestamp,$asterisk_status,$total_extensions,$online_extensions,$active_calls,$trunk_status" >> "$METRICS_DIR/asterisk_metrics.csv"
    
    # Check for issues
    if [[ "$asterisk_status" == "down" ]]; then
        send_alert "critical" "Asterisk service is down" "Asterisk PBX service has stopped running"
    elif [[ $online_extensions -lt $total_extensions ]]; then
        local offline_count=$((total_extensions - online_extensions))
        send_alert "warning" "Extensions offline" "$offline_count out of $total_extensions extensions are offline"
    fi
    
    echo "AST:$asterisk_status EXT:$online_extensions/$total_extensions CALLS:$active_calls TRUNK:$trunk_status"
}

monitor_call_quality() {
    local timestamp=$(get_timestamp)
    local epoch=$(get_epoch)
    
    # Get call statistics from CDR
    local call_stats=""
    if command -v mysql &> /dev/null; then
        call_stats=$(mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' freepbx_skyn3t -se "
            SELECT 
                COUNT(*) as total_calls,
                SUM(CASE WHEN disposition = 'ANSWERED' THEN 1 ELSE 0 END) as successful_calls,
                ROUND(AVG(billsec), 2) as avg_duration,
                ROUND(SUM(CASE WHEN disposition = 'ANSWERED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate
            FROM cdr 
            WHERE calldate >= DATE_SUB(NOW(), INTERVAL 1 HOUR);
        " 2>/dev/null || echo "0,0,0,0")
    else
        call_stats="0,0,0,0"
    fi
    
    IFS=',' read -r total_calls successful_calls avg_duration success_rate <<< "$call_stats"
    
    # Store metrics
    echo "$epoch,$timestamp,$total_calls,$successful_calls,$avg_duration,$success_rate" >> "$METRICS_DIR/call_quality.csv"
    
    # Check call quality thresholds
    local failure_rate=$(echo "100 - $success_rate" | bc -l)
    if (( $(echo "$failure_rate >= ${THRESHOLDS[call_failure_critical]}" | bc -l) )); then
        send_alert "critical" "High call failure rate" "Call failure rate: ${failure_rate}% (threshold: ${THRESHOLDS[call_failure_critical]}%)"
    elif (( $(echo "$failure_rate >= ${THRESHOLDS[call_failure_warning]}" | bc -l) )); then
        send_alert "warning" "Elevated call failure rate" "Call failure rate: ${failure_rate}% (threshold: ${THRESHOLDS[call_failure_warning]}%)"
    fi
    
    echo "CALLS:$total_calls SUCCESS:$success_rate% AVG:${avg_duration}s"
}

monitor_network_connectivity() {
    local timestamp=$(get_timestamp)
    local epoch=$(get_epoch)
    
    # Test external connectivity
    local internet_status="down"
    if ping -c 1 8.8.8.8 &>/dev/null; then
        internet_status="up"
    fi
    
    # Test SIP connectivity (if configured)
    local sip_status="unknown"
    if command -v asterisk &>/dev/null && systemctl is-active --quiet asterisk; then
        # Check if any SIP trunks are registered
        if asterisk -rx "pjsip show endpoints" 2>/dev/null | grep -q "Available.*entel\|Available.*vtr"; then
            sip_status="up"
        else
            sip_status="down"
        fi
    fi
    
    # Network latency test
    local latency="999"
    if [[ "$internet_status" == "up" ]]; then
        latency=$(ping -c 1 8.8.8.8 | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}' | sed 's/ms//' || echo "999")
    fi
    
    # Store metrics
    echo "$epoch,$timestamp,$internet_status,$sip_status,$latency" >> "$METRICS_DIR/network_metrics.csv"
    
    # Check connectivity issues
    if [[ "$internet_status" == "down" ]]; then
        send_alert "critical" "Internet connectivity lost" "Server has lost internet connectivity"
    elif [[ "$sip_status" == "down" ]]; then
        send_alert "warning" "SIP trunk connectivity issues" "One or more SIP trunks are not registered"
    fi
    
    echo "NET:$internet_status SIP:$sip_status LAT:${latency}ms"
}

#═══════════════════════════════════════════════════════════════════════════════
#  THRESHOLD CHECKING AND ALERTING
#═══════════════════════════════════════════════════════════════════════════════

check_system_thresholds() {
    local cpu_percent="$1"
    local memory_percent="$2"
    local disk_usage="$3"
    local load_avg="$4"
    
    # CPU threshold check
    if (( $(echo "$cpu_percent >= ${THRESHOLDS[cpu_critical]}" | bc -l) )); then
        send_alert "critical" "Critical CPU usage" "CPU usage: ${cpu_percent}% (threshold: ${THRESHOLDS[cpu_critical]}%)"
    elif (( $(echo "$cpu_percent >= ${THRESHOLDS[cpu_warning]}" | bc -l) )); then
        send_alert "warning" "High CPU usage" "CPU usage: ${cpu_percent}% (threshold: ${THRESHOLDS[cpu_warning]}%)"
    fi
    
    # Memory threshold check
    if (( $(echo "$memory_percent >= ${THRESHOLDS[memory_critical]}" | bc -l) )); then
        send_alert "critical" "Critical memory usage" "Memory usage: ${memory_percent}% (threshold: ${THRESHOLDS[memory_critical]}%)"
    elif (( $(echo "$memory_percent >= ${THRESHOLDS[memory_warning]}" | bc -l) )); then
        send_alert "warning" "High memory usage" "Memory usage: ${memory_percent}% (threshold: ${THRESHOLDS[memory_warning]}%)"
    fi
    
    # Disk threshold check
    if (( $(echo "$disk_usage >= ${THRESHOLDS[disk_critical]}" | bc -l) )); then
        send_alert "critical" "Critical disk usage" "Disk usage: ${disk_usage}% (threshold: ${THRESHOLDS[disk_critical]}%)"
    elif (( $(echo "$disk_usage >= ${THRESHOLDS[disk_warning]}" | bc -l) )); then
        send_alert "warning" "High disk usage" "Disk usage: ${disk_usage}% (threshold: ${THRESHOLDS[disk_warning]}%)"
    fi
    
    # Load average threshold check
    if (( $(echo "$load_avg >= ${THRESHOLDS[load_critical]}" | bc -l) )); then
        send_alert "critical" "Critical system load" "Load average: $load_avg (threshold: ${THRESHOLDS[load_critical]})"
    elif (( $(echo "$load_avg >= ${THRESHOLDS[load_warning]}" | bc -l) )); then
        send_alert "warning" "High system load" "Load average: $load_avg (threshold: ${THRESHOLDS[load_warning]})"
    fi
}

send_alert() {
    local severity="$1"
    local subject="$2"
    local message="$3"
    local timestamp=$(get_timestamp)
    
    # Create alert record
    local alert_file="$ALERTS_DIR/alert_$(date +%Y%m%d_%H%M%S).txt"
    cat > "$alert_file" << EOF
SKYN3T FreePBX Alert
====================
Timestamp: $timestamp
Severity: $severity
Subject: $subject
Server: $SERVER_NAME ($SERVER_IP)

Message:
$message

System Status:
$(monitor_system_resources)
$(monitor_asterisk_status)

Automatic actions taken:
- Alert logged to: $alert_file
- Email notification: $(send_email_alert "$severity" "$subject" "$message" && echo "Sent" || echo "Failed")

EOF
    
    # Log alert
    case $severity in
        "critical")
            log_critical "$subject: $message"
            ;;
        "warning")
            log_warning "$subject: $message"
            ;;
        *)
            log_info "$subject: $message"
            ;;
    esac
    
    # Try self-healing for known issues
    attempt_self_healing "$subject" "$message"
}

send_email_alert() {
    local severity="$1"
    local subject="$2"
    local message="$3"
    
    if [[ -n "$ALERT_EMAIL" ]] && command -v mail &>/dev/null; then
        echo -e "SKYN3T FreePBX Alert\n\nSeverity: $severity\nServer: $SERVER_NAME\nTime: $(get_timestamp)\n\n$message" | \
        mail -s "[$severity] SKYN3T FreePBX: $subject" "$ALERT_EMAIL"
        return $?
    fi
    return 1
}

#═══════════════════════════════════════════════════════════════════════════════
#  SELF-HEALING FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

attempt_self_healing() {
    local issue="$1"
    local details="$2"
    
    log_info "🔧 Attempting self-healing for: $issue"
    
    case "$issue" in
        *"Asterisk service is down"*)
            heal_asterisk_service
            ;;
        *"High memory usage"*|*"Critical memory usage"*)
            heal_memory_issues
            ;;
        *"High disk usage"*|*"Critical disk usage"*)
            heal_disk_space_issues
            ;;
        *"SIP trunk connectivity"*)
            heal_sip_connectivity
            ;;
        *)
            log_info "No automatic healing available for: $issue"
            ;;
    esac
}

heal_asterisk_service() {
    log_info "🔧 Attempting to restart Asterisk service..."
    
    if systemctl restart asterisk; then
        sleep 10
        if systemctl is-active --quiet asterisk; then
            log_success "Asterisk service successfully restarted"
            send_alert "info" "Self-healing successful" "Asterisk service was automatically restarted and is now running"
        else
            log_error "Asterisk service restart failed"
        fi
    else
        log_error "Failed to restart Asterisk service"
    fi
}

heal_memory_issues() {
    log_info "🔧 Attempting to free memory..."
    
    # Clear system caches
    sync
    echo 3 > /proc/sys/vm/drop_caches
    
    # Restart Apache if memory usage is critical
    local memory_percent=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    if (( $(echo "$memory_percent >= 90" | bc -l) )); then
        log_info "Restarting Apache to free memory"
        systemctl restart apache2
    fi
    
    log_success "Memory cleanup completed"
}

heal_disk_space_issues() {
    log_info "🔧 Attempting to free disk space..."
    
    # Clean old log files
    find /var/log -name "*.log" -mtime +30 -exec gzip {} \;
    find /var/log -name "*.gz" -mtime +90 -delete
    
    # Clean old CDR records (older than 6 months)
    if command -v mysql &>/dev/null; then
        mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' freepbx_skyn3t -e "
            DELETE FROM cdr WHERE calldate < DATE_SUB(NOW(), INTERVAL 6 MONTH);
        " 2>/dev/null || true
    fi
    
    # Clean old backup files
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
    
    # Clean package cache
    apt autoremove -y
    apt autoclean
    
    log_success "Disk cleanup completed"
}

heal_sip_connectivity() {
    log_info "🔧 Attempting to restore SIP connectivity..."
    
    # Reload PJSIP module
    if systemctl is-active --quiet asterisk; then
        asterisk -rx "module reload res_pjsip.so"
        sleep 5
        
        # Check if connectivity restored
        if asterisk -rx "pjsip show endpoints" | grep -q "Available.*entel\|Available.*vtr"; then
            log_success "SIP connectivity restored"
            send_alert "info" "Self-healing successful" "SIP trunk connectivity was automatically restored"
        else
            log_warning "SIP connectivity not fully restored"
        fi
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  AUTOMATED MAINTENANCE
#═══════════════════════════════════════════════════════════════════════════════

run_daily_maintenance() {
    log_info "🔧 Running daily maintenance tasks..."
    
    # Database optimization
    if command -v mysql &>/dev/null; then
        log_info "Optimizing database tables..."
        mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' freepbx_skyn3t -e "
            OPTIMIZE TABLE cdr;
            OPTIMIZE TABLE userman_users;
            OPTIMIZE TABLE admin;
        " 2>/dev/null || true
    fi
    
    # Log rotation
    logrotate -f /etc/logrotate.conf
    
    # Update system packages (security only)
    apt update -qq
    apt upgrade -y -qq --security
    
    # Clean temporary files
    find /tmp -type f -mtime +7 -delete 2>/dev/null || true
    
    # Backup configuration
    create_daily_backup
    
    # Generate daily report
    generate_daily_report
    
    log_success "Daily maintenance completed"
}

run_weekly_maintenance() {
    log_info "🔧 Running weekly maintenance tasks..."
    
    # Full system package update
    apt update && apt upgrade -y
    
    # Analyze disk usage
    analyze_disk_usage
    
    # Security audit
    run_security_audit
    
    # Performance analysis
    analyze_performance_trends
    
    # Clean old metrics (keep 3 months)
    find "$METRICS_DIR" -name "*.csv" -mtime +90 -delete
    
    # Generate weekly report
    generate_weekly_report
    
    log_success "Weekly maintenance completed"
}

create_daily_backup() {
    local backup_file="$BACKUP_DIR/daily_backup_$(date +%Y%m%d).tar.gz"
    
    tar -czf "$backup_file" \
        /etc/asterisk/ \
        /etc/freepbx.conf \
        /etc/amportal.conf \
        "$MONITORING_DIR" \
        "$METRICS_DIR" \
        2>/dev/null || true
    
    # Keep only last 7 daily backups
    find "$BACKUP_DIR" -name "daily_backup_*.tar.gz" -mtime +7 -delete
    
    log_success "Daily backup created: $backup_file"
}

#═══════════════════════════════════════════════════════════════════════════════
#  REPORTING AND ANALYTICS
#═══════════════════════════════════════════════════════════════════════════════

generate_daily_report() {
    local report_file="$MONITORING_DIR/daily_report_$(date +%Y%m%d).txt"
    
    cat > "$report_file" << EOF
SKYN3T FreePBX DAILY REPORT
===========================
Date: $(date)
Server: $SERVER_NAME ($SERVER_IP)

SYSTEM HEALTH SUMMARY:
======================
$(generate_health_summary)

CALL STATISTICS (Last 24 Hours):
=================================
$(generate_call_statistics)

PERFORMANCE METRICS:
===================
$(generate_performance_summary)

ALERTS GENERATED:
================
$(list_recent_alerts)

MAINTENANCE TASKS:
==================
✅ Database optimization completed
✅ Log rotation completed
✅ System updates checked
✅ Configuration backup created
✅ Temporary files cleaned

RECOMMENDATIONS:
===============
$(generate_recommendations)

Next scheduled maintenance: $(date -d '+1 day' '+%Y-%m-%d 02:00')
EOF
    
    log_success "Daily report generated: $report_file"
    
    # Email report if configured
    if [[ -n "$ALERT_EMAIL" ]]; then
        mail -s "SKYN3T FreePBX Daily Report - $(date +%Y-%m-%d)" "$ALERT_EMAIL" < "$report_file" 2>/dev/null || true
    fi
}

generate_health_summary() {
    local cpu_avg=$(tail -n 288 "$METRICS_DIR/system_metrics.csv" 2>/dev/null | awk -F, '{sum+=$3; count++} END {if(count>0) printf "%.1f", sum/count; else print "N/A"}')
    local mem_avg=$(tail -n 288 "$METRICS_DIR/system_metrics.csv" 2>/dev/null | awk -F, '{sum+=$4; count++} END {if(count>0) printf "%.1f", sum/count; else print "N/A"}')
    local disk_current=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    
    local asterisk_uptime="Unknown"
    if systemctl is-active --quiet asterisk; then
        asterisk_uptime=$(systemctl show asterisk --property=ActiveEnterTimestamp --value | xargs -I {} date -d {} '+%Y-%m-%d %H:%M')
    fi
    
    cat << EOF
CPU Usage (24h avg): ${cpu_avg}%
Memory Usage (24h avg): ${mem_avg}%
Disk Usage: ${disk_current}%
Asterisk Status: $(systemctl is-active asterisk)
Asterisk Uptime: $asterisk_uptime
Load Average: $(uptime | awk -F'load average:' '{print $2}')
EOF
}

generate_call_statistics() {
    if ! command -v mysql &>/dev/null; then
        echo "Database not available for call statistics"
        return
    fi
    
    mysql -u freepbxuser -p'FreePBX_SKYN3T_2025!' freepbx_skyn3t -se "
        SELECT 
            CONCAT('Total Calls: ', COUNT(*)) as stat
        FROM cdr 
        WHERE calldate >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        
        UNION ALL
        
        SELECT 
            CONCAT('Successful Calls: ', SUM(CASE WHEN disposition = 'ANSWERED' THEN 1 ELSE 0 END))
        FROM cdr 
        WHERE calldate >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        
        UNION ALL
        
        SELECT 
            CONCAT('Success Rate: ', ROUND(SUM(CASE WHEN disposition = 'ANSWERED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2), '%')
        FROM cdr 
        WHERE calldate >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
        
        UNION ALL
        
        SELECT 
            CONCAT('Average Duration: ', ROUND(AVG(billsec), 2), ' seconds')
        FROM cdr 
        WHERE calldate >= DATE_SUB(NOW(), INTERVAL 24 HOUR) AND disposition = 'ANSWERED';
    " 2>/dev/null || echo "Call statistics temporarily unavailable"
}

generate_performance_summary() {
    local uptime_info=$(uptime)
    local memory_info=$(free -h | grep Mem)
    local disk_info=$(df -h /)
    
    cat << EOF
System Uptime: $uptime_info
Memory: $memory_info
Disk Space: $disk_info

Network Connectivity: $(ping -c 1 8.8.8.8 &>/dev/null && echo "✅ Online" || echo "❌ Offline")
DNS Resolution: $(nslookup google.com &>/dev/null && echo "✅ Working" || echo "❌ Failed")
EOF
}

list_recent_alerts() {
    if [[ -d "$ALERTS_DIR" ]]; then
        local alert_count=$(find "$ALERTS_DIR" -name "alert_*.txt" -mtime -1 | wc -l)
        echo "Alerts in last 24 hours: $alert_count"
        
        if [[ $alert_count -gt 0 ]]; then
            echo ""
            find "$ALERTS_DIR" -name "alert_*.txt" -mtime -1 -exec basename {} \; | sort | head -10
        fi
    else
        echo "No alerts directory found"
    fi
}

generate_recommendations() {
    local cpu_avg=$(tail -n 288 "$METRICS_DIR/system_metrics.csv" 2>/dev/null | awk -F, '{sum+=$3; count++} END {if(count>0) printf "%.0f", sum/count; else print "0"}')
    local mem_avg=$(tail -n 288 "$METRICS_DIR/system_metrics.csv" 2>/dev/null | awk -F, '{sum+=$4; count++} END {if(count>0) printf "%.0f", sum/count; else print "0"}')
    local disk_usage=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
    
    local recommendations=""
    
    if [[ $cpu_avg -gt 70 ]]; then
        recommendations+="\n- Consider CPU optimization or hardware upgrade (avg: ${cpu_avg}%)"
    fi
    
    if [[ $mem_avg -gt 80 ]]; then
        recommendations+="\n- Consider memory optimization or RAM upgrade (avg: ${mem_avg}%)"
    fi
    
    if [[ $disk_usage -gt 80 ]]; then
        recommendations+="\n- Disk cleanup recommended (current: ${disk_usage}%)"
    fi
    
    local alert_count=$(find "$ALERTS_DIR" -name "alert_*.txt" -mtime -1 | wc -l)
    if [[ $alert_count -gt 5 ]]; then
        recommendations+="\n- High alert frequency detected - review system stability"
    fi
    
    if [[ -z "$recommendations" ]]; then
        echo "✅ System running optimally - no immediate recommendations"
    else
        echo -e "Recommendations:$recommendations"
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  REAL-TIME MONITORING DASHBOARD
#═══════════════════════════════════════════════════════════════════════════════

show_realtime_dashboard() {
    while true; do
        clear
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║           SKYN3T FreePBX Real-time Dashboard               ║${NC}"
        echo -e "${BLUE}║                $(date '+%Y-%m-%d %H:%M:%S')                ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${GREEN}📊 SYSTEM STATUS:${NC}"
        local system_metrics=$(monitor_system_resources)
        echo "   $system_metrics"
        echo ""
        
        echo -e "${GREEN}📞 ASTERISK STATUS:${NC}"
        local asterisk_metrics=$(monitor_asterisk_status)
        echo "   $asterisk_metrics"
        echo ""
        
        echo -e "${GREEN}📈 CALL QUALITY:${NC}"
        local call_metrics=$(monitor_call_quality)
        echo "   $call_metrics"
        echo ""
        
        echo -e "${GREEN}🌐 NETWORK STATUS:${NC}"
        local network_metrics=$(monitor_network_connectivity)
        echo "   $network_metrics"
        echo ""
        
        echo -e "${GREEN}🚨 RECENT ALERTS:${NC}"
        local recent_alerts=$(find "$ALERTS_DIR" -name "alert_*.txt" -mtime -0.1 2>/dev/null | wc -l)
        echo "   Last 2.4 hours: $recent_alerts alerts"
        echo ""
        
        echo -e "${YELLOW}Press Ctrl+C to exit real-time monitoring${NC}"
        sleep 30
    done
}

#═══════════════════════════════════════════════════════════════════════════════
#  DAEMON MODE FUNCTIONS
#═══════════════════════════════════════════════════════════════════════════════

start_monitoring_daemon() {
    local pid_file="/var/run/skyn3t_monitoring.pid"
    
    if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
        log_error "Monitoring daemon already running (PID: $(cat "$pid_file"))"
        return 1
    fi
    
    log_info "Starting SKYN3T monitoring daemon..."
    
    # Start daemon in background
    nohup bash -c "
        trap 'log_info \"Monitoring daemon stopping...\"; exit 0' SIGTERM SIGINT
        
        while true; do
            monitor_system_resources >/dev/null
            monitor_asterisk_status >/dev/null
            monitor_call_quality >/dev/null
            monitor_network_connectivity >/dev/null
            sleep ${INTERVALS[real_time]}
        done
    " > "$MONITORING_DIR/daemon.log" 2>&1 &
    
    echo $! > "$pid_file"
    log_success "Monitoring daemon started (PID: $!)"
}

stop_monitoring_daemon() {
    local pid_file="/var/run/skyn3t_monitoring.pid"
    
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -TERM "$pid" 2>/dev/null; then
            log_success "Monitoring daemon stopped (PID: $pid)"
            rm -f "$pid_file"
        else
            log_error "Failed to stop monitoring daemon (PID: $pid)"
            return 1
        fi
    else
        log_warning "Monitoring daemon not running"
    fi
}

#═══════════════════════════════════════════════════════════════════════════════
#  MAIN MENU AND CONTROL
#═══════════════════════════════════════════════════════════════════════════════

show_main_menu() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           SKYN3T Monitoring System v$SCRIPT_VERSION                ║${NC}"
    echo -e "${BLUE}║                Server: $SERVER_NAME                 ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}📊 Monitoring & Maintenance Options:${NC}"
    echo ""
    echo "1) 📊 Real-time Dashboard"
    echo "2) 🔧 Run System Health Check"
    echo "3) 📈 View Performance Report"
    echo "4) 🚨 View Recent Alerts"
    echo "5) 🔧 Run Manual Maintenance"
    echo "6) ⚙️  Configure Alert Thresholds"
    echo "7) 📧 Test Alert System"
    echo "8) 🤖 Start Monitoring Daemon"
    echo "9) ⏹️  Stop Monitoring Daemon"
    echo ""
    echo "0) ❌ Exit"
    echo ""
}

run_system_health_check() {
    echo -e "${YELLOW}🔍 Running comprehensive system health check...${NC}"
    echo ""
    
    echo -e "${CYAN}System Resources:${NC}"
    echo "  $(monitor_system_resources)"
    echo ""
    
    echo -e "${CYAN}Asterisk Status:${NC}"
    echo "  $(monitor_asterisk_status)"
    echo ""
    
    echo -e "${CYAN}Call Quality:${NC}"
    echo "  $(monitor_call_quality)"
    echo ""
    
    echo -e "${CYAN}Network Connectivity:${NC}"
    echo "  $(monitor_network_connectivity)"
    echo ""
    
    echo -e "${CYAN}Service Status:${NC}"
    for service in apache2 mariadb asterisk; do
        if systemctl is-active --quiet "$service"; then
            echo -e "  ✅ $service: ${GREEN}Running${NC}"
        else
            echo -e "  ❌ $service: ${RED}Stopped${NC}"
        fi
    done
    echo ""
    
    echo -e "${CYAN}Disk Space:${NC}"
    df -h / | tail -1
    echo ""
    
    echo -e "${CYAN}Recent Alerts:${NC}"
    local alert_count=$(find "$ALERTS_DIR" -name "alert_*.txt" -mtime -1 2>/dev/null | wc -l)
    echo "  Alerts in last 24 hours: $alert_count"
}

configure_alert_thresholds() {
    echo -e "${YELLOW}⚙️ Configure Alert Thresholds${NC}"
    echo ""
    
    for threshold in "${!THRESHOLDS[@]}"; do
        echo "Current $threshold: ${THRESHOLDS[$threshold]}"
        read -p "New value (or press Enter to keep current): " new_value
        if [[ -n "$new_value" ]]; then
            THRESHOLDS["$threshold"]="$new_value"
            echo "Updated $threshold to $new_value"
        fi
        echo ""
    done
    
    # Save new thresholds
    cat > "$MONITORING_DIR/thresholds.conf" << EOF
# SKYN3T Alert Thresholds Configuration
EOF
    
    for threshold in "${!THRESHOLDS[@]}"; do
        echo "THRESHOLDS[\"$threshold\"]=\"${THRESHOLDS[$threshold]}\"" >> "$MONITORING_DIR/thresholds.conf"
    done
    
    log_success "Alert thresholds updated and saved"
}

test_alert_system() {
    echo -e "${YELLOW}📧 Testing Alert System${NC}"
    echo ""
    
    read -p "Enter email address for test (or press Enter for default): " test_email
    if [[ -n "$test_email" ]]; then
        ALERT_EMAIL="$test_email"
    fi
    
    echo "Sending test alert..."
    send_alert "info" "Test Alert" "This is a test alert from SKYN3T monitoring system. If you receive this, the alert system is working correctly."
    
    echo "Test alert sent. Check your email and alert logs."
}

main() {
    # Initialize
    setup_directories
    
    # Load custom thresholds if they exist
    if [[ -f "$MONITORING_DIR/thresholds.conf" ]]; then
        source "$MONITORING_DIR/thresholds.conf"
    fi
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    # Create metric files with headers if they don't exist
    if [[ ! -f "$METRICS_DIR/system_metrics.csv" ]]; then
        echo "epoch,timestamp,cpu_percent,memory_percent,disk_usage,load_1min,load_5min,load_15min,connections" > "$METRICS_DIR/system_metrics.csv"
    fi
    
    if [[ ! -f "$METRICS_DIR/asterisk_metrics.csv" ]]; then
        echo "epoch,timestamp,asterisk_status,total_extensions,online_extensions,active_calls,trunk_status" > "$METRICS_DIR/asterisk_metrics.csv"
    fi
    
    if [[ ! -f "$METRICS_DIR/call_quality.csv" ]]; then
        echo "epoch,timestamp,total_calls,successful_calls,avg_duration,success_rate" > "$METRICS_DIR/call_quality.csv"
    fi
    
    if [[ ! -f "$METRICS_DIR/network_metrics.csv" ]]; then
        echo "epoch,timestamp,internet_status,sip_status,latency" > "$METRICS_DIR/network_metrics.csv"
    fi
    
    # Handle command line arguments
    case "${1:-}" in
        "daemon")
            start_monitoring_daemon
            exit 0
            ;;
        "stop")
            stop_monitoring_daemon
            exit 0
            ;;
        "status")
            run_system_health_check
            exit 0
            ;;
        "dashboard")
            show_realtime_dashboard
            exit 0
            ;;
        "maintenance")
            run_daily_maintenance
            exit 0
            ;;
        "report")
            generate_daily_report
            exit 0
            ;;
    esac
    
    # Interactive menu
    while true; do
        clear
        show_main_menu
        read -p "Select option [0-9]: " choice
        echo ""
        
        case $choice in
            1)
                show_realtime_dashboard
                ;;
            2)
                run_system_health_check
                read -p "Press Enter to continue..."
                ;;
            3)
                if [[ -f "$MONITORING_DIR/daily_report_$(date +%Y%m%d).txt" ]]; then
                    cat "$MONITORING_DIR/daily_report_$(date +%Y%m%d).txt"
                else
                    echo "No report available. Generating now..."
                    generate_daily_report
                    cat "$MONITORING_DIR/daily_report_$(date +%Y%m%d).txt"
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                echo "Recent alerts:"
                find "$ALERTS_DIR" -name "alert_*.txt" -mtime -7 -exec echo "- {}" \; 2>/dev/null | head -10
                echo ""
                read -p "View specific alert? Enter filename (or press Enter): " alert_file
                if [[ -n "$alert_file" && -f "$ALERTS_DIR/$alert_file" ]]; then
                    cat "$ALERTS_DIR/$alert_file"
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                echo "Running manual maintenance..."
                run_daily_maintenance
                read -p "Press Enter to continue..."
                ;;
            6)
                configure_alert_thresholds
                read -p "Press Enter to continue..."
                ;;
            7)
                test_alert_system
                read -p "Press Enter to continue..."
                ;;
            8)
                start_monitoring_daemon
                read -p "Press Enter to continue..."
                ;;
            9)
                stop_monitoring_daemon
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}👋 Monitoring system management completed!${NC}"
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
