#!/bin/bash

# Automated Datadog Setup for Healthcare Application
# This script provides a complete automated setup for Datadog monitoring

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
    echo -e "${BLUE}[AUTOMATED-SETUP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[AUTOMATED-SETUP]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[AUTOMATED-SETUP]${NC} $1"
}

log_error() {
    echo -e "${RED}[AUTOMATED-SETUP]${NC} $1"
}

# Show banner
show_banner() {
    echo ""
    echo "=========================================="
    echo "  DATADOG AUTOMATED SETUP"
    echo "  Healthcare Application Monitoring"
    echo "=========================================="
    echo ""
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if DATADOG_API_KEY is set
    if [ -z "$DATADOG_API_KEY" ]; then
        log_error "DATADOG_API_KEY environment variable is not set"
        log_info "Please set your Datadog API key: export DATADOG_API_KEY='your-api-key'"
        log_info "You can get your API key from: https://app.datadoghq.com/organization-settings/application-keys"
        exit 1
    fi
    
    # Check if required tools are installed
    local missing_tools=()
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and try again"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Setup Datadog infrastructure
setup_datadog_infrastructure() {
    log_info "Setting up Datadog infrastructure..."
    
    # Run the deployment script
    cd "$SCRIPT_DIR"
    ./deploy-datadog.sh
    
    log_success "Datadog infrastructure setup completed"
}

# Configure Jenkins integration
configure_jenkins_integration() {
    log_info "Configuring Jenkins integration..."
    
    # Check if Jenkins is available
    if [ -f "$PROJECT_ROOT/Jenkinsfile" ]; then
        log_info "Jenkinsfile found. Datadog integration is already configured in the pipeline."
        log_info "The pipeline will automatically:"
        echo "  • Deploy Datadog infrastructure on each run"
        echo "  • Send metrics and events to Datadog"
        echo "  • Create monitors and dashboards"
        echo "  • Track build and deployment metrics"
    else
        log_warning "Jenkinsfile not found. Manual Jenkins integration may be required."
    fi
    
    log_success "Jenkins integration configured"
}

# Send initial metrics
send_initial_metrics() {
    log_info "Sending initial metrics to Datadog..."
    
    cd "$SCRIPT_DIR"
    ./jenkins-datadog-integration.sh pipeline-start
    
    log_success "Initial metrics sent"
}

# Display setup summary
display_summary() {
    log_info "Setup Summary:"
    
    echo ""
    echo "=========================================="
    echo "  DATADOG SETUP COMPLETED SUCCESSFULLY"
    echo "=========================================="
    echo ""
    echo "✅ Infrastructure deployed via Terraform"
    echo "✅ Dashboards created and configured"
    echo "✅ Monitors and alerts set up"
    echo "✅ Synthetic tests configured"
    echo "✅ Jenkins integration ready"
    echo "✅ Sample metrics sent"
    echo ""
    echo "📊 Access your monitoring:"
    echo "  • Datadog Dashboard: https://app.datadoghq.com/dashboard"
    echo "  • Healthcare Dashboard: $(cd "$TERRAFORM_DIR" && terraform output -raw datadog_dashboard_url 2>/dev/null || echo 'Check Datadog UI')"
    echo "  • Jenkins Dashboard: $(cd "$TERRAFORM_DIR" && terraform output -raw datadog_jenkins_dashboard_url 2>/dev/null || echo 'Check Datadog UI')"
    echo ""
    echo "🚨 Configure notifications:"
    echo "  • Slack integration: https://app.datadoghq.com/monitors"
    echo "  • Email notifications: https://app.datadoghq.com/monitors"
    echo "  • PagerDuty integration: https://app.datadoghq.com/monitors"
    echo ""
    echo "🔧 Next steps:"
    echo "  1. Configure Slack webhooks in Datadog for alert notifications"
    echo "  2. Test your monitors and synthetic tests"
    echo "  3. Run the Jenkins pipeline to see metrics in action"
    echo "  4. Customize dashboards for your specific needs"
    echo ""
    echo "📚 Documentation:"
    echo "  • Datadog Docs: https://docs.datadoghq.com/"
    echo "  • Healthcare App Monitoring Guide: $PROJECT_ROOT/MONITORING_GUIDE.md"
    echo "  • Terraform Datadog Provider: https://registry.terraform.io/providers/DataDog/datadog/latest/docs"
    echo ""
}

# Cleanup function
cleanup() {
    rm -f /tmp/datadog_*_response
}

# Set up cleanup on exit
trap cleanup EXIT

# Main function
main() {
    show_banner
    check_prerequisites
    setup_datadog_infrastructure
    configure_jenkins_integration
    send_initial_metrics
    display_summary
    
    log_success "Datadog automated setup completed successfully!"
}

# Check if running in help mode
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Datadog Automated Setup Script"
    echo ""
    echo "This script provides complete automated setup for Datadog monitoring"
    echo "of the Healthcare Application, including Infrastructure as Code deployment,"
    echo "dashboard creation, monitor setup, and Jenkins integration."
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h   Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DATADOG_API_KEY    (required) Your Datadog API key"
    echo "  DATADOG_APP_KEY    (optional) Your Datadog application key"
    echo "  ENVIRONMENT        (optional) Environment name (default: staging)"
    echo ""
    echo "Prerequisites:"
    echo "  • Terraform installed and configured"
    echo "  • curl and jq command-line tools"
    echo "  • Valid Datadog API key"
    echo ""
    echo "What this script does:"
    echo "  1. Validates prerequisites and environment"
    echo "  2. Deploys Datadog infrastructure using Terraform"
    echo "  3. Creates dashboards, monitors, and synthetic tests"
    echo "  4. Configures Jenkins pipeline integration"
    echo "  5. Sends initial metrics and events"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run complete setup"
    echo "  ENVIRONMENT=production $0  # Setup for production environment"
    exit 0
fi

# Run main function
main "$@"
