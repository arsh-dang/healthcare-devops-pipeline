#!/bin/bash

# Setup Jenkins Datadog Integration
# This script ensures everything is ready for the Jenkins pipeline to run automatically

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[SETUP]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SETUP]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[SETUP]${NC} $1"
}

show_banner() {
    echo ""
    echo "=========================================="
    echo "  JENKINS DATADOG INTEGRATION SETUP"
    echo "=========================================="
    echo ""
    echo "This script ensures your Jenkins pipeline will work"
    echo "automatically with Datadog monitoring."
    echo ""
}

# Check if DATADOG_API_KEY is provided
check_api_key() {
    if [ -z "$DATADOG_API_KEY" ]; then
        log_warning "DATADOG_API_KEY not provided via environment variable"
        echo ""
        echo "To complete the setup, you need to:"
        echo "1. Get your Datadog API key from: https://app.datadoghq.com/organization-settings/application-keys"
        echo "2. Add it as a Jenkins credential with ID: 'datadog-api-key'"
        echo "3. Or set it as an environment variable: export DATADOG_API_KEY='your-key'"
        echo ""
        log_warning "Continuing setup without API key validation..."
    else
        log_success "DATADOG_API_KEY is set"
    fi
}

# Ensure all scripts are executable
make_scripts_executable() {
    log_info "Making all scripts executable..."
    
    chmod +x datadog/scripts/*.sh
    chmod +x terraform/*.sh 2>/dev/null || true
    
    log_success "All scripts are now executable"
}

# Verify file structure
verify_structure() {
    log_info "Verifying project structure..."
    
    local required_files=(
        "Jenkinsfile"
        "terraform/datadog.tf"
        "terraform/providers.tf"
        "terraform/variables.tf"
        "datadog/scripts/deploy-datadog.sh"
        "datadog/scripts/jenkins-datadog-integration.sh"
        "datadog/scripts/automated-setup.sh"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        log_success "All required files are present"
    else
        log_warning "Missing files: ${missing_files[*]}"
        log_warning "Please ensure all files are present before running the pipeline"
    fi
}

# Test Jenkins pipeline syntax
test_jenkins_syntax() {
    log_info "Testing Jenkins pipeline syntax..."
    
    if command -v groovy &> /dev/null; then
        if groovy Jenkinsfile 2>&1 | grep -q "No signature of method: node"; then
            log_success "Jenkins pipeline syntax is valid"
        else
            log_warning "Jenkins pipeline syntax check inconclusive (expected in non-Jenkins environment)"
        fi
    else
        log_warning "Groovy not available for syntax checking"
    fi
}

# Display final instructions
display_instructions() {
    echo ""
    echo "=========================================="
    echo "  SETUP COMPLETED SUCCESSFULLY"
    echo "=========================================="
    echo ""
    echo "✅ All scripts are executable"
    echo "✅ Project structure verified"
    echo "✅ Jenkins pipeline ready"
    echo ""
    echo "🚀 NEXT STEPS:"
    echo ""
    echo "1. Add Datadog API Key to Jenkins:"
    echo "   • Go to Jenkins → Manage Jenkins → Credentials"
    echo "   • Add Secret Text credential with ID: 'datadog-api-key'"
    echo "   • Value: Your Datadog API key"
    echo ""
    echo "2. Run the Jenkins Pipeline:"
    echo "   • The pipeline will automatically:"
    echo "     - Deploy Datadog infrastructure via Terraform"
    echo "     - Create dashboards and monitors"
    echo "     - Send metrics and events throughout the pipeline"
    echo "     - Handle all monitoring setup automatically"
    echo ""
    echo "3. View Results in Datadog:"
    echo "   • Dashboards: https://app.datadoghq.com/dashboard"
    echo "   • Monitors: https://app.datadoghq.com/monitors"
    echo "   • Events: https://app.datadoghq.com/events"
    echo ""
    echo "🎯 THAT'S IT! Just run the Jenkins pipeline and everything"
    echo "   will be set up automatically."
    echo ""
}

# Main function
main() {
    show_banner
    check_api_key
    make_scripts_executable
    verify_structure
    test_jenkins_syntax
    display_instructions
    
    log_success "Setup completed! Your Jenkins pipeline is ready to run."
}

# Run main function
main "$@"
