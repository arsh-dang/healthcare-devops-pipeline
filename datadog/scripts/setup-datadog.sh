#!/bin/bash

# Datadog Setup Script for Healthcare Application
# This script configures Datadog dashboards, alerts, and monitoring using the Datadog API

set -e

# Configuration
DATADOG_API_KEY="${DATADOG_API_KEY}"
DATADOG_APP_KEY="${DATADOG_APP_KEY:-}"
DATADOG_SITE="datadoghq.com"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed. Please install curl."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not installed. Please install jq."
        exit 1
    fi
    
    log_success "All dependencies are available"
}

# Validate API key
validate_api_key() {
    log_info "Validating Datadog API key..."
    
    if [ -z "$DATADOG_API_KEY" ]; then
        log_error "DATADOG_API_KEY environment variable is not set"
        log_info "Please set your Datadog API key: export DATADOG_API_KEY='your-api-key'"
        exit 1
    fi
    
    # Test API key by making a simple request
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_test_response \
        -X GET "https://api.${DATADOG_SITE}/api/v1/validate" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}")
    
    if [ "$response" != "200" ]; then
        log_error "Invalid Datadog API key or API request failed (HTTP $response)"
        log_info "Please check your API key and try again"
        exit 1
    fi
    
    log_success "Datadog API key is valid"
}

# Create dashboard
create_dashboard() {
    log_info "Creating healthcare application dashboard..."
    
    local dashboard_file="${SCRIPT_DIR}/../dashboards/healthcare-dashboard.json"
    
    if [ ! -f "$dashboard_file" ]; then
        log_error "Dashboard file not found: $dashboard_file"
        exit 1
    fi
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_dashboard_response \
        -X POST "https://api.${DATADOG_SITE}/api/v1/dashboard" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d @"$dashboard_file")
    
    if [ "$response" = "200" ] || [ "$response" = "201" ]; then
        local dashboard_url=$(cat /tmp/datadog_dashboard_response | jq -r '.url')
        log_success "Dashboard created successfully"
        log_info "Dashboard URL: $dashboard_url"
    else
        log_error "Failed to create dashboard (HTTP $response)"
        cat /tmp/datadog_dashboard_response
        exit 1
    fi
}

# Create monitors (alerts)
create_monitors() {
    log_info "Creating healthcare application monitors..."
    
    local alerts_file="${SCRIPT_DIR}/../alerts/healthcare-alerts.json"
    
    if [ ! -f "$alerts_file" ]; then
        log_error "Alerts file not found: $alerts_file"
        exit 1
    fi
    
    # Read alerts from JSON file
    local alerts=$(cat "$alerts_file" | jq -c '.alerts[]')
    local success_count=0
    local total_count=0
    
    while IFS= read -r alert; do
        total_count=$((total_count + 1))
        
        local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_monitor_response \
            -X POST "https://api.${DATADOG_SITE}/api/v1/monitor" \
            -H "Content-Type: application/json" \
            -H "DD-API-KEY: ${DATADOG_API_KEY}" \
            -d "$alert")
        
        if [ "$response" = "200" ] || [ "$response" = "201" ]; then
            local monitor_name=$(echo "$alert" | jq -r '.name')
            success_count=$((success_count + 1))
            log_success "Monitor created: $monitor_name"
        else
            local monitor_name=$(echo "$alert" | jq -r '.name')
            log_error "Failed to create monitor: $monitor_name (HTTP $response)"
            cat /tmp/datadog_monitor_response
        fi
    done <<< "$alerts"
    
    log_info "Created $success_count out of $total_count monitors"
}

# Send sample metrics
send_sample_metrics() {
    log_info "Sending sample healthcare metrics to Datadog..."
    
    local timestamp=$(date +%s)
    
    # Sample metrics payload
    local metrics_payload=$(cat <<EOF
{
    "series": [
        {
            "metric": "healthcare.app.health",
            "points": [[$timestamp, 1]],
            "tags": ["env:staging", "service:healthcare-app", "component:overall"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.api.requests",
            "points": [[$timestamp, 150]],
            "tags": ["env:staging", "service:healthcare-app", "endpoint:all"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.api.errors",
            "points": [[$timestamp, 2]],
            "tags": ["env:staging", "service:healthcare-app", "endpoint:all"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.api.response_time",
            "points": [[$timestamp, 150.5]],
            "tags": ["env:staging", "service:healthcare-app", "endpoint:all"],
            "type": "gauge"
        },
        {
            "metric": "mongodb.connections.current",
            "points": [[$timestamp, 25]],
            "tags": ["env:staging", "service:healthcare-app", "component:database"],
            "type": "gauge"
        },
        {
            "metric": "mongodb.connections.available",
            "points": [[$timestamp, 975]],
            "tags": ["env:staging", "service:healthcare-app", "component:database"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.patients.active",
            "points": [[$timestamp, 1250]],
            "tags": ["env:staging", "service:healthcare-app", "component:business"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.sla.uptime",
            "points": [[$timestamp, 99.95]],
            "tags": ["env:staging", "service:healthcare-app", "component:business"],
            "type": "gauge"
        }
    ]
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_metrics_response \
        -X POST "https://api.${DATADOG_SITE}/api/v1/series" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d "$metrics_payload")
    
    if [ "$response" = "200" ] || [ "$response" = "202" ]; then
        log_success "Sample metrics sent successfully"
    else
        log_error "Failed to send sample metrics (HTTP $response)"
        cat /tmp/datadog_metrics_response
    fi
}

# Create service check
create_service_check() {
    log_info "Creating healthcare service check..."
    
    local service_check_payload=$(cat <<EOF
{
    "check": "healthcare.app.health",
    "host_name": "healthcare-staging",
    "status": 0,
    "timestamp": $(date +%s),
    "message": "Healthcare application is healthy",
    "tags": ["env:staging", "service:healthcare-app"]
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_service_check_response \
        -X POST "https://api.${DATADOG_SITE}/api/v1/check_run" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d "$service_check_payload")
    
    if [ "$response" = "200" ] || [ "$response" = "202" ]; then
        log_success "Service check created successfully"
    else
        log_error "Failed to create service check (HTTP $response)"
        cat /tmp/datadog_service_check_response
    fi
}

# Main setup function
main() {
    log_info "Starting Datadog setup for Healthcare Application..."
    
    check_dependencies
    validate_api_key
    create_dashboard
    create_monitors
    send_sample_metrics
    create_service_check
    
    log_success "Datadog setup completed successfully!"
    log_info "You can now view your dashboard and monitors in the Datadog UI"
    log_info "Dashboard URL: https://app.${DATADOG_SITE}/dashboards"
    log_info "Monitors URL: https://app.${DATADOG_SITE}/monitors"
}

# Cleanup function
cleanup() {
    rm -f /tmp/datadog_*_response
}

# Set up cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"
