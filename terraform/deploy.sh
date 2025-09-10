#!/bin/bash

# Healthcare DevOps - Terraform Deployment Script
# This script handles the deployment of infrastructure with proper error handling

set -e

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to handle existing resources
handle_existing_resources() {
    log "Checking for existing resources..."
    
    # Check if namespaces exist and import them if needed
    if kubectl get namespace healthcare-staging >/dev/null 2>&1; then
        log "Namespace healthcare-staging already exists, attempting to import..."
        terraform import -var="environment=staging" -var="app_version=${BUILD_NUMBER:-latest}" \
            -var="frontend_image=${FRONTEND_IMAGE:-healthcare-app-frontend:latest}" \
            -var="backend_image=${BACKEND_IMAGE:-healthcare-app-backend:latest}" \
            kubernetes_namespace.healthcare healthcare-staging || true
    fi
    
    if kubectl get namespace monitoring-staging >/dev/null 2>&1; then
        log "Namespace monitoring-staging already exists, attempting to import..."
        terraform import -var="environment=staging" -var="app_version=${BUILD_NUMBER:-latest}" \
            -var="frontend_image=${FRONTEND_IMAGE:-healthcare-app-frontend:latest}" \
            -var="backend_image=${BACKEND_IMAGE:-healthcare-app-backend:latest}" \
            kubernetes_namespace.monitoring monitoring-staging || true
    fi
    
    # Check if cluster role exists
    if kubectl get clusterrole prometheus-staging >/dev/null 2>&1; then
        log "ClusterRole prometheus-staging already exists, attempting to import..."
        terraform import -var="environment=staging" -var="app_version=${BUILD_NUMBER:-latest}" \
            -var="frontend_image=${FRONTEND_IMAGE:-healthcare-app-frontend:latest}" \
            -var="backend_image=${BACKEND_IMAGE:-healthcare-app-backend:latest}" \
            kubernetes_cluster_role.prometheus prometheus-staging || true
    fi
    
    # Check if Datadog Helm release exists
    if helm list -n healthcare-staging | grep -q datadog >/dev/null 2>&1; then
        log "Datadog Helm release already exists, attempting to import..."
        terraform import -var="environment=staging" -var="app_version=${BUILD_NUMBER:-latest}" \
            -var="frontend_image=${FRONTEND_IMAGE:-healthcare-app-frontend:latest}" \
            -var="backend_image=${BACKEND_IMAGE:-healthcare-app-backend:latest}" \
            -var="enable_datadog=true" \
            helm_release.datadog healthcare-staging/datadog || true
    fi
}

# Function to clean up existing resources if needed
cleanup_existing_resources() {
    log "Cleaning up existing conflicting resources..."
    
    # Delete resources that might conflict (optional)
    kubectl delete namespace healthcare-staging --ignore-not-found=true || true
    kubectl delete namespace monitoring-staging --ignore-not-found=true || true
    kubectl delete clusterrole prometheus-staging --ignore-not-found=true || true
    kubectl delete clusterrolebinding prometheus-staging --ignore-not-found=true || true
    
    # Clean up Datadog Helm release if it exists
    if helm list -n healthcare-staging | grep -q datadog >/dev/null 2>&1; then
        log "Removing existing Datadog Helm release..."
        helm uninstall datadog -n healthcare-staging || true
    fi
    
    # Wait a bit for cleanup to complete
    sleep 10
}

# Main deployment function
deploy_infrastructure() {
    local environment=${1:-staging}
    local app_version=${2:-${BUILD_NUMBER:-latest}}
    local frontend_image=${3:-healthcare-app-frontend:${app_version}}
    local backend_image=${4:-healthcare-app-backend:${app_version}}
    local datadog_api_key=${5:-${DATADOG_API_KEY:-""}}
    local enable_datadog=${6:-${ENABLE_DATADOG:-false}}
    
    log "Starting infrastructure deployment..."
    log "Environment: $environment"
    log "App Version: $app_version"
    log "Frontend Image: $frontend_image"
    log "Backend Image: $backend_image"
    log "Enable Datadog: $enable_datadog"
    
    # Change to terraform directory
    cd "$(dirname "$0")"
    
    # Initialize Terraform
    log "Initializing Terraform..."
    terraform init -upgrade
    
    # Handle existing resources strategy
    if [[ "${TERRAFORM_STRATEGY:-import}" == "clean" ]]; then
        log "Using clean strategy - removing existing resources..."
        cleanup_existing_resources
    else
        log "Using import strategy - importing existing resources..."
        handle_existing_resources
    fi
    
    # Build terraform plan command with optional Datadog variables
    local plan_cmd="terraform plan -var=\"environment=$environment\" -var=\"app_version=$app_version\" -var=\"frontend_image=$frontend_image\" -var=\"backend_image=$backend_image\""
    
    if [[ "$enable_datadog" == "true" && -n "$datadog_api_key" ]]; then
        plan_cmd="$plan_cmd -var=\"enable_datadog=true\" -var=\"datadog_api_key=$datadog_api_key\""
    fi
    
    plan_cmd="$plan_cmd -out=tfplan"
    
    # Plan the deployment
    log "Planning Terraform deployment..."
    eval "$plan_cmd"
    
    # Apply the deployment
    log "Applying Terraform configuration..."
    terraform apply -auto-approve tfplan
    
    # Cleanup plan file
    rm -f tfplan
    
    log "Infrastructure deployment completed successfully!"
    
    # Show deployment status
    log "Checking deployment status..."
    kubectl get pods -n healthcare-$environment || true
    kubectl get pods -n monitoring-$environment || true
    kubectl get services -n healthcare-$environment || true
    kubectl get services -n monitoring-$environment || true
}

# Error handling
trap 'log "Deployment failed with exit code $?"; exit 1' ERR

# Main execution
case "${1:-deploy}" in
    deploy)
        deploy_infrastructure "${2:-staging}" "${3:-${BUILD_NUMBER:-latest}}" \
            "${4:-healthcare-app-frontend:${BUILD_NUMBER:-latest}}" \
            "${5:-healthcare-app-backend:${BUILD_NUMBER:-latest}}" \
            "${6:-""}" "${7:-false}"
        ;;
    clean)
        log "Cleaning up all resources..."
        cleanup_existing_resources
        ;;
    import)
        log "Importing existing resources..."
        handle_existing_resources
        ;;
    *)
        echo "Usage: $0 {deploy|clean|import} [environment] [app_version] [frontend_image] [backend_image] [datadog_api_key] [enable_datadog]"
        echo "  deploy: Deploy infrastructure (default)"
        echo "  clean: Clean up existing resources"
        echo "  import: Import existing resources into Terraform state"
        echo ""
        echo "Parameters:"
        echo "  environment: Target environment (default: staging)"
        echo "  app_version: Application version/build number (default: BUILD_NUMBER or latest)"
        echo "  frontend_image: Frontend Docker image (default: healthcare-app-frontend:app_version)"
        echo "  backend_image: Backend Docker image (default: healthcare-app-backend:app_version)"
        echo "  datadog_api_key: Datadog API key (optional)"
        echo "  enable_datadog: Enable Datadog monitoring (true/false, default: false)"
        echo ""
        echo "Environment variables:"
        echo "  TERRAFORM_STRATEGY: 'import' (default) or 'clean'"
        echo "  BUILD_NUMBER: Build number for versioning"
        echo "  DATADOG_API_KEY: Alternative way to pass Datadog API key"
        echo "  ENABLE_DATADOG: Alternative way to enable Datadog (true/false)"
        exit 1
        ;;
esac
