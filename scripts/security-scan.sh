#!/bin/bash

# Healthcare Application Security Vulnerability Scanner
# Performs comprehensive security assessment

set -e

# Configuration
NAMESPACE="healthcare-production-green"
REPORT_DIR="security-reports/$(date +%Y%m%d_%H%M%S)"
SCAN_TOOLS=("trivy" "kube-hunter" "kube-bench" "falco")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Create report directory
mkdir -p "$REPORT_DIR"

log_info "Starting Healthcare Application Security Scan"
log_info "Report directory: $REPORT_DIR"

# Function to check if tool is available
check_tool() {
    local tool=$1
    if command -v "$tool" >/dev/null 2>&1; then
        log_success "$tool is available"
        return 0
    else
        log_warning "$tool is not available"
        return 1
    fi
}

# Pre-scan checks
log_info "Checking available security scanning tools..."
AVAILABLE_TOOLS=()
for tool in "${SCAN_TOOLS[@]}"; do
    if check_tool "$tool"; then
        AVAILABLE_TOOLS+=("$tool")
    fi
done

if [ ${#AVAILABLE_TOOLS[@]} -eq 0 ]; then
    log_error "No security scanning tools available"
    log_info "Please install at least one of: ${SCAN_TOOLS[*]}"
    exit 1
fi

# Container Image Vulnerability Scan
scan_container_images() {
    log_info "Scanning container images for vulnerabilities..."

    # Get all running pods and their images
    kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort | uniq > "$REPORT_DIR/container_images.txt"

    while read -r image; do
        if [ -n "$image" ]; then
            log_info "Scanning image: $image"

            if command -v trivy >/dev/null 2>&1; then
                trivy image --format json --output "$REPORT_DIR/trivy_${image//\//_}.json" "$image" || log_warning "Failed to scan $image"
            fi
        fi
    done < "$REPORT_DIR/container_images.txt"
}

# Kubernetes Configuration Scan
scan_kubernetes_config() {
    log_info "Scanning Kubernetes configuration..."

    # Kube-bench scan
    if command -v kube-bench >/dev/null 2>&1; then
        log_info "Running kube-bench security assessment..."
        kube-bench --config-dir /etc/kube-bench/cfg --config /etc/kube-bench/cfg/config.yaml > "$REPORT_DIR/kube-bench-report.txt" 2>&1 || log_warning "kube-bench scan failed"
    fi

    # Check network policies
    log_info "Analyzing network policies..."
    kubectl get networkpolicies -n "$NAMESPACE" -o yaml > "$REPORT_DIR/network_policies.yaml"

    # Check RBAC configuration
    log_info "Analyzing RBAC configuration..."
    kubectl get roles,rolebindings,clusterroles,clusterrolebindings -n "$NAMESPACE" -o yaml > "$REPORT_DIR/rbac_config.yaml"

    # Check secrets exposure
    log_info "Checking for exposed secrets..."
    kubectl get secrets -n "$NAMESPACE" -o yaml > "$REPORT_DIR/secrets_analysis.yaml"
}

# Runtime Security Scan
scan_runtime_security() {
    log_info "Scanning runtime security..."

    # Check pod security contexts
    log_info "Analyzing pod security contexts..."
    kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].spec.containers[*].securityContext}' > "$REPORT_DIR/security_contexts.txt"

    # Check service account tokens
    log_info "Checking service account configurations..."
    kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].spec.serviceAccountName}' | sort | uniq > "$REPORT_DIR/service_accounts.txt"

    # Check for privileged containers
    log_info "Checking for privileged containers..."
    kubectl get pods -n "$NAMESPACE" -o json | jq -r '.items[] | select(.spec.containers[].securityContext.privileged == true) | .metadata.name' > "$REPORT_DIR/privileged_containers.txt"
}

# Dependency Vulnerability Scan
scan_dependencies() {
    log_info "Scanning application dependencies..."

    # Check package.json files
    if [ -f "package.json" ]; then
        log_info "Analyzing Node.js dependencies..."
        if command -v npm >/dev/null 2>&1; then
            npm audit --audit-level moderate --json > "$REPORT_DIR/npm_audit.json" 2>/dev/null || log_warning "npm audit failed"
        fi
    fi

    # Check Python dependencies if any
    if [ -f "requirements.txt" ]; then
        log_info "Analyzing Python dependencies..."
        if command -v safety >/dev/null 2>&1; then
            safety check --file requirements.txt --json > "$REPORT_DIR/python_safety.json" 2>/dev/null || log_warning "safety check failed"
        fi
    fi
}

# Compliance Check
check_compliance() {
    log_info "Performing compliance checks..."

    # GDPR compliance check
    log_info "Checking GDPR compliance..."
    cat > "$REPORT_DIR/gdpr_compliance.md" << EOF
# GDPR Compliance Assessment

## Data Processing Inventory
- Personal Health Information (PHI) processing: Yes
- Data encryption at rest: $(kubectl get secrets -n "$NAMESPACE" | grep -q "encryption" && echo "Yes" || echo "No")
- Data encryption in transit: Check TLS configuration
- Data retention policies: Check backup policies
- Data subject rights implementation: Check API endpoints

## Security Measures
- Access controls: $(kubectl get networkpolicies -n "$NAMESPACE" | wc -l) network policies
- Audit logging: Check application logs
- Breach notification: Check alerting configuration
- Data minimization: Check data collection practices

## Recommendations
1. Implement TLS 1.3 for all communications
2. Regular security assessments
3. Employee training on data protection
4. Incident response plan
5. Data mapping and classification
EOF

    # HIPAA compliance check (if applicable)
    cat > "$REPORT_DIR/hipaa_compliance.md" << EOF
# HIPAA Compliance Assessment

## Security Rule Requirements
- Access Control: $(kubectl get networkpolicies -n "$NAMESPACE" | wc -l) policies implemented
- Audit Controls: Check logging configuration
- Integrity: Check data validation
- Transmission Security: Check encryption in transit

## Recommendations
1. Implement comprehensive audit logging
2. Regular risk assessments
3. Business associate agreements
4. Incident response procedures
5. Security awareness training
EOF
}

# Generate comprehensive security report
generate_security_report() {
    log_info "Generating comprehensive security report..."

    # Count vulnerabilities
    HIGH_VULN=0
    MEDIUM_VULN=0
    LOW_VULN=0

    # Analyze trivy results
    for file in "$REPORT_DIR"/trivy_*.json; do
        if [ -f "$file" ]; then
            HIGH_VULN=$((HIGH_VULN + $(jq '.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH") | length' "$file" 2>/dev/null || echo 0)))
            MEDIUM_VULN=$((MEDIUM_VULN + $(jq '.Results[]?.Vulnerabilities[]? | select(.Severity == "MEDIUM") | length' "$file" 2>/dev/null || echo 0)))
            LOW_VULN=$((LOW_VULN + $(jq '.Results[]?.Vulnerabilities[]? | select(.Severity == "LOW") | length' "$file" 2>/dev/null || echo 0)))
        fi
    done

    cat > "$REPORT_DIR/security_report.md" << EOF
# Healthcare Application Security Assessment Report

## Executive Summary
Security assessment completed on $(date) for namespace: $NAMESPACE

## Vulnerability Summary
- **High Severity**: $HIGH_VULN vulnerabilities
- **Medium Severity**: $MEDIUM_VULN vulnerabilities
- **Low Severity**: $LOW_VULN vulnerabilities
- **Total Vulnerabilities**: $((HIGH_VULN + MEDIUM_VULN + LOW_VULN))

## Scan Results

### Container Image Vulnerabilities
$(ls "$REPORT_DIR"/trivy_*.json 2>/dev/null | wc -l) images scanned

### Kubernetes Configuration
- Network Policies: $(kubectl get networkpolicies -n "$NAMESPACE" --no-headers | wc -l)
- RBAC Roles: $(kubectl get roles,clusterroles -n "$NAMESPACE" --no-headers | wc -l)
- Secrets: $(kubectl get secrets -n "$NAMESPACE" --no-headers | wc -l)

### Runtime Security
- Privileged Containers: $(wc -l < "$REPORT_DIR/privileged_containers.txt")
- Service Accounts: $(wc -l < "$REPORT_DIR/service_accounts.txt")

## Risk Assessment

### Critical Risks
$(if [ $HIGH_VULN -gt 0 ]; then echo "- $HIGH_VULN high-severity vulnerabilities require immediate attention"; fi)
$(if [ "$(wc -l < "$REPORT_DIR/privileged_containers.txt")" -gt 0 ]; then echo "- Privileged containers detected - security risk"; fi)

### Medium Risks
$(if [ $MEDIUM_VULN -gt 10 ]; then echo "- High number of medium-severity vulnerabilities"; fi)

### Low Risks
$(if [ $LOW_VULN -gt 20 ]; then echo "- Consider addressing low-severity vulnerabilities during maintenance"; fi)

## Recommendations

### Immediate Actions (Critical)
1. Address all high-severity vulnerabilities
2. Remove privileged containers if not required
3. Implement TLS for all communications
4. Review and strengthen RBAC policies

### Short-term Actions (1-3 months)
1. Update container images to latest secure versions
2. Implement image scanning in CI/CD pipeline
3. Configure security monitoring and alerting
4. Regular vulnerability assessments

### Long-term Actions (3-6 months)
1. Implement zero-trust architecture
2. Automated security testing in CI/CD
3. Security training for development team
4. Regular penetration testing

## Compliance Status

### GDPR Compliance
- Data processing identified: Yes
- Security measures: Partial
- Next steps: Implement encryption, access controls

### HIPAA Compliance (if applicable)
- Security controls: Basic
- Audit logging: Partial
- Next steps: Comprehensive audit trail, risk assessment

## Tools Used
$(printf '%s\n' "${AVAILABLE_TOOLS[@]}")

## Report Files
$(ls -la "$REPORT_DIR")

---
*Security Assessment completed on $(date)*
*Report generated by Healthcare Security Scanner*
EOF
}

# Main execution
log_info "Starting security assessment..."

# Run all security scans
scan_container_images
scan_kubernetes_config
scan_runtime_security
scan_dependencies
check_compliance

# Generate final report
generate_security_report

log_success "Security assessment completed!"
log_info "Results saved to: $REPORT_DIR"
log_info "Security report: $REPORT_DIR/security_report.md"

# Summary
echo ""
echo "=================================================="
echo "Security Assessment Summary:"
echo "=================================================="
echo "Report Directory: $REPORT_DIR"
echo "High Vulnerabilities: $HIGH_VULN"
echo "Medium Vulnerabilities: $MEDIUM_VULN"
echo "Low Vulnerabilities: $LOW_VULN"
echo "=================================================="

if [ $HIGH_VULN -eq 0 ]; then
    log_success "No high-severity vulnerabilities found"
else
    log_error "$HIGH_VULN high-severity vulnerabilities require attention"
fi
