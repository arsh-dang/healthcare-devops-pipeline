#!/bin/bash

# Healthcare DevOps - Resource Cleanup Script
# This script cleans up conflicting Kubernetes resources before Terraform deployment

set -e

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to clean up Jaeger resources
cleanup_jaeger_resources() {
    log "Cleaning up conflicting Jaeger resources..."
    
    # Delete Jaeger-related resources that might conflict
    kubectl delete serviceaccount jaeger-operator -n monitoring-staging --ignore-not-found=true || true
    kubectl delete clusterrole jaeger-operator --ignore-not-found=true || true
    kubectl delete clusterrolebinding jaeger-operator --ignore-not-found=true || true
    kubectl delete configmap jaeger-config -n monitoring-staging --ignore-not-found=true || true
    kubectl delete deployment jaeger -n monitoring-staging --ignore-not-found=true || true
    kubectl delete service jaeger -n monitoring-staging --ignore-not-found=true || true
    
    # Wait for resources to be deleted
    log "Waiting for Jaeger resources to be deleted..."
    sleep 10
    
    # Verify cleanup
    if kubectl get serviceaccount jaeger-operator -n monitoring-staging >/dev/null 2>&1; then
        log "WARNING: jaeger-operator serviceaccount still exists"
    else
        log "jaeger-operator serviceaccount cleaned up successfully"
    fi
    
    if kubectl get clusterrole jaeger-operator >/dev/null 2>&1; then
        log "WARNING: jaeger-operator clusterrole still exists"
    else
        log "jaeger-operator clusterrole cleaned up successfully"
    fi
}

# Function to clean up MongoDB StatefulSet if it's stuck
cleanup_mongodb_statefulset() {
    log "Checking MongoDB StatefulSet status..."
    
    # Check if StatefulSet exists and is stuck
    if kubectl get statefulset mongodb -n healthcare-staging >/dev/null 2>&1; then
        local rollout_status=$(kubectl rollout status statefulset/mongodb -n healthcare-staging --timeout=30s 2>/dev/null || echo "timeout")
        
        if [[ "$rollout_status" == *"timeout"* ]]; then
            log "MongoDB StatefulSet appears to be stuck, forcing rollout restart..."
            kubectl rollout restart statefulset/mongodb -n healthcare-staging || true
            sleep 30
        else
            log "MongoDB StatefulSet is healthy"
        fi
    else
        log "MongoDB StatefulSet does not exist"
    fi
}

# Function to clean up all resources (nuclear option)
cleanup_all_resources() {
    log "Performing complete resource cleanup..."
    
    # Delete namespaces (this will delete all resources within them)
    kubectl delete namespace healthcare-staging --ignore-not-found=true --timeout=60s || true
    kubectl delete namespace monitoring-staging --ignore-not-found=true --timeout=60s || true
    
    # Delete cluster-level resources
    kubectl delete clusterrole prometheus-staging --ignore-not-found=true || true
    kubectl delete clusterrolebinding prometheus-staging --ignore-not-found=true || true
    kubectl delete clusterrole jaeger-operator --ignore-not-found=true || true
    kubectl delete clusterrolebinding jaeger-operator --ignore-not-found=true || true
    
    # Wait for cleanup to complete
    log "Waiting for complete cleanup..."
    sleep 30
}

# Main cleanup function
main_cleanup() {
    local cleanup_type=${1:-jaeger}
    
    case "$cleanup_type" in
        jaeger)
            cleanup_jaeger_resources
            ;;
        mongodb)
            cleanup_mongodb_statefulset
            ;;
        all)
            cleanup_all_resources
            ;;
        *)
            echo "Usage: $0 {jaeger|mongodb|all}"
            echo "  jaeger: Clean up conflicting Jaeger resources"
            echo "  mongodb: Restart stuck MongoDB StatefulSet"
            echo "  all: Complete cleanup of all resources"
            exit 1
            ;;
    esac
    
    log "Cleanup completed successfully"
}

# Run main cleanup
main_cleanup "$@"
