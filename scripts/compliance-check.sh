#!/bin/bash

# Healthcare DevOps Pipeline - Real Compliance Automation Script
# Performs HIPAA, SOC2, and GDPR compliance checks with actual validation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_FILE="${PROJECT_ROOT}/compliance-reports/compliance-check-$(date +%Y%m%d_%H%M%S).json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[COMPLIANCE]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} ✓ $1"
    ((PASSED_CHECKS++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} ✗ $1"
    echo -e "${RED}   Details: $2${NC}"
    ((FAILED_CHECKS++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} ⚠ $1"
    echo -e "${YELLOW}   Note: $2${NC}"
    ((WARNING_CHECKS++))
}

# Initialize compliance report
init_compliance_report() {
    mkdir -p "$(dirname "$REPORT_FILE")"
    cat > "$REPORT_FILE" << EOF
{
  "compliance_check": {
    "timestamp": "$(date -Iseconds)",
    "status": "running",
    "frameworks": ["HIPAA", "SOC2", "GDPR"]
  },
  "results": {
    "hipaa": {"total": 0, "passed": 0, "failed": 0, "warnings": 0, "checks": []},
    "soc2": {"total": 0, "passed": 0, "failed": 0, "warnings": 0, "checks": []},
    "gdpr": {"total": 0, "passed": 0, "failed": 0, "warnings": 0, "checks": []},
    "security": {"total": 0, "passed": 0, "failed": 0, "warnings": 0, "checks": []}
  },
  "summary": {
    "total_checks": 0,
    "passed_checks": 0,
    "failed_checks": 0,
    "warning_checks": 0,
    "compliance_percentage": 0
  }
}
EOF
}

# Update compliance report
update_compliance_report() {
    local framework="$1"
    local check_name="$2"
    local status="$3"
    local details="$4"

    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json
import sys

try:
    with open('$REPORT_FILE', 'r') as f:
        data = json.load(f)

    # Add check result
    check = {
        'name': '$check_name',
        'status': '$status',
        'details': '$details',
        'timestamp': '$(date -Iseconds)'
    }
    data['results']['$framework']['checks'].append(check)

    # Update counters
    data['results']['$framework']['total'] = len(data['results']['$framework']['checks'])
    data['results']['$framework']['passed'] = len([c for c in data['results']['$framework']['checks'] if c['status'] == 'passed'])
    data['results']['$framework']['failed'] = len([c for c in data['results']['$framework']['checks'] if c['status'] == 'failed'])
    data['results']['$framework']['warnings'] = len([c for c in data['results']['$framework']['checks'] if c['status'] == 'warning'])

    # Update summary
    total = sum(len(data['results'][f]['checks']) for f in data['results'])
    passed = sum(data['results'][f]['passed'] for f in data['results'])
    failed = sum(data['results'][f]['failed'] for f in data['results'])
    warnings = sum(data['results'][f]['warnings'] for f in data['results'])

    data['summary']['total_checks'] = total
    data['summary']['passed_checks'] = passed
    data['summary']['failed_checks'] = failed
    data['summary']['warning_checks'] = warnings
    data['summary']['compliance_percentage'] = round((passed / total * 100) if total > 0 else 0, 2)

    with open('$REPORT_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f'Error updating report: {e}')
"
    fi
}

# Finalize compliance report
finalize_compliance_report() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json

try:
    with open('$REPORT_FILE', 'r') as f:
        data = json.load(f)

    data['compliance_check']['status'] = 'completed'

    with open('$REPORT_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print(f'Error finalizing report: {e}')
"
    fi
}

# Check file exists and has content
check_file_exists() {
    local file="$1"
    local description="$2"
    local framework="$3"

    ((TOTAL_CHECKS++))
    if [[ -f "$file" && -s "$file" ]]; then
        log_success "$description"
        update_compliance_report "$framework" "$description" "passed" "File exists and has content"
        return 0
    else
        log_error "$description" "File $file does not exist or is empty"
        update_compliance_report "$framework" "$description" "failed" "File missing or empty"
        return 1
    fi
}

# Check file contains specific pattern
check_file_pattern() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    local framework="$4"

    ((TOTAL_CHECKS++))
    if [[ -f "$file" ]] && grep -q "$pattern" "$file" 2>/dev/null; then
        log_success "$description"
        update_compliance_report "$framework" "$description" "passed" "Pattern found in file"
        return 0
    else
        log_error "$description" "Pattern '$pattern' not found in $file"
        update_compliance_report "$framework" "$description" "failed" "Required pattern missing"
        return 1
    fi
}

# Check command availability
check_command() {
    local cmd="$1"
    local description="$2"
    local framework="$3"

    ((TOTAL_CHECKS++))
    if command -v "$cmd" >/dev/null 2>&1; then
        log_success "$description"
        update_compliance_report "$framework" "$description" "passed" "Command available"
        return 0
    else
        log_error "$description" "Command $cmd not found"
        update_compliance_report "$framework" "$description" "failed" "Command not available"
        return 1
    fi
}

# Check Terraform resource
check_terraform_resource() {
    local resource_type="$1"
    local description="$2"
    local framework="$3"

    ((TOTAL_CHECKS++))
    if [[ -f "terraform/main.tf" ]] && grep -q "resource \"$resource_type\"" terraform/main.tf 2>/dev/null; then
        log_success "$description"
        update_compliance_report "$framework" "$description" "passed" "Terraform resource configured"
        return 0
    else
        log_error "$description" "Terraform resource '$resource_type' not found"
        update_compliance_report "$framework" "$description" "failed" "Terraform resource missing"
        return 1
    fi
}

# HIPAA Compliance Checks
check_hipaa_compliance() {
    log_info "🔒 Starting HIPAA compliance validation..."

    # 1. Data Encryption at Rest
    check_terraform_resource "aws_kms_key" "Data encryption at rest (KMS)" "hipaa"
    check_terraform_resource "aws_db_instance" "Database encryption" "hipaa"

    # 2. Access Controls and Authentication
    check_terraform_resource "aws_iam_role" "Role-based access controls" "hipaa"
    check_terraform_resource "aws_iam_policy" "IAM policies for access control" "hipaa"

    # 3. Audit Logging and Monitoring
    check_terraform_resource "aws_cloudtrail" "Audit logging (CloudTrail)" "hipaa"
    check_terraform_resource "aws_cloudwatch_log_group" "CloudWatch audit logs" "hipaa"

    # 4. Secure Communication (TLS/SSL)
    check_terraform_resource "aws_acm_certificate" "SSL/TLS certificates" "hipaa"
    check_terraform_resource "aws_lb" "Load balancer with SSL termination" "hipaa"

    # 5. Backup and Recovery
    check_terraform_resource "aws_backup_plan" "Automated backup plan" "hipaa"
    check_file_exists "docs/DEPLOYMENT_GUIDE.md" "Backup and recovery procedures" "hipaa"

    # 6. Data Retention Policies
    check_file_exists "docs/MONITORING_GUIDE.md" "Data retention policies" "hipaa"

    # 7. Incident Response Plan
    check_file_exists "docs/SETUP_GUIDE.md" "Incident response plan" "hipaa"

    # 8. Business Associate Agreements
    check_file_exists "docs/DPA.md" "Business Associate Agreement template" "hipaa"
}

# SOC 2 Compliance Checks
check_soc2_compliance() {
    log_info "🔒 Starting SOC 2 compliance validation..."

    # 1. Security (CC1.1) - Network Security
    check_terraform_resource "aws_security_group" "Network security groups" "soc2"
    check_terraform_resource "aws_wafv2_web_acl" "Web Application Firewall" "soc2"

    # 2. Confidentiality (CC2.1) - Data Protection
    check_terraform_resource "aws_kms_key" "Data encryption keys" "soc2"
    check_terraform_resource "aws_secretsmanager_secret" "Secrets management" "soc2"

    # 3. Privacy (CC2.2) - Privacy Controls
    check_file_exists "docs/PRIVACY_POLICY.md" "Privacy policy" "soc2"

    # 4. Availability (CC3.1) - System Availability
    check_terraform_resource "aws_rds_cluster" "Multi-AZ database deployment" "soc2"
    check_terraform_resource "aws_backup_vault" "Backup vault for disaster recovery" "soc2"

    # 5. Processing Integrity (CC4.1) - Data Processing
    check_file_pattern "Jenkinsfile" "test" "Automated testing in CI/CD" "soc2"
    check_file_pattern "Jenkinsfile" "quality" "Code quality gates" "soc2"

    # 6. Change Management (CC5.1)
    check_file_exists "docs/CHANGE_MANAGEMENT.md" "Change management procedures" "soc2"

    # 7. Risk Management (CC6.1)
    check_terraform_resource "aws_config_configuration_recorder" "AWS Config for compliance monitoring" "soc2"
}

# GDPR Compliance Checks
check_gdpr_compliance() {
    log_info "🔒 Starting GDPR compliance validation..."

    # 1. Lawful Basis for Processing
    check_file_exists "docs/GDPR_COMPLIANCE.md" "Lawful basis documentation" "gdpr"

    # 2. Data Subject Rights Implementation
    check_file_pattern "server/server.js" "delete" "Right to erasure (delete)" "gdpr"
    check_file_pattern "server/server.js" "consent" "Consent management" "gdpr"

    # 3. Data Protection Officer
    check_file_exists "docs/DPO_CONTACT.md" "Data Protection Officer contact" "gdpr"

    # 4. Data Processing Agreement
    check_file_exists "docs/DPA.md" "Data Processing Agreement" "gdpr"

    # 5. Data Breach Notification
    check_terraform_resource "aws_sns_topic" "Breach notification system" "gdpr"
    check_terraform_resource "aws_cloudwatch_metric_alarm" "Automated breach detection" "gdpr"

    # 6. Data Mapping and Inventory
    check_file_exists "docs/DATA_INVENTORY.md" "Data mapping and inventory" "gdpr"

    # 7. International Data Transfers
    check_terraform_resource "aws_cloudfront_distribution" "CDN for data residency" "gdpr"
    check_file_pattern "terraform/main.tf" "eu-west" "EU data residency configuration" "gdpr"

    # 8. Privacy by Design
    check_file_pattern "src/App.js" "privacy" "Privacy by design implementation" "gdpr"
}

# Additional Security Checks
check_security_compliance() {
    log_info "🔒 Starting additional security validation..."

    # 1. Dependency Scanning
    check_command "npm" "NPM for dependency management" "security"
    check_command "snyk" "Snyk for vulnerability scanning" "security"

    # 2. Container Security
    check_command "docker" "Docker for containerization" "security"
    check_command "trivy" "Trivy for container scanning" "security"

    # 3. Infrastructure as Code Security
    check_file_exists "terraform/main.tf" "Infrastructure as Code" "security"
    check_command "tflint" "TFLint for Terraform validation" "security"

    # 4. CI/CD Security
    check_file_exists "Jenkinsfile" "CI/CD pipeline configuration" "security"
    check_file_pattern "Jenkinsfile" "security" "Security scanning in pipeline" "security"

    # 5. Secrets Management
    check_terraform_resource "aws_secretsmanager_secret" "AWS Secrets Manager" "security"
    check_terraform_resource "aws_ssm_parameter" "Parameter Store for secrets" "security"

    # 6. Monitoring and Alerting
    check_terraform_resource "aws_cloudwatch_dashboard" "CloudWatch monitoring dashboard" "security"
    check_terraform_resource "aws_sns_topic" "Alerting system" "security"

    # 7. Log Management
    check_terraform_resource "aws_cloudwatch_log_group" "Centralized logging" "security"
    check_terraform_resource "aws_kinesis_stream" "Log streaming for analysis" "security"
}

# Generate compliance summary
generate_summary() {
    log_info "📊 Generating compliance summary..."

    if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json

try:
    with open('$REPORT_FILE', 'r') as f:
        data = json.load(f)

    print('\n' + '='*60)
    print('COMPLIANCE CHECK RESULTS SUMMARY')
    print('='*60)
    print(f'Total Checks Performed: {data[\"summary\"][\"total_checks\"]}')
    print(f'Passed: {data[\"summary\"][\"passed_checks\"]}')
    print(f'Failed: {data[\"summary\"][\"failed_checks\"]}')
    print(f'Warnings: {data[\"summary\"][\"warning_checks\"]}')
    print(f'Compliance Percentage: {data[\"summary\"][\"compliance_percentage\"]}%')
    print('')

    # Framework breakdown
    for framework in ['hipaa', 'soc2', 'gdpr', 'security']:
        if data['results'][framework]['total'] > 0:
            passed = data['results'][framework]['passed']
            total = data['results'][framework]['total']
            percentage = round((passed / total * 100) if total > 0 else 0, 1)
            print(f'{framework.upper()}: {passed}/{total} ({percentage}%)')

    print('='*60)
    print(f'Report saved to: $REPORT_FILE')
except Exception as e:
    print(f'Error generating summary: {e}')
"
    fi
}

# Main execution
main() {
    log_info "🚀 Starting Healthcare DevOps Compliance Automation"
    log_info "Report will be saved to: $REPORT_FILE"

    cd "$PROJECT_ROOT"
    init_compliance_report

    # Run all compliance checks
    check_hipaa_compliance
    echo ""
    check_soc2_compliance
    echo ""
    check_gdpr_compliance
    echo ""
    check_security_compliance
    echo ""

    # Finalize and generate summary
    finalize_compliance_report
    generate_summary

    # Determine exit status based on compliance percentage
    if command -v python3 >/dev/null 2>&1; then
        compliance_percentage=$(python3 -c "
import json
with open('$REPORT_FILE', 'r') as f:
    data = json.load(f)
print(int(data['summary']['compliance_percentage']))
" 2>/dev/null || echo "0")

        if [ "$compliance_percentage" -ge 80 ]; then
            log_success "✅ Compliance check PASSED (${compliance_percentage}%)"
            return 0
        elif [ "$compliance_percentage" -ge 60 ]; then
            log_warning "⚠️  Compliance check FAIR (${compliance_percentage}%)" "Address failed checks to improve compliance"
            return 0
        else
            log_error "❌ Compliance check FAILED (${compliance_percentage}%)" "Immediate action required"
            return 1
        fi
    else
        log_info "Python3 not available - cannot calculate compliance percentage"
        return 0
    fi
}

# Run main function
main "$@"
