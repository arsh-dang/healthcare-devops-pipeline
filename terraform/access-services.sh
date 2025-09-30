#!/bin/bash

# Healthcare App Service Access Automation Script
# This script automatically sets up port forwarding and provides service access

set -e

NAMESPACE="healthcare-staging"
MONITORING_NAMESPACE="monitoring-staging"

echo "🚀 Healthcare App Service Access Setup"
echo "======================================"

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Port $port is already in use"
        return 1
    else
        echo "✅ Port $port is available"
        return 0
    fi
}

# Function to kill existing port forwards
cleanup_port_forwards() {
    echo "🧹 Cleaning up existing port forwards..."
    pkill -f "kubectl port-forward.*healthcare-staging" 2>/dev/null || true
    pkill -f "kubectl port-forward.*monitoring-staging" 2>/dev/null || true
    sleep 2
}

# Function to setup port forwarding
setup_port_forward() {
    local service=$1
    local local_port=$2
    local service_port=$3
    local namespace=$4
    local description=$5
    
    echo "🔗 Setting up port forward for $description..."
    echo "   Local: http://localhost:$local_port"
    echo "   Service: $service:$service_port in namespace $namespace"
    
    kubectl port-forward -n $namespace service/$service $local_port:$service_port > /dev/null 2>&1 &
    local pid=$!
    sleep 2
    
    if kill -0 $pid 2>/dev/null; then
        echo "   ✅ Port forward established (PID: $pid)"
        echo $pid >> /tmp/healthcare-port-forwards.pids
        return 0
    else
        echo "   ❌ Failed to establish port forward"
        return 1
    fi
}

# Function to test service accessibility
test_service() {
    local url=$1
    local name=$2
    local max_attempts=5
    local attempt=1
    
    echo "🧪 Testing $name accessibility..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s --connect-timeout 5 "$url" > /dev/null 2>&1; then
            echo "   ✅ $name is accessible at $url"
            return 0
        else
            echo "   ⏳ Attempt $attempt/$max_attempts: $name not ready yet..."
            sleep 3
            attempt=$((attempt + 1))
        fi
    done
    
    echo "   ❌ $name is not accessible after $max_attempts attempts"
    echo "   ⚠️  Continuing setup - $name may become available later"
    return 0
}

# Main setup function
setup_services() {
    echo "📋 Setting up Healthcare App services..."
    
    # Cleanup existing port forwards
    cleanup_port_forwards
    
    # Check if services exist
    echo "🔍 Checking service availability..."
    kubectl get service frontend -n $NAMESPACE >/dev/null 2>&1 || {
        echo "❌ Frontend service not found in namespace $NAMESPACE"
        return 1
    }
    
    kubectl get service backend -n $NAMESPACE >/dev/null 2>&1 || {
        echo "❌ Backend service not found in namespace $NAMESPACE"
        return 1
    }
    
    # Setup port forwards for main services
    echo ""
    echo "🌐 Setting up main application services..."
    
    # Frontend - use port 8082 (avoiding Jenkins on 8080)
    echo "⏳ Waiting for frontend pods to be ready..."
    if kubectl wait --for=condition=ready pod -l app=healthcare-app,component=frontend,environment=staging -n $NAMESPACE --timeout=120s 2>/dev/null; then
        echo "✅ Frontend pods are ready"
        if check_port 8082; then
            setup_port_forward "frontend" 8082 80 $NAMESPACE "Healthcare App Frontend"
        else
            echo "⚠️  Using alternative port for frontend..."
            setup_port_forward "frontend" 8084 80 $NAMESPACE "Healthcare App Frontend"
        fi
    else
        echo "⚠️  Frontend pods not ready, skipping frontend port forward"
        echo "   You can manually set up frontend access once pods are ready"
    fi
    
    # Backend - use port 8083
    echo "⏳ Waiting for backend pods to be ready..."
    if kubectl wait --for=condition=ready pod -l app=healthcare-app,component=backend,environment=staging -n $NAMESPACE --timeout=120s 2>/dev/null; then
        echo "✅ Backend pods are ready"
        if check_port 8083; then
            setup_port_forward "backend" 8083 5001 $NAMESPACE "Healthcare App Backend API"
        else
            echo "⚠️  Using alternative port for backend..."
            setup_port_forward "backend" 8085 5001 $NAMESPACE "Healthcare App Backend API"
        fi
    else
        echo "⚠️  Backend pods not ready, skipping backend port forward"
        echo "   You can manually set up backend access once pods are ready"
    fi
    
    # Setup monitoring services
    echo ""
    echo "📊 Setting up monitoring services..."
    
    # Grafana
    if kubectl get service grafana-external -n $MONITORING_NAMESPACE >/dev/null 2>&1; then
        echo "⏳ Waiting for Grafana pods to be ready..."
        if kubectl wait --for=condition=ready pod -l app=healthcare-app,component=grafana,environment=staging -n $MONITORING_NAMESPACE --timeout=60s 2>/dev/null; then
            echo "✅ Grafana pods are ready"
            if check_port 3000; then
                setup_port_forward "grafana-external" 3000 3000 $MONITORING_NAMESPACE "Grafana Dashboard"
            fi
        else
            echo "⚠️  Grafana pods not ready, skipping port forward"
        fi
    fi
    
    # Prometheus
    if kubectl get service prometheus-external -n $MONITORING_NAMESPACE >/dev/null 2>&1; then
        echo "⏳ Waiting for Prometheus pods to be ready..."
        if kubectl wait --for=condition=ready pod -l app=healthcare-app,component=prometheus,environment=staging -n $MONITORING_NAMESPACE --timeout=60s 2>/dev/null; then
            echo "✅ Prometheus pods are ready"
            if check_port 9090; then
                setup_port_forward "prometheus-external" 9090 9090 $MONITORING_NAMESPACE "Prometheus Metrics"
            fi
        else
            echo "⚠️  Prometheus pods not ready, skipping port forward"
        fi
    fi
    
    # Jaeger
    if kubectl get service jaeger-external -n $MONITORING_NAMESPACE >/dev/null 2>&1; then
        echo "⏳ Waiting for Jaeger pods to be ready..."
        if kubectl wait --for=condition=ready pod -l app=healthcare-app,component=jaeger,environment=staging -n $MONITORING_NAMESPACE --timeout=60s 2>/dev/null; then
            echo "✅ Jaeger pods are ready"
            if check_port 16686; then
                setup_port_forward "jaeger-external" 16686 16686 $MONITORING_NAMESPACE "Jaeger Tracing"
            fi
        else
            echo "⚠️  Jaeger pods not ready, skipping port forward"
        fi
    fi
    
    echo ""
    echo "⏳ Waiting for services to be ready..."
    sleep 5
    
    # Test service accessibility
    echo ""
    echo "🧪 Testing service accessibility..."
    
    # Test frontend
    local frontend_port=8082
    if ! lsof -Pi :8082 -sTCP:LISTEN -t >/dev/null 2>&1; then
        frontend_port=8084
    fi
    test_service "http://localhost:$frontend_port" "Frontend"
    
    # Test backend
    local backend_port=8083
    if ! lsof -Pi :8083 -sTCP:LISTEN -t >/dev/null 2>&1; then
        backend_port=8085
    fi
    test_service "http://localhost:$backend_port/api/health" "Backend API"
    
    # Display access information
    echo ""
    echo "🎉 Healthcare App Services Ready!"
    echo "================================="
    echo ""
    echo "📱 Main Application:"
    echo "   Frontend: http://localhost:$frontend_port"
    echo "   Backend API: http://localhost:$backend_port/api/"
    echo "   Health Check: http://localhost:$backend_port/api/health"
    echo ""
    
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "📊 Monitoring Dashboards:"
        echo "   Grafana: http://localhost:3000 (admin/admin)"
        echo "   Prometheus: http://localhost:9090"
        echo "   Jaeger: http://localhost:16686"
        echo ""
    fi
    
    echo "🔧 Management Commands:"
    echo "   Stop all port forwards: pkill -f 'kubectl port-forward.*healthcare'"
    echo "   View logs: kubectl logs -n $NAMESPACE -l app=healthcare-app"
    echo "   Restart services: kubectl rollout restart -n $NAMESPACE deployment/frontend"
    echo ""
    
    # Save port forward PIDs for cleanup
    echo "💾 Port forward PIDs saved to /tmp/healthcare-port-forwards.pids"
}

# Function to stop all port forwards
stop_services() {
    echo "🛑 Stopping all Healthcare App port forwards..."
    cleanup_port_forwards
    rm -f /tmp/healthcare-port-forwards.pids
    echo "✅ All port forwards stopped"
}

# Function to show status
show_status() {
    echo "📊 Healthcare App Service Status"
    echo "================================"
    
    echo ""
    echo "🔍 Service Status:"
    kubectl get pods -n $NAMESPACE --no-headers | while read line; do
        echo "   $line"
    done
    
    echo ""
    echo "🌐 Active Port Forwards:"
    if [ -f /tmp/healthcare-port-forwards.pids ]; then
        while read pid; do
            if kill -0 $pid 2>/dev/null; then
                echo "   ✅ PID $pid: Active"
            else
                echo "   ❌ PID $pid: Inactive"
            fi
        done < /tmp/healthcare-port-forwards.pids
    else
        echo "   No active port forwards found"
    fi
    
    echo ""
    echo "🔗 Service Access:"
    echo "   Frontend: http://localhost:8082 (or 8084 if 8082 busy)"
    echo "   Backend: http://localhost:8083 (or 8085 if 8083 busy)"
    echo "   Grafana: http://localhost:3000"
    echo "   Prometheus: http://localhost:9090"
    echo "   Jaeger: http://localhost:16686"
}

# Main script logic
case "${1:-setup}" in
    "setup")
        setup_services
        ;;
    "stop")
        stop_services
        ;;
    "status")
        show_status
        ;;
    "restart")
        stop_services
        sleep 2
        setup_services
        ;;
    *)
        echo "Usage: $0 {setup|stop|status|restart}"
        echo ""
        echo "Commands:"
        echo "  setup   - Set up port forwarding for all services (default)"
        echo "  stop    - Stop all port forwards"
        echo "  status  - Show current service status"
        echo "  restart - Restart all port forwards"
        exit 1
        ;;
esac
