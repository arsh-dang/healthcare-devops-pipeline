#!/bin/bash

# Deployment Validation Script
# Validates that all components are working correctly

set -e

echo "🔍 Healthcare App Deployment Validation"
echo "========================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Validation functions
validate_docker() {
    echo "🐳 Validating Docker..."
    if docker ps &> /dev/null; then
        print_status "Docker is running"
        docker --version
    else
        print_error "Docker is not running"
        return 1
    fi
}

validate_kubernetes() {
    echo "⚙️  Validating Kubernetes..."
    if kubectl cluster-info &> /dev/null; then
        print_status "Kubernetes cluster is accessible"
        kubectl version --client --short
    else
        print_error "Kubernetes cluster is not accessible"
        return 1
    fi
}

validate_jenkins() {
    echo "🔧 Validating Jenkins..."
    if curl -s http://localhost:8080 > /dev/null; then
        print_status "Jenkins is running on http://localhost:8080"
    else
        print_warning "Jenkins is not running on http://localhost:8080"
        echo "Start Jenkins with: brew services start jenkins"
    fi
}

validate_sonarqube() {
    echo "📊 Validating SonarQube..."
    if curl -s http://localhost:9000/api/system/status | grep -q "UP"; then
        print_status "SonarQube is running on http://localhost:9000"
    else
        print_warning "SonarQube is not ready"
        echo "Start SonarQube with: docker run -d --name sonarqube -p 9000:9000 sonarqube:latest"
    fi
}

validate_application_build() {
    echo "🏗️  Validating Application Build..."
    if [ -f "package.json" ]; then
        if npm run build > /dev/null 2>&1; then
            print_status "Application builds successfully"
        else
            print_error "Application build failed"
            return 1
        fi
    else
        print_error "package.json not found"
        return 1
    fi
}

validate_kubernetes_deployment() {
    echo "🚀 Validating Kubernetes Deployment..."
    
    # Check if any healthcare app pods are running (Terraform-managed)
    if kubectl get pods -l app=healthcare-app 2>/dev/null | grep -q "Running"; then
        print_status "Healthcare app pods are running"
        kubectl get pods -l app=healthcare-app
    elif kubectl get pods -l managed-by=terraform 2>/dev/null | grep -q "Running"; then
        print_status "Terraform-managed healthcare app pods are running"
        kubectl get pods -l managed-by=terraform
    else
        print_warning "No healthcare app pods found"
        echo "Deploy with: cd terraform && terraform apply"
        echo "Or use: ./kubernetes/deploy.sh"
    fi
}

validate_monitoring() {
    echo "📊 Validating Monitoring..."
    
    # Check Prometheus
    if kubectl get svc prometheus-service 2>/dev/null | grep -q "prometheus"; then
        print_status "Prometheus service found"
    else
        print_warning "Prometheus service not found"
    fi
    
    # Check Grafana
    if kubectl get svc grafana 2>/dev/null | grep -q "grafana"; then
        print_status "Grafana service found"
    else
        print_warning "Grafana service not found"
    fi
}

test_api_endpoints() {
    echo "🧪 Testing API Endpoints..."
    
    # Test if backend is accessible
    BACKEND_URL="http://localhost:5000"
    if curl -s "${BACKEND_URL}/health" | grep -q "ok"; then
        print_status "Backend health endpoint is working"
    else
        print_warning "Backend health endpoint not accessible"
        echo "Try port forwarding: kubectl port-forward svc/backend 5000:5000"
    fi
}

validate_security_tools() {
    echo "🔒 Validating Security Tools..."
    
    tools=("trivy" "semgrep" "trufflehog")
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            print_status "$tool is installed"
        else
            print_warning "$tool is not installed (will be installed during pipeline)"
        fi
    done
}

validate_terraform() {
    echo "🏗️  Validating Terraform..."
    if [ -f "terraform/main.tf" ]; then
        cd terraform
        if terraform validate > /dev/null 2>&1; then
            print_status "Terraform configuration is valid"
        else
            print_error "Terraform configuration is invalid"
            terraform validate
            return 1
        fi
        cd ..
    else
        print_error "Terraform configuration not found"
        return 1
    fi
}

# Run all validations
echo "Starting comprehensive validation..."
echo ""

validation_results=()

validate_docker && validation_results+=("docker:pass") || validation_results+=("docker:fail")
validate_kubernetes && validation_results+=("k8s:pass") || validation_results+=("k8s:fail")
validate_jenkins && validation_results+=("jenkins:pass") || validation_results+=("jenkins:warn")
validate_sonarqube && validation_results+=("sonar:pass") || validation_results+=("sonar:warn")
validate_application_build && validation_results+=("build:pass") || validation_results+=("build:fail")
validate_kubernetes_deployment && validation_results+=("deploy:pass") || validation_results+=("deploy:warn")
validate_monitoring && validation_results+=("monitor:pass") || validation_results+=("monitor:warn")
test_api_endpoints && validation_results+=("api:pass") || validation_results+=("api:warn")
validate_security_tools && validation_results+=("security:pass") || validation_results+=("security:warn")
validate_terraform && validation_results+=("terraform:pass") || validation_results+=("terraform:fail")

echo ""
echo "📋 Validation Summary"
echo "===================="

passed=0
failed=0
warnings=0

for result in "${validation_results[@]}"; do
    IFS=':' read -r component status <<< "$result"
    case $status in
        "pass")
            echo -e "${GREEN}✅ $component${NC}"
            ((passed++))
            ;;
        "fail")
            echo -e "${RED}❌ $component${NC}"
            ((failed++))
            ;;
        "warn")
            echo -e "${YELLOW}⚠️  $component${NC}"
            ((warnings++))
            ;;
    esac
done

echo ""
echo "Results: $passed passed, $failed failed, $warnings warnings"

if [ $failed -eq 0 ]; then
    print_status "Validation completed successfully!"
    echo ""
    echo "🎯 Ready for pipeline execution!"
    echo "Next steps:"
    echo "1. Configure Jenkins credentials"
    echo "2. Create Jenkins pipeline job"
    echo "3. Run the pipeline"
    echo "4. Record demo video"
else
    print_error "Validation failed. Please fix the issues above before proceeding."
    exit 1
fi
