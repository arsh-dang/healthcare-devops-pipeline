#!/bin/bash

echo "🔒 PVC Protection Script"
echo "======================="
echo ""

# Function to check PVC protection
check_pvc_protection() {
    local pvc_name=$1
    local namespace=$2
    
    echo "🔍 Checking protection for $pvc_name..."
    
    # Check if PVC exists
    if ! kubectl get pvc $pvc_name -n $namespace >/dev/null 2>&1; then
        echo "❌ PVC $pvc_name not found"
        return 1
    fi
    
    # Check finalizers
    local finalizers=$(kubectl get pvc $pvc_name -n $namespace -o jsonpath='{.metadata.finalizers}' 2>/dev/null)
    if [[ $finalizers == *"kubernetes.io/pvc-protection"* ]]; then
        echo "✅ PVC protection finalizer is active"
    else
        echo "❌ PVC protection finalizer is missing"
        return 1
    fi
    
    # Check if PVC is in use
    local pods_using=$(kubectl get pods -n $namespace -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.volumes[*].persistentVolumeClaim.claimName}{"\n"}{end}' | grep $pvc_name | wc -l)
    if [ $pods_using -gt 0 ]; then
        echo "✅ PVC is in use by $pods_using pod(s)"
    else
        echo "⚠️ PVC is not currently in use"
    fi
    
    # Check protection labels
    local protection_label=$(kubectl get pvc $pvc_name -n $namespace -o jsonpath='{.metadata.labels.protected}' 2>/dev/null)
    if [ "$protection_label" = "true" ]; then
        echo "✅ Protection labels are set"
    else
        echo "⚠️ Protection labels are missing"
    fi
    
    echo ""
}

# Check all PVCs
echo "📋 Checking all PVCs in monitoring-staging namespace..."
echo ""

check_pvc_protection "alertmanager-storage" "monitoring-staging"
check_pvc_protection "grafana-storage" "monitoring-staging"
check_pvc_protection "prometheus-storage" "monitoring-staging"
check_pvc_protection "sonarqube-data" "monitoring-staging"

echo "✅ PVC protection check completed"
