#!/bin/bash

# Production Deployment Script with Blue-Green Strategy and Rollback
# This script implements enterprise-grade deployment practices

set -e

# Configuration
ENVIRONMENT=${1:-"production"}
APP_VERSION=${2:-"latest"}
FRONTEND_IMAGE=${3:-"healthcare-app-frontend:latest"}
BACKEND_IMAGE=${4:-"healthcare-app-backend:latest"}
ROLLBACK=${5:-"false"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Pre-deployment validation
validate_deployment() {
    log_info "Running pre-deployment validation..."

    # Check if images exist
    if ! docker images | grep -q "healthcare-app-frontend"; then
        log_error "Frontend Docker image not found"
        exit 1
    fi

    if ! docker images | grep -q "healthcare-app-backend"; then
        log_error "Backend Docker image not found"
        exit 1
    fi

    # Check Kubernetes connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    # Check if namespace exists
    if ! kubectl get namespace healthcare-${ENVIRONMENT} >/dev/null 2>&1; then
        log_error "Namespace healthcare-${ENVIRONMENT} does not exist"
        exit 1
    fi

    log_success "Pre-deployment validation passed"
}

# Load images into cluster
load_images() {
    log_info "Loading Docker images into Kubernetes cluster..."

    # Check if using k3s/colima
    if command -v colima >/dev/null 2>&1; then
        log_info "Using Colima/k3s - loading images..."

        # Load frontend image
        docker save ${FRONTEND_IMAGE} | colima ssh -- sudo /usr/bin/ctr -n k8s.io images import -

        # Load backend image
        docker save ${BACKEND_IMAGE} | colima ssh -- sudo /usr/bin/ctr -n k8s.io images import -

        log_success "Images loaded into k3s cluster"
    else
        log_warning "Colima not detected - assuming images are available in registry"
    fi
}

# Deploy to blue environment
deploy_blue() {
    log_info "Deploying to BLUE environment..."

    # Update blue deployment
    kubectl set image deployment/frontend-blue frontend=${FRONTEND_IMAGE} -n healthcare-${ENVIRONMENT}
    kubectl set image deployment/backend-blue backend=${BACKEND_IMAGE} -n healthcare-${ENVIRONMENT}

    # Wait for rollout
    log_info "Waiting for blue deployment rollout..."
    kubectl rollout status deployment/frontend-blue -n healthcare-${ENVIRONMENT} --timeout=300s
    kubectl rollout status deployment/backend-blue -n healthcare-${ENVIRONMENT} --timeout=300s

    log_success "Blue deployment completed"
}

# Deploy to green environment
deploy_green() {
    log_info "Deploying to GREEN environment..."

    # Update green deployment
    kubectl set image deployment/frontend-green frontend=${FRONTEND_IMAGE} -n healthcare-${ENVIRONMENT}
    kubectl set image deployment/backend-green backend=${BACKEND_IMAGE} -n healthcare-${ENVIRONMENT}

    # Wait for rollout
    log_info "Waiting for green deployment rollout..."
    kubectl rollout status deployment/frontend-green -n healthcare-${ENVIRONMENT} --timeout=300s
    kubectl rollout status deployment/backend-green -n healthcare-${ENVIRONMENT} --timeout=300s

    log_success "Green deployment completed"
}

# Health validation
validate_health() {
    local environment=$1
    log_info "Validating health of ${environment} environment..."

    # Wait for services to be ready
    sleep 30

    # Check frontend health
    if kubectl get pods -l app=frontend,environment=${environment} -n healthcare-${ENVIRONMENT} | grep -q Running; then
        log_success "Frontend pods are running in ${environment}"
    else
        log_error "Frontend pods not healthy in ${environment}"
        return 1
    fi

    # Check backend health
    if kubectl get pods -l app=backend,environment=${environment} -n healthcare-${ENVIRONMENT} | grep -q Running; then
        log_success "Backend pods are running in ${environment}"
    else
        log_error "Backend pods not healthy in ${environment}"
        return 1
    fi

    # Test health endpoints
    local frontend_port=$(kubectl get svc frontend-${environment} -n healthcare-${ENVIRONMENT} -o jsonpath='{.spec.ports[0].nodePort}')
    local backend_port=$(kubectl get svc backend-${environment} -n healthcare-${ENVIRONMENT} -o jsonpath='{.spec.ports[0].nodePort}')

    # Simple health check (assuming NodePort services)
    if curl -f http://localhost:${frontend_port}/ >/dev/null 2>&1; then
        log_success "Frontend health check passed for ${environment}"
    else
        log_error "Frontend health check failed for ${environment}"
        return 1
    fi

    if curl -f http://localhost:${backend_port}/health >/dev/null 2>&1; then
        log_success "Backend health check passed for ${environment}"
    else
        log_error "Backend health check failed for ${environment}"
        return 1
    fi

    log_success "${environment} environment health validation passed"
}

# Switch traffic between environments
switch_traffic() {
    local target=$1
    log_info "Switching traffic to ${target} environment..."

    # Update ingress/service selectors
    kubectl patch service frontend -n healthcare-${ENVIRONMENT} -p "{\"spec\":{\"selector\":{\"app\":\"frontend\",\"environment\":\"${target}\"}}}"
    kubectl patch service backend -n healthcare-${ENVIRONMENT} -p "{\"spec\":{\"selector\":{\"app\":\"backend\",\"environment\":\"${target}\"}}}"

    log_success "Traffic switched to ${target} environment"
}

# Rollback function
rollback() {
    local from_env=$1
    local to_env=$2
    log_warning "Initiating rollback from ${from_env} to ${to_env}..."

    # Switch traffic back
    switch_traffic ${to_env}

    # Scale down problematic environment
    kubectl scale deployment frontend-${from_env} --replicas=0 -n healthcare-${ENVIRONMENT}
    kubectl scale deployment backend-${from_env} --replicas=0 -n healthcare-${ENVIRONMENT}

    log_success "Rollback completed - traffic switched back to ${to_env}"
}

# Get current active environment
get_active_environment() {
    local frontend_selector=$(kubectl get service frontend -n healthcare-${ENVIRONMENT} -o jsonpath='{.spec.selector.environment}')
    echo ${frontend_selector}
}

# Main deployment function
main_deployment() {
    log_info "Starting production deployment..."
    log_info "Environment: ${ENVIRONMENT}"
    log_info "App Version: ${APP_VERSION}"
    log_info "Frontend Image: ${FRONTEND_IMAGE}"
    log_info "Backend Image: ${BACKEND_IMAGE}"

    # Pre-deployment validation
    validate_deployment

    # Load images
    load_images

    # Determine deployment strategy
    local active_env=$(get_active_environment)
    local target_env=""

    if [ "${active_env}" = "blue" ]; then
        target_env="green"
    else
        target_env="blue"
    fi

    log_info "Current active environment: ${active_env}"
    log_info "Target environment: ${target_env}"

    # Deploy to target environment
    if [ "${target_env}" = "blue" ]; then
        deploy_blue
    else
        deploy_green
    fi

    # Validate health
    if ! validate_health ${target_env}; then
        log_error "Health validation failed for ${target_env}"
        if [ "${ROLLBACK}" = "true" ]; then
            rollback ${target_env} ${active_env}
        fi
        exit 1
    fi

    # Switch traffic
    switch_traffic ${target_env}

    # Wait and validate final state
    sleep 10
    if validate_health ${target_env}; then
        log_success "Production deployment completed successfully!"
        log_success "Active environment: ${target_env}"

        # Scale down old environment
        if [ "${active_env}" = "blue" ]; then
            kubectl scale deployment frontend-blue --replicas=0 -n healthcare-${ENVIRONMENT}
            kubectl scale deployment backend-blue --replicas=0 -n healthcare-${ENVIRONMENT}
        else
            kubectl scale deployment frontend-green --replicas=0 -n healthcare-${ENVIRONMENT}
            kubectl scale deployment backend-green --replicas=0 -n healthcare-${ENVIRONMENT}
        fi

        log_success "Old environment scaled down"
    else
        log_error "Final validation failed"
        if [ "${ROLLBACK}" = "true" ]; then
            rollback ${target_env} ${active_env}
        fi
        exit 1
    fi
}

# Rollback-only mode
rollback_only() {
    local current_active=$(get_active_environment)
    local rollback_target=""

    if [ "${current_active}" = "blue" ]; then
        rollback_target="green"
    else
        rollback_target="blue"
    fi

    log_info "Rolling back to ${rollback_target} environment..."
    switch_traffic ${rollback_target}

    # Scale up target environment
    kubectl scale deployment frontend-${rollback_target} --replicas=2 -n healthcare-${ENVIRONMENT}
    kubectl scale deployment backend-${rollback_target} --replicas=3 -n healthcare-${ENVIRONMENT}

    # Scale down current environment
    kubectl scale deployment frontend-${current_active} --replicas=0 -n healthcare-${ENVIRONMENT}
    kubectl scale deployment backend-${current_active} --replicas=0 -n healthcare-${ENVIRONMENT}

    log_success "Rollback completed successfully"
}

# Main script logic
case "${ROLLBACK}" in
    "rollback-only")
        rollback_only
        ;;
    "true"|*)
        main_deployment
        ;;
esac
