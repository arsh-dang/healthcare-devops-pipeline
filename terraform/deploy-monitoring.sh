#!/bin/bash

# Healthcare Application Monitoring Enhancements Deployment Script
# This script helps deploy and validate the monitoring enhancements

set -e

# Configuration
ENVIRONMENT=${1:-"staging"}
NAMESPACE="healthcare-${ENVIRONMENT}"
MONITORING_NAMESPACE="monitoring-${ENVIRONMENT}"

echo "🚀 Deploying Monitoring Enhancements for ${ENVIRONMENT} environment"
echo "============================================================"

# Function to check if a resource exists
resource_exists() {
    local resource_type=$1
    local resource_name=$2
    local namespace=$3

    kubectl get "${resource_type}" "${resource_name}" -n "${namespace}" >/dev/null 2>&1
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment_name=$1
    local namespace=$2
    local timeout=${3:-300}

    echo "⏳ Waiting for ${deployment_name} to be ready..."
    kubectl wait --for=condition=available --timeout="${timeout}s" deployment/"${deployment_name}" -n "${namespace}"
    echo "✅ ${deployment_name} is ready"
}

# Function to validate service endpoints
validate_service() {
    local service_name=$1
    local namespace=$2
    local port=$3

    echo "🔍 Validating ${service_name} service..."
    local service_url="${service_name}.${namespace}.svc.cluster.local:${port}"

    # Try to connect to the service
    if timeout 10 bash -c "echo > /dev/tcp/${service_name}.${namespace}.svc.cluster.local/${port}" 2>/dev/null; then
        echo "✅ ${service_name} service is accessible on port ${port}"
    else
        echo "❌ ${service_name} service is not accessible on port ${port}"
        return 1
    fi
}

# Check if monitoring namespace exists
echo "📋 Checking monitoring namespace..."
if ! resource_exists namespace "${MONITORING_NAMESPACE}"; then
    echo "❌ Monitoring namespace ${MONITORING_NAMESPACE} does not exist"
    echo "Please run Terraform apply first to create the monitoring infrastructure"
    exit 1
fi
echo "✅ Monitoring namespace exists"

# Check core monitoring components
echo ""
echo "📊 Checking core monitoring components..."

COMPONENTS=(
    "prometheus:deployment"
    "grafana:deployment"
    "alertmanager:deployment"
    "mongodb-exporter:deployment"
    "node-exporter:daemonset"
)

for component in "${COMPONENTS[@]}"; do
    IFS=':' read -r name type <<< "${component}"
    if resource_exists "${type}" "${name}" "${MONITORING_NAMESPACE}"; then
        echo "✅ ${name} ${type} exists"
        if [ "${type}" = "deployment" ]; then
            wait_for_deployment "${name}" "${MONITORING_NAMESPACE}"
        fi
    else
        echo "❌ ${name} ${type} does not exist"
    fi
done

# Check enhanced monitoring components
echo ""
echo "🔧 Checking enhanced monitoring components..."

ENHANCED_COMPONENTS=(
    "nginx-ingress-controller:deployment"
    "fluent-bit:daemonset"
    "synthetic-monitoring:deployment"
    "jaeger:deployment"
)

for component in "${ENHANCED_COMPONENTS[@]}"; do
    IFS=':' read -r name type <<< "${component}"
    if resource_exists "${type}" "${name}" "${MONITORING_NAMESPACE}"; then
        echo "✅ ${name} ${type} exists"
        if [ "${type}" = "deployment" ]; then
            wait_for_deployment "${name}" "${MONITORING_NAMESPACE}"
        fi
    else
        echo "⚠️  ${name} ${type} does not exist (may be disabled)"
    fi
done

# Validate service endpoints
echo ""
echo "🌐 Validating service endpoints..."

SERVICES=(
    "prometheus:9090"
    "grafana:3000"
    "alertmanager:9093"
    "mongodb-exporter:9216"
)

for service in "${SERVICES[@]}"; do
    IFS=':' read -r name port <<< "${service}"
    if resource_exists service "${name}" "${MONITORING_NAMESPACE}"; then
        validate_service "${name}" "${MONITORING_NAMESPACE}" "${port}" || true
    else
        echo "⚠️  ${name} service does not exist"
    fi
done

# Check enhanced services
echo ""
echo "🔧 Checking enhanced service endpoints..."

ENHANCED_SERVICES=(
    "ingress-nginx-controller:80"
    "synthetic-monitoring:8080"
    "jaeger:16686"
)

for service in "${ENHANCED_SERVICES[@]}"; do
    IFS=':' read -r name port <<< "${service}"
    if resource_exists service "${name}" "${MONITORING_NAMESPACE}"; then
        validate_service "${name}" "${MONITORING_NAMESPACE}" "${port}" || true
    else
        echo "⚠️  ${name} service does not exist (may be disabled)"
    fi
done

# Test synthetic monitoring
echo ""
echo "🧪 Testing synthetic monitoring..."

if resource_exists deployment "synthetic-monitoring" "${MONITORING_NAMESPACE}"; then
    echo "🔍 Testing synthetic health checks..."

    # Test backend health check
    if kubectl run test-backend-health --image=curlimages/curl:8.1.2 --rm -i --restart=Never -- \
        curl -s --max-time 10 http://healthcare-backend.${NAMESPACE}.svc.cluster.local:5001/health >/dev/null 2>&1; then
        echo "✅ Backend health check endpoint is accessible"
    else
        echo "❌ Backend health check endpoint is not accessible"
    fi

    # Test frontend availability
    if kubectl run test-frontend-health --image=curlimages/curl:8.1.2 --rm -i --restart=Never -- \
        curl -s --max-time 10 http://healthcare-frontend.${NAMESPACE}.svc.cluster.local:3001 >/dev/null 2>&1; then
        echo "✅ Frontend service is accessible"
    else
        echo "❌ Frontend service is not accessible"
    fi
else
    echo "⚠️  Synthetic monitoring is not deployed"
fi

# Check Prometheus targets
echo ""
echo "📈 Checking Prometheus targets..."

if resource_exists deployment "prometheus" "${MONITORING_NAMESPACE}"; then
    echo "🔍 Checking Prometheus target health..."

    # Get Prometheus pod name
    PROMETHEUS_POD=$(kubectl get pods -n "${MONITORING_NAMESPACE}" -l component=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

    if [ -n "${PROMETHEUS_POD}" ]; then
        # Check targets endpoint
        TARGETS=$(kubectl exec -n "${MONITORING_NAMESPACE}" "${PROMETHEUS_POD}" -- \
            curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[].health' 2>/dev/null || echo "")

        if echo "${TARGETS}" | grep -q "up"; then
            UP_TARGETS=$(echo "${TARGETS}" | grep -c "up" || echo "0")
            TOTAL_TARGETS=$(echo "${TARGETS}" | wc -l | tr -d ' ' || echo "0")
            echo "✅ Prometheus has ${UP_TARGETS}/${TOTAL_TARGETS} healthy targets"
        else
            echo "❌ No healthy Prometheus targets found"
        fi
    else
        echo "❌ Prometheus pod not found"
    fi
else
    echo "⚠️  Prometheus is not deployed"
fi

# Summary
echo ""
echo "📋 Deployment Summary"
echo "===================="

echo "Core Monitoring Components:"
kubectl get deployments,daemonsets -n "${MONITORING_NAMESPACE}" -o name | sed 's/.*\///' | while read -r component; do
    echo "  - ${component}"
done

echo ""
echo "Available Services:"
kubectl get services -n "${MONITORING_NAMESPACE}" -o name | sed 's/.*\///' | while read -r service; do
    echo "  - ${service}"
done

echo ""
echo "🎯 Next Steps:"
echo "1. Access Grafana: kubectl port-forward -n ${MONITORING_NAMESPACE} svc/grafana 3000:3000"
echo "2. Access Prometheus: kubectl port-forward -n ${MONITORING_NAMESPACE} svc/prometheus 9090:9090"
echo "3. Access Jaeger: kubectl port-forward -n ${MONITORING_NAMESPACE} svc/jaeger 16686:16686"
echo "4. Check Grafana dashboards for enhanced monitoring visualizations"
echo "5. Review Alertmanager for active alerts"

echo ""
echo "✅ Monitoring enhancements deployment validation completed!"</content>
<parameter name="filePath">/Users/arshdang/Documents/SIT223/7.3HD/healthcare-app/terraform/deploy-monitoring.sh
