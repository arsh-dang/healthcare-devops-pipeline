#!/bin/bash

# Smart PVC Handler for Healthcare App
# This script intelligently manages PVC lifecycle to prevent hanging issues

set -e

NAMESPACE="$1"
ENVIRONMENT="$2"
ENABLE_PERSISTENT="$3"

if [ -z "$NAMESPACE" ] || [ -z "$ENVIRONMENT" ] || [ -z "$ENABLE_PERSISTENT" ]; then
    echo "Usage: $0 <namespace> <environment> <enable_persistent_storage>"
    echo "Example: $0 monitoring-staging staging true"
    exit 1
fi

echo "🔍 Smart PVC Handler Starting..."
echo "   Namespace: $NAMESPACE"
echo "   Environment: $ENVIRONMENT"
echo "   Enable Persistent Storage: $ENABLE_PERSISTENT"

# Function to check if PVC exists and is healthy
check_pvc_health() {
    local pvc_name="$1"
    echo "   Checking PVC: $pvc_name"
    
    if kubectl get pvc "$pvc_name" -n "$NAMESPACE" >/dev/null 2>&1; then
        local status=$(kubectl get pvc "$pvc_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
        echo "   PVC $pvc_name status: $status"
        
        if [ "$status" = "Bound" ] || [ "$status" = "Pending" ]; then
            echo "   ✅ PVC $pvc_name is healthy"
            return 0
        else
            echo "   ⚠️ PVC $pvc_name is in unhealthy state: $status"
            return 1
        fi
    else
        echo "   ❌ PVC $pvc_name does not exist"
        return 1
    fi
}

# Function to safely delete PVC
safe_delete_pvc() {
    local pvc_name="$1"
    echo "   Attempting to delete PVC: $pvc_name"
    
    # First, try to delete any pods using this PVC
    echo "   Deleting pods using PVC $pvc_name..."
    kubectl delete pods -n "$NAMESPACE" --field-selector=spec.volumes[*].persistentVolumeClaim.claimName="$pvc_name" --force --grace-period=0 2>/dev/null || true
    
    # Wait a moment for pods to terminate
    sleep 10
    
    # Remove finalizers
    echo "   Removing finalizers from PVC $pvc_name..."
    kubectl patch pvc "$pvc_name" -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
    
    # Try to delete the PVC
    echo "   Deleting PVC $pvc_name..."
    kubectl delete pvc "$pvc_name" -n "$NAMESPACE" --force --grace-period=0 2>/dev/null || true
    
    # Wait for deletion with shorter timeout
    local attempts=0
    while kubectl get pvc "$pvc_name" -n "$NAMESPACE" >/dev/null 2>&1 && [ $attempts -lt 15 ]; do
        echo "   Waiting for PVC $pvc_name to be deleted... (attempt $((attempts+1))/15)"
        sleep 2
        attempts=$((attempts+1))
    done
    
    if kubectl get pvc "$pvc_name" -n "$NAMESPACE" >/dev/null 2>&1; then
        echo "   ⚠️ PVC $pvc_name still exists after deletion attempts - forcing removal"
        # Last resort: patch with empty finalizers again and force delete
        kubectl patch pvc "$pvc_name" -n "$NAMESPACE" --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
        kubectl delete pvc "$pvc_name" -n "$NAMESPACE" --force --grace-period=0 2>/dev/null || true
        return 1
    else
        echo "   ✅ PVC $pvc_name successfully deleted"
        return 0
    fi
}

# Main logic based on enable_persistent_storage setting
if [ "$ENABLE_PERSISTENT" = "true" ]; then
    echo "📦 Persistent storage is ENABLED"
    echo "   Strategy: Check existing PVCs, use if healthy, create if needed"
    
    # List of PVCs we manage
    PVCs=("alertmanager-storage" "prometheus-storage" "grafana-storage")
    
    for pvc in "${PVCs[@]}"; do
        if check_pvc_health "$pvc"; then
            echo "   ✅ Using existing healthy PVC: $pvc"
        else
            echo "   🔧 PVC $pvc needs to be created (will be handled by Terraform)"
        fi
    done
    
    echo "   📋 Terraform will create/update PVCs as needed"
    
elif [ "$ENABLE_PERSISTENT" = "false" ]; then
    echo "💾 Persistent storage is DISABLED"
    echo "   Strategy: Remove existing PVCs to prevent hanging, use emptyDir"
    
    # List of PVCs to potentially remove
    PVCs=("alertmanager-storage" "prometheus-storage" "grafana-storage")
    
    for pvc in "${PVCs[@]}"; do
        if kubectl get pvc "$pvc" -n "$NAMESPACE" >/dev/null 2>&1; then
            echo "   🗑️ Removing existing PVC: $pvc"
            safe_delete_pvc "$pvc"
        else
            echo "   ✅ PVC $pvc does not exist (no action needed)"
        fi
    done
    
    echo "   📋 Terraform will create emptyDir volumes instead"
    
else
    echo "❌ Invalid ENABLE_PERSISTENT value: $ENABLE_PERSISTENT"
    echo "   Must be 'true' or 'false'"
    exit 1
fi

echo "🎉 Smart PVC Handler completed successfully!"
echo "   Ready for Terraform deployment"
