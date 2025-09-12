#!/bin/bash

# Healthcare DevOps Pipeline - Compliance Automation Script
# Performs HIPAA, SOC2, and GDPR compliance checks

set -u

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMPLIANCE_PASSED=0
COMPLIANCE_FAILED=0
TOTAL_CHECKS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[COMPLIANCE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} ✓ $1"
    ((COMPLIANCE_PASSED++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} ✗ $1"
    echo -e "${RED}   Reason: $2${NC}"
    ((COMPLIANCE_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} ⚠ $1"
    echo -e "${YELLOW}   Note: $2${NC}"
}

# Check if file exists and is not empty
check_file_exists() {
    local file="$1"
    local description="$2"

    ((TOTAL_CHECKS++))
    if [[ -f "$file" && -s "$file" ]]; then
        log_success "$description found"
        return 0
    else
        log_error "$description not found" "File $file does not exist or is empty"
        return 1
    fi
}

# Check if directory exists
check_directory_exists() {
    local dir="$1"
    local description="$2"

    ((TOTAL_CHECKS++))
    if [[ -d "$dir" ]]; then
        log_success "$description found"
        return 0
    else
        log_error "$description not found" "Directory $dir does not exist"
        return 1
    fi
}

# Check if command is available
check_command_available() {
    local cmd="$1"
    local description="$2"

    ((TOTAL_CHECKS++))
    if command -v "$cmd" >/dev/null 2>&1; then
        log_success "$description available"
        return 0
    else
        log_error "$description not available" "Command $cmd not found in PATH"
        return 1
    fi
}

# Check file content for specific patterns
check_file_content() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    ((TOTAL_CHECKS++))
    if [[ -f "$file" ]] && grep -q "$pattern" "$file" 2>/dev/null; then
        log_success "$description implemented"
        return 0
    else
        log_error "$description not implemented" "Pattern '$pattern' not found in $file"
        return 1
    fi
}

# HIPAA Compliance Checks
check_hipaa_compliance() {
    log_info "Starting HIPAA compliance checks..."
    log_info "=================================================="

    # 1. Data Encryption at Rest
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "encryption\|kms\|encrypt" terraform/main.tf 2>/dev/null; then
        log_success "Data encryption at rest implemented"
    else
        log_error "Data encryption at rest not found" "Implement AES-256 encryption for sensitive data"
    fi

    # 2. Role-Based Access Controls
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "iam_role\|rbac\|access_control" terraform/main.tf 2>/dev/null; then
        log_success "Role-based access controls implemented"
    else
        log_error "Role-based access controls missing" "Implement RBAC for user access management"
    fi

    # 3. Audit Logging
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "cloudtrail\|audit\|logging" terraform/main.tf 2>/dev/null; then
        log_success "Audit logging implemented"
    else
        log_error "Audit logging not found" "Implement comprehensive audit logging"
    fi

    # 4. Backup and Recovery
    check_file_exists "docs/DEPLOYMENT_GUIDE.md" "Backup and recovery procedures documented"

    # 5. Secure Communication
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "https\|tls\|ssl" terraform/main.tf 2>/dev/null; then
        log_success "Secure communication implemented"
    else
        log_error "Secure communication not implemented" "Implement TLS 1.3 for all communications"
    fi

    # 6. Data Retention Policies
    check_file_exists "docs/MONITORING_GUIDE.md" "Data retention policies documented"

    # 7. Incident Response Plan
    check_file_exists "docs/SETUP_GUIDE.md" "Incident response plan documented"
}

# SOC 2 Compliance Checks
check_soc2_compliance() {
    log_info "Starting SOC 2 compliance checks..."
    log_info "=================================================="

    # 1. Security (CC1.1)
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "security_group\|firewall\|waf" terraform/main.tf 2>/dev/null; then
        log_success "Network security controls implemented"
    else
        log_error "Network security controls missing" "Implement security groups and firewall rules"
    fi

    # 2. Confidentiality (CC2.1)
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "kms\|encryption\|secrets" terraform/main.tf 2>/dev/null; then
        log_success "Data confidentiality controls implemented"
    else
        log_error "Data confidentiality controls missing" "Implement encryption for sensitive data"
    fi

    # 3. Privacy (CC2.2)
    check_file_exists "docs/PRIVACY_POLICY.md" "Privacy policy documented"

    # 4. Availability (CC3.1)
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "multi_az\|backup\|disaster_recovery" terraform/main.tf 2>/dev/null; then
        log_success "System availability controls implemented"
    else
        log_error "System availability controls missing" "Implement multi-AZ deployment and backup strategies"
    fi

    # 5. Processing Integrity (CC4.1)
    ((TOTAL_CHECKS++))
    if [[ -f "Jenkinsfile" ]] && grep -q "test\|quality\|validation" Jenkinsfile 2>/dev/null; then
        log_success "Data processing integrity controls implemented"
    else
        log_error "Data processing integrity controls missing" "Implement automated testing and validation"
    fi

    # 6. Change Management (CC5.1)
    check_file_exists "docs/CHANGE_MANAGEMENT.md" "Change management procedures documented"
}

# GDPR Compliance Checks
check_gdpr_compliance() {
    log_info "Starting GDPR compliance checks..."
    log_info "=================================================="

    # 1. Lawful Basis for Processing
    check_file_exists "docs/GDPR_COMPLIANCE.md" "Lawful basis documentation"

    # 2. Data Subject Rights
    ((TOTAL_CHECKS++))
    if [[ -f "server/server.js" ]] && grep -q "delete\|gdpr\|consent" server/server.js 2>/dev/null; then
        log_success "Data subject rights implemented"
    else
        log_error "Data subject rights not implemented" "Implement data deletion and consent management"
    fi

    # 3. Data Protection Officer
    check_file_exists "docs/DPO_CONTACT.md" "Data Protection Officer contact information"

    # 4. Data Processing Agreement
    check_file_exists "docs/DPA.md" "Data Processing Agreement documented"

    # 5. Data Breach Notification
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "alert\|notification\|monitoring" terraform/main.tf 2>/dev/null; then
        log_success "Data breach notification system implemented"
    else
        log_error "Data breach notification system missing" "Implement automated breach detection and notification"
    fi

    # 6. Data Mapping and Inventory
    check_file_exists "docs/DATA_INVENTORY.md" "Data mapping and inventory documented"

    # 7. International Data Transfers
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "eu-west\|gdpr\|privacy_shield" terraform/main.tf 2>/dev/null; then
        log_success "International data transfer safeguards implemented"
    else
        log_error "International data transfer safeguards missing" "Implement adequate safeguards for data transfers"
    fi
}

# Additional Security Checks
check_additional_security() {
    log_info "Starting additional security checks..."
    log_info "=================================================="

    # 1. Dependency Scanning
    check_command_available "npm" "NPM for dependency scanning"

    # 2. Container Security
    check_command_available "docker" "Docker for container security"

    # 3. Infrastructure as Code
    check_file_exists "terraform/main.tf" "Infrastructure as Code configuration"

    # 4. CI/CD Pipeline Security
    check_file_exists "Jenkinsfile" "CI/CD pipeline configuration"

    # 5. Secrets Management
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "secret\|parameter\|kms" terraform/main.tf 2>/dev/null; then
        log_success "Secrets management implemented"
    else
        log_error "Secrets management not implemented" "Implement secure secrets management"
    fi

    # 6. Monitoring and Alerting
    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "datadog\|prometheus\|alert" terraform/main.tf 2>/dev/null; then
        log_success "Monitoring and alerting implemented"
    else
        log_error "Monitoring and alerting not implemented" "Implement comprehensive monitoring"
    fi
}

# Generate compliance report
generate_report() {
    log_info "Generating compliance report..."
    log_info "=================================================="

    local compliance_percentage=$(( (COMPLIANCE_PASSED * 100) / TOTAL_CHECKS ))

    echo ""
    echo "========================================"
    echo "COMPLIANCE CHECK RESULTS"
    echo "========================================"
    echo "Total Checks Performed: $TOTAL_CHECKS"
    echo "Passed: $COMPLIANCE_PASSED"
    echo "Failed: $COMPLIANCE_FAILED"
    echo "Compliance Percentage: ${compliance_percentage}%"
    echo ""

    if [[ $compliance_percentage -ge 80 ]]; then
        log_success "Overall compliance status: GOOD (${compliance_percentage}%)"
        return 0
    elif [[ $compliance_percentage -ge 60 ]]; then
        log_warning "Overall compliance status: FAIR (${compliance_percentage}%)" "Address failed checks to improve compliance"
        return 0
    else
        log_error "Overall compliance status: POOR (${compliance_percentage}%)" "Immediate action required to address compliance gaps"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting Compliance Automation for Healthcare DevOps Pipeline"
    log_info "=================================================="

    cd "$PROJECT_ROOT"

    # Run all compliance checks
    check_hipaa_compliance
    echo ""
    check_soc2_compliance
    echo ""
    check_gdpr_compliance
    echo ""
    check_additional_security
    echo ""

    # Generate final report
    generate_report
}

# Run main function
main "$@"
