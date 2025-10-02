#!/bin/bash

# Datadog Automated Deployment Script
# This script deploys Datadog monitoring infrastructure using Terraform

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
ENVIRONMENT="${ENVIRONMENT:-staging}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[DATADOG-DEPLOY]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[DATADOG-DEPLOY]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[DATADOG-DEPLOY]${NC} $1"
}

log_error() {
    echo -e "${RED}[DATADOG-DEPLOY]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is required but not installed. Please install Terraform."
        exit 1
    fi
    
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

# Validate environment variables
validate_environment() {
    log_info "Validating environment variables..."
    
    if [ -z "$DATADOG_API_KEY" ]; then
        log_error "DATADOG_API_KEY environment variable is not set"
        log_info "Please set your Datadog API key: export DATADOG_API_KEY='your-api-key'"
        exit 1
    fi
    
    if [ -z "$DATADOG_APP_KEY" ]; then
        log_warning "DATADOG_APP_KEY not set. Some features may not work properly."
        log_info "You can set it with: export DATADOG_APP_KEY='your-app-key'"
    fi
    
    log_success "Environment variables validated"
}

# Initialize Terraform
init_terraform() {
    log_info "Initializing Terraform for Datadog..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform with Datadog provider
    terraform init -upgrade
    
    log_success "Terraform initialized successfully"
}

# Plan Terraform deployment
plan_terraform() {
    log_info "Planning Datadog infrastructure deployment..."
    
    cd "$TERRAFORM_DIR"
    
    # Create plan
    terraform plan \
        -var="enable_datadog=true" \
        -var="datadog_api_key=${DATADOG_API_KEY}" \
        -var="datadog_app_key=${DATADOG_APP_KEY:-}" \
        -var="environment=${ENVIRONMENT}" \
        -out=datadog.tfplan
    
    log_success "Terraform plan created successfully"
    
    # Show plan summary
    log_info "Plan summary:"
    terraform show -no-color datadog.tfplan | grep -E "(Plan:|will be created|will be updated|will be destroyed)" || true
}

# Apply Terraform deployment
apply_terraform() {
    log_info "Applying Datadog infrastructure..."
    
    cd "$TERRAFORM_DIR"
    
    # Apply the plan
    terraform apply -auto-approve \
        -var="enable_datadog=true" \
        -var="datadog_api_key=${DATADOG_API_KEY}" \
        -var="datadog_app_key=${DATADOG_APP_KEY:-}" \
        -var="environment=${ENVIRONMENT}"
    
    log_success "Datadog infrastructure deployed successfully"
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
            "tags": ["env:${ENVIRONMENT}", "service:healthcare-app", "component:overall"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.api.requests",
            "points": [[$timestamp, 150]],
            "tags": ["env:${ENVIRONMENT}", "service:healthcare-app", "endpoint:all"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.api.errors",
            "points": [[$timestamp, 2]],
            "tags": ["env:${ENVIRONMENT}", "service:healthcare-app", "endpoint:all"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.api.response_time",
            "points": [[$timestamp, 150.5]],
            "tags": ["env:${ENVIRONMENT}", "service:healthcare-app", "endpoint:all"],
            "type": "gauge"
        },
        {
            "metric": "mongodb.connections.current",
            "points": [[$timestamp, 25]],
            "tags": ["env:${ENVIRONMENT}", "service:healthcare-app", "component:database"],
            "type": "gauge"
        },
        {
            "metric": "mongodb.connections.available",
            "points": [[$timestamp, 975]],
            "tags": ["env:${ENVIRONMENT}", "service:healthcare-app", "component:database"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.patients.active",
            "points": [[$timestamp, 1250]],
            "tags": ["env:${ENVIRONMENT}", "service:healthcare-app", "component:business"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.sla.uptime",
            "points": [[$timestamp, 99.95]],
            "tags": ["env:${ENVIRONMENT}", "service:healthcare-app", "component:business"],
            "type": "gauge"
        },
        {
            "metric": "healthcare.deployment.status",
            "points": [[$timestamp, 1]],
            "tags": ["env:${ENVIRONMENT}", "service:healthcare-app", "component:deployment"],
            "type": "gauge"
        }
    ]
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_sample_metrics_response \
        -X POST "https://api.us5.datadoghq.com/api/v1/series" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d "$metrics_payload")
    
    if [ "$response" = "200" ] || [ "$response" = "202" ]; then
        log_success "Sample metrics sent successfully"
    else
        log_error "Failed to send sample metrics (HTTP $response)"
        [ -f /tmp/datadog_sample_metrics_response ] && cat /tmp/datadog_sample_metrics_response
    fi
}

# Display deployment summary
display_summary() {
    log_info "Deployment Summary:"
    
    cd "$TERRAFORM_DIR"
    
    # Get outputs
    local dashboard_url=$(terraform output -raw datadog_dashboard_url 2>/dev/null || echo "N/A")
    local jenkins_dashboard_url=$(terraform output -raw datadog_jenkins_dashboard_url 2>/dev/null || echo "N/A")
    local monitors_count=$(terraform output -raw datadog_monitors_count 2>/dev/null || echo "0")
    local synthetic_tests_count=$(terraform output -raw datadog_synthetic_tests_count 2>/dev/null || echo "0")
    
    echo ""
    echo "=========================================="
    echo "  DATADOG DEPLOYMENT SUMMARY"
    echo "=========================================="
    echo "Environment: $ENVIRONMENT"
    echo "Dashboard URL: $dashboard_url"
    echo "Jenkins Dashboard URL: $jenkins_dashboard_url"
    echo "Monitors Created: $monitors_count"
    echo "Synthetic Tests Created: $synthetic_tests_count"
    echo "=========================================="
    echo ""
    
    log_info "Next Steps:"
    echo "1. Access your dashboards in the Datadog UI"
    echo "2. Configure Slack notifications in Datadog"
    echo "3. Test your monitors and synthetic tests"
    echo "4. Integrate with Jenkins pipeline using the jenkins-datadog-integration.sh script"
    echo ""
    
    log_info "Useful URLs:"
    echo "• Datadog Dashboard: https://app.datadoghq.com/dashboard"
    echo "• Datadog Monitors: https://app.datadoghq.com/monitors"
    echo "• Datadog Synthetics: https://app.datadoghq.com/synthetics"
    echo "• Healthcare Dashboard: $dashboard_url"
    echo "• Jenkins Dashboard: $jenkins_dashboard_url"
}

# Cleanup function
cleanup() {
    rm -f /tmp/datadog_*_response
    rm -f "$TERRAFORM_DIR/datadog.tfplan"
}

# Set up cleanup on exit
trap cleanup EXIT

# Main deployment function
main() {
    log_info "Starting Datadog automated deployment for Healthcare Application..."
    
    check_dependencies
    validate_environment
    init_terraform
    plan_terraform
    apply_terraform
    send_sample_metrics
    display_summary
    
    log_success "Datadog deployment completed successfully!"
}

# Check if running in dry-run mode
if [ "$1" = "--dry-run" ]; then
    log_info "Running in dry-run mode (plan only)..."
    check_dependencies
    validate_environment
    init_terraform
    plan_terraform
    log_info "Dry-run completed. Use './deploy-datadog.sh' to apply changes."
    exit 0
fi

# Check if running in help mode
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Datadog Automated Deployment Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be deployed without making changes"
    echo "  --help, -h   Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DATADOG_API_KEY    (required) Your Datadog API key"
    echo "  DATADOG_APP_KEY    (optional) Your Datadog application key"
    echo "  ENVIRONMENT        (optional) Environment name (default: staging)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy with current environment"
    echo "  $0 --dry-run         # Show deployment plan"
    echo "  ENVIRONMENT=production $0  # Deploy to production"
    exit 0
fi

# Run main function
main "$@"
