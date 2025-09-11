#!/bin/bash

# Healthcare Application Monitoring Deployment Script
# This script deploys the complete monitoring stack through IaC

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${1:-staging}"
WORKSPACE_DIR="/Users/arshdang/Documents/SIT223/7.3HD/healthcare-app"
TERRAFORM_DIR="$WORKSPACE_DIR/terraform"

# Functions
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

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if tools are installed
    command -v terraform >/dev/null 2>&1 || { log_error "Terraform is not installed. Please install it first."; exit 1; }
    command -v kubectl >/dev/null 2>&1 || { log_error "kubectl is not installed. Please install it first."; exit 1; }
    command -v helm >/dev/null 2>&1 || { log_error "Helm is not installed. Please install it first."; exit 1; }

    # Check if terraform.tfvars exists
    if [ ! -f "$TERRAFORM_DIR/terraform.tfvars" ]; then
        log_warning "terraform.tfvars not found. Creating template..."
        cat > "$TERRAFORM_DIR/terraform.tfvars" << EOF
environment = "$ENVIRONMENT"
app_version = "1.0.0"
enable_datadog = true
enable_persistent_storage = true

# Datadog Configuration (REPLACE WITH YOUR VALUES)
datadog_api_key = "your-datadog-api-key"
datadog_app_key = "your-datadog-app-key"
datadog_rum_app_id = "your-rum-app-id"
datadog_rum_client_token = "your-rum-client-token"

# MongoDB Configuration
mongodb_root_password = "secure-password-change-me"
EOF
        log_warning "Please edit $TERRAFORM_DIR/terraform.tfvars with your actual values before proceeding."
        exit 1
    fi

    # Check Kubernetes connectivity
    kubectl cluster-info >/dev/null 2>&1 || { log_error "Cannot connect to Kubernetes cluster. Please configure kubectl."; exit 1; }

    log_success "Prerequisites check passed."
}

setup_helm_repos() {
    log_info "Setting up Helm repositories..."

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update >/dev/null 2>&1
    helm repo add grafana https://grafana.github.io/helm-charts --force-update >/dev/null 2>&1
    helm repo add datadog https://helm.datadoghq.com --force-update >/dev/null 2>&1
    helm repo update >/dev/null 2>&1

    log_success "Helm repositories configured."
}

deploy_monitoring() {
    log_info "Deploying monitoring stack to $ENVIRONMENT environment..."

    cd "$TERRAFORM_DIR"

    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init -upgrade >/dev/null 2>&1

    # Validate configuration
    log_info "Validating Terraform configuration..."
    terraform validate

    # Plan deployment
    log_info "Planning deployment..."
    terraform plan -out=tfplan -var="environment=$ENVIRONMENT"

    # Ask for confirmation
    echo
    log_warning "Ready to deploy monitoring stack. This will:"
    echo "  - Create monitoring namespace"
    echo "  - Deploy Prometheus, Grafana, Alertmanager"
    echo "  - Configure MongoDB exporter"
    echo "  - Set up Datadog integration"
    echo "  - Configure ingress and networking"
    echo
    read -p "Do you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deployment cancelled."
        exit 0
    fi

    # Apply configuration
    log_info "Applying Terraform configuration..."
    terraform apply tfplan

    log_success "Monitoring stack deployed successfully!"
}

verify_deployment() {
    log_info "Verifying deployment..."

    # Wait for components to be ready
    log_info "Waiting for monitoring components to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus-server -n monitoring-$ENVIRONMENT >/dev/null 2>&1 || log_warning "Prometheus deployment timeout"
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring-$ENVIRONMENT >/dev/null 2>&1 || log_warning "Grafana deployment timeout"
    kubectl wait --for=condition=available --timeout=300s deployment/alertmanager -n monitoring-$ENVIRONMENT >/dev/null 2>&1 || log_warning "Alertmanager deployment timeout"

    # Check pod status
    log_info "Checking pod status..."
    kubectl get pods -n monitoring-$ENVIRONMENT
    kubectl get pods -n healthcare-$ENVIRONMENT

    # Check services
    log_info "Checking services..."
    kubectl get services -n monitoring-$ENVIRONMENT
    kubectl get services -n healthcare-$ENVIRONMENT

    log_success "Deployment verification completed."
}

show_access_info() {
    echo
    log_success "🎉 Monitoring stack deployment completed!"
    echo
    log_info "Access Information:"
    echo "  Grafana: http://127.0.0.1:3000"
    echo "  Prometheus: http://127.0.0.1:9090"
    echo "  Alertmanager: http://127.0.0.1:9093"
    echo "  MongoDB Exporter: http://127.0.0.1:9216"
    echo
    log_info "Default Credentials:"
    echo "  Grafana: admin / admin (change immediately!)"
    echo
    log_info "Next Steps:"
    echo "  1. Update Grafana admin password"
    echo "  2. Configure alert notification channels"
    echo "  3. Review and customize dashboards"
    echo "  4. Set up monitoring alerts in your notification system"
    echo
    log_info "For detailed documentation, see: MONITORING_GUIDE.md"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    cd "$TERRAFORM_DIR"
    rm -f tfplan
}

# Main execution
main() {
    echo
    log_info "🚀 Healthcare Application Monitoring Deployment"
    log_info "Environment: $ENVIRONMENT"
    echo

    check_prerequisites
    setup_helm_repos
    deploy_monitoring
    verify_deployment
    show_access_info
    cleanup

    log_success "Deployment script completed successfully!"
}

# Run main function
main "$@"
