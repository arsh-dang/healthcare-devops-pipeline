#!/bin/bash

# Green Environment Health Check Script
# This script validates the green environment deployment and ensures all services are healthy

set -e

NAMESPACE="healthcare-production-green"
MONITORING_NAMESPACE="monitoring-production"

echo "🌿 Green Environment Health Check"
echo "================================="

# Function to check if namespace exists
check_namespace() {
    local namespace=$1
    echo "Checking namespace: $namespace"
    
    if kubectl get namespace "$namespace" >/dev/null 2>&1; then
        echo "✅ Namespace $namespace exists"
        return 0
    else
        echo "❌ Namespace $namespace not found"
        return 1
    fi
}

# Function to check pod health
check_pod_health() {
    local namespace=$1
    local label_selector=$2
    local expected_count=${3:-1}
    
    echo "Checking pods in namespace: $namespace with selector: $label_selector"
    
    local pod_count=$(kubectl get pods -n "$namespace" -l "$label_selector" --no-headers | grep -c "Running" || echo "0")
    
    if [ "$pod_count" -ge "$expected_count" ]; then
        echo "✅ Found $pod_count running pods (expected: $expected_count)"
        return 0
    else
        echo "❌ Found $pod_count running pods (expected: $expected_count)"
        return 1
    fi
}

# Function to check service health
check_service_health() {
    local namespace=$1
    local service_name=$2
    local port=$3
    
    echo "Checking service: $service_name in namespace: $namespace"
    
    if kubectl get service "$service_name" -n "$namespace" >/dev/null 2>&1; then
        echo "✅ Service $service_name exists"
        
        # Test service connectivity
        if kubectl port-forward -n "$namespace" "service/$service_name" "$((port + 10000)):$port" >/dev/null 2>&1 &
        then
            local pf_pid=$!
            sleep 2
            
            if curl -s -f "http://localhost:$((port + 10000))" >/dev/null 2>&1; then
                echo "✅ Service $service_name is responding on port $port"
                kill $pf_pid 2>/dev/null || true
                return 0
            else
                echo "❌ Service $service_name is not responding on port $port"
                kill $pf_pid 2>/dev/null || true
                return 1
            fi
        else
            echo "⚠️  Could not port-forward to service $service_name"
            return 1
        fi
    else
        echo "❌ Service $service_name not found"
        return 1
    fi
}

# Function to check ingress health
check_ingress_health() {
    local namespace=$1
    local ingress_name=$2
    
    echo "Checking ingress: $ingress_name in namespace: $namespace"
    
    if kubectl get ingress "$ingress_name" -n "$namespace" >/dev/null 2>&1; then
        echo "✅ Ingress $ingress_name exists"
        
        # Check if ingress has an address (LoadBalancer or NodePort)
        local ingress_address=$(kubectl get ingress "$ingress_name" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [ -n "$ingress_address" ]; then
            echo "✅ Ingress $ingress_name has address: $ingress_address"
            return 0
        else
            echo "⚠️  Ingress $ingress_name has no external address"
            return 1
        fi
    else
        echo "❌ Ingress $ingress_name not found"
        return 1
    fi
}

# Function to check database connectivity
check_database_health() {
    local namespace=$1
    
    echo "Checking database connectivity in namespace: $namespace"
    
    # Check MongoDB StatefulSet
    if kubectl get statefulset mongodb -n "$namespace" >/dev/null 2>&1; then
        local ready_replicas=$(kubectl get statefulset mongodb -n "$namespace" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired_replicas=$(kubectl get statefulset mongodb -n "$namespace" -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        if [ "$ready_replicas" -eq "$desired_replicas" ] && [ "$desired_replicas" -gt "0" ]; then
            echo "✅ MongoDB StatefulSet is ready ($ready_replicas/$desired_replicas)"
            return 0
        else
            echo "❌ MongoDB StatefulSet is not ready ($ready_replicas/$desired_replicas)"
            return 1
        fi
    else
        echo "❌ MongoDB StatefulSet not found"
        return 1
    fi
}

# Main health check function
run_green_environment_health_check() {
    echo "Starting Green Environment Health Check..."
    echo "Target namespace: $NAMESPACE"
    echo "Monitoring namespace: $MONITORING_NAMESPACE"
    echo ""
    
    local failed_checks=0
    
    # Check namespaces
    if ! check_namespace "$NAMESPACE"; then
        ((failed_checks++))
    fi
    
    if ! check_namespace "$MONITORING_NAMESPACE"; then
        ((failed_checks++))
    fi
    
    echo ""
    
    # Check application pods
    echo "=== Application Health Checks ==="
    if ! check_pod_health "$NAMESPACE" "app=healthcare-app,component=frontend" 1; then
        ((failed_checks++))
    fi
    
    if ! check_pod_health "$NAMESPACE" "app=healthcare-app,component=mongodb" 1; then
        ((failed_checks++))
    fi
    
    echo ""
    
    # Check services
    echo "=== Service Health Checks ==="
    if ! check_service_health "$NAMESPACE" "frontend" 80; then
        ((failed_checks++))
    fi
    
    if ! check_service_health "$NAMESPACE" "backend" 5001; then
        ((failed_checks++))
    fi
    
    echo ""
    
    # Check ingress
    echo "=== Ingress Health Checks ==="
    if ! check_ingress_health "$NAMESPACE" "frontend-ingress"; then
        ((failed_checks++))
    fi
    
    if ! check_ingress_health "$NAMESPACE" "backend-ingress"; then
        ((failed_checks++))
    fi
    
    echo ""
    
    # Check database
    echo "=== Database Health Checks ==="
    if ! check_database_health "$NAMESPACE"; then
        ((failed_checks++))
    fi
    
    echo ""
    
    # Check monitoring services
    echo "=== Monitoring Health Checks ==="
    if ! check_pod_health "$MONITORING_NAMESPACE" "app.kubernetes.io/name=grafana" 1; then
        ((failed_checks++))
    fi
    
    if ! check_pod_health "$MONITORING_NAMESPACE" "app.kubernetes.io/name=prometheus" 1; then
        ((failed_checks++))
    fi
    
    if ! check_service_health "$MONITORING_NAMESPACE" "grafana" 3000; then
        ((failed_checks++))
    fi
    
    if ! check_service_health "$MONITORING_NAMESPACE" "prometheus" 9090; then
        ((failed_checks++))
    fi
    
    echo ""
    echo "================================="
    
    if [ $failed_checks -eq 0 ]; then
        echo "🎉 Green Environment Health Check: PASSED"
        echo "All services are healthy and ready for production traffic"
        exit 0
    else
        echo "❌ Green Environment Health Check: FAILED"
        echo "Failed checks: $failed_checks"
        echo "Please review the issues above before switching traffic"
        exit 1
    fi
}

# Run the health check
run_green_environment_health_check "$@"
