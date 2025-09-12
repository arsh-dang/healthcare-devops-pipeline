#!/bin/bash

# Healthcare DevOps - Terraform Deployment Script
# This script handles the deployment of infrastructure with proper error handling

set -e

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to handle state lock issues
handle_state_lock() {
    log "Checking for Terraform state lock..."
    
    # Try to unlock the state if it's locked
    if terraform force-unlock -lock=false 2>/dev/null; then
        log "Successfully unlocked Terraform state"
    else
        log "No state lock found or unable to unlock"
    fi
}

# Function to clean up existing resources if needed
cleanup_existing_resources() {
    log "Cleaning up existing conflicting resources..."
    
    # Use the cleanup script for thorough cleanup
    if [[ -f "./cleanup-resources.sh" ]]; then
        log "Using cleanup script for resource cleanup..."
        ./cleanup-resources.sh all
    else
        # Fallback to manual cleanup
        kubectl delete namespace healthcare-staging --ignore-not-found=true || true
        kubectl delete namespace monitoring-staging --ignore-not-found=true || true
        kubectl delete clusterrole prometheus-staging --ignore-not-found=true || true
        kubectl delete clusterrolebinding prometheus-staging --ignore-not-found=true || true
        sleep 10
    fi
}

# Main deployment function
deploy_infrastructure() {
    local environment=${1:-staging}
    local app_version=${2:-${BUILD_NUMBER:-latest}}
    local frontend_image=${3:-healthcare-app-frontend:${app_version}}
    local backend_image=${4:-healthcare-app-backend:${app_version}}
    
    log "Starting infrastructure deployment..."
    log "Environment: $environment"
    log "App Version: $app_version"
    log "Frontend Image: $frontend_image"
    log "Backend Image: $backend_image"
    
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
    
    # Handle state lock issues
    handle_state_lock
    
    # Plan the deployment
    log "Planning Terraform deployment..."
    terraform plan \
        -var="environment=$environment" \
        -var="app_version=$app_version" \
        -var="frontend_image=$frontend_image" \
        -var="backend_image=$backend_image" \
        -out=tfplan
    
    # Apply the deployment
    log "Applying Terraform configuration..."
    terraform apply -auto-approve -lock-timeout=10m tfplan
    
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
            "${5:-healthcare-app-backend:${BUILD_NUMBER:-latest}}"
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
        echo "Usage: $0 {deploy|clean|import} [environment] [app_version] [frontend_image] [backend_image]"
        echo "  deploy: Deploy infrastructure (default)"
        echo "  clean: Clean up existing resources"
        echo "  import: Import existing resources into Terraform state"
        echo ""
        echo "Environment variables:"
        echo "  TERRAFORM_STRATEGY: 'import' (default) or 'clean'"
        echo "  BUILD_NUMBER: Build number for versioning"
        exit 1
        ;;
esac
