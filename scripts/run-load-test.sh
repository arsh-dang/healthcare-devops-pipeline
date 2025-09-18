#!/bin/bash

# Healthcare Application Load Testing Script
# This script performs comprehensive load testing and performance analysis

set -e

# Configuration
NAMESPACE="healthcare-production-green"
ARTILLERY_CONFIG="load-tests/healthcare-load-test.yml"
REPORT_DIR="load-tests/reports/$(date +%Y%m%d_%H%M%S)"
DURATION=600  # 10 minutes total test duration

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

# Create report directory
mkdir -p "$REPORT_DIR"

log_info "Starting Healthcare Application Load Test"
log_info "Report directory: $REPORT_DIR"
log_info "Test duration: $DURATION seconds"

# Pre-test checks
log_info "Performing pre-test checks..."

# Check if services are running
check_service() {
    local service=$1
    local expected_pods=$2

    if kubectl get pods -n "$NAMESPACE" -l "app=$service" --no-headers | grep -q Running; then
        local running_pods=$(kubectl get pods -n "$NAMESPACE" -l "app=$service" --no-headers | grep Running | wc -l)
        if [ "$running_pods" -ge "$expected_pods" ]; then
            log_success "$service: $running_pods pods running"
            return 0
        else
            log_warning "$service: Only $running_pods pods running (expected $expected_pods)"
            return 1
        fi
    else
        log_error "$service: No running pods found"
        return 1
    fi
}

# Check all services
SERVICES_OK=true
check_service "healthcare-app" 1 || SERVICES_OK=false
check_service "prometheus" 1 || SERVICES_OK=false
check_service "grafana" 1 || SERVICES_OK=false
check_service "alertmanager" 1 || SERVICES_OK=false

if [ "$SERVICES_OK" = false ]; then
    log_warning "Some services are not fully available. Continuing with load test..."
fi

# Get baseline metrics
log_info "Collecting baseline metrics..."
BASELINE_METRICS="$REPORT_DIR/baseline_metrics.json"
kubectl get pods -n "$NAMESPACE" -o json > "$REPORT_DIR/pods_baseline.json"
kubectl top pods -n "$NAMESPACE" > "$REPORT_DIR/cpu_memory_baseline.txt" 2>/dev/null || echo "Metrics server not available for baseline" > "$REPORT_DIR/cpu_memory_baseline.txt"

# Start monitoring script in background
log_info "Starting performance monitoring..."
MONITORING_PID=""
start_monitoring() {
    while true; do
        echo "$(date +%s),$(kubectl top pods -n "$NAMESPACE" 2>/dev/null | grep -E '(frontend|backend|mongodb)' | awk '{print $1","$2","$3}' | tr '\n' ';')" >> "$REPORT_DIR/performance_metrics.csv"
        sleep 10
    done
}

start_monitoring &
MONITORING_PID=$!

# Function to cleanup monitoring
cleanup_monitoring() {
    if [ -n "$MONITORING_PID" ]; then
        kill "$MONITORING_PID" 2>/dev/null || true
    fi
}

# Trap to ensure cleanup on exit
trap cleanup_monitoring EXIT

# Initialize performance metrics CSV
echo "timestamp,pod_metrics" > "$REPORT_DIR/performance_metrics.csv"

# Run load test
log_info "Starting load test with Artillery..."
if command -v artillery >/dev/null 2>&1; then
    artillery run "$ARTILLERY_CONFIG" \
        --output "$REPORT_DIR/artillery_report.json" \
        --overrides "{\"config\": {\"target\": \"http://$(kubectl get svc frontend -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}'):30285\"}}" || {
        log_error "Artillery load test failed"
        cleanup_monitoring
        exit 1
    }
else
    log_warning "Artillery not found. Running basic load test with curl..."

    # Basic load test using curl
    run_basic_load_test() {
        local duration=$1
        local concurrency=$2
        local endpoint=$3
        local start_time=$(date +%s)

        log_info "Running basic load test: $concurrency concurrent requests for $duration seconds"

        for i in $(seq 1 "$concurrency"); do
            (
                while [ $(($(date +%s) - start_time)) -lt "$duration" ]; do
                    curl -s -w "%{http_code},%{time_total}\n" -o /dev/null "$endpoint" >> "$REPORT_DIR/basic_load_test_results.csv"
                    sleep 0.1
                done
            ) &
        done

        wait
    }

    # Initialize results file
    echo "status_code,response_time" > "$REPORT_DIR/basic_load_test_results.csv"

    # Run different load patterns
    FRONTEND_IP=$(kubectl get svc frontend -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}')

    run_basic_load_test 60 5 "http://$FRONTEND_IP:30285/"  # Warm up
    run_basic_load_test 120 20 "http://$FRONTEND_IP:30285/"  # Load test
    run_basic_load_test 60 50 "http://$FRONTEND_IP:30285/"  # Stress test
fi

# Collect post-test metrics
log_info "Collecting post-test metrics..."
kubectl get pods -n "$NAMESPACE" -o json > "$REPORT_DIR/pods_posttest.json"
kubectl top pods -n "$NAMESPACE" > "$REPORT_DIR/cpu_memory_posttest.txt" 2>/dev/null || echo "Metrics server not available for post-test" > "$REPORT_DIR/cpu_memory_posttest.txt"

# Generate performance report
log_info "Generating performance report..."
cat > "$REPORT_DIR/performance_report.md" << EOF
# Healthcare Application Load Test Report

## Test Configuration
- **Date**: $(date)
- **Duration**: $DURATION seconds
- **Namespace**: $NAMESPACE
- **Target**: http://frontend:30285

## Pre-Test Status
$(cat "$REPORT_DIR/cpu_memory_baseline.txt")

## Post-Test Status
$(cat "$REPORT_DIR/cpu_memory_posttest.txt")

## Performance Metrics
### CPU and Memory Usage Over Time
\`\`\`csv
$(cat "$REPORT_DIR/performance_metrics.csv")
\`\`\`

## Recommendations

### Based on test results:

1. **Resource Allocation**
   - Monitor CPU usage patterns
   - Adjust memory limits based on peak usage
   - Consider horizontal scaling for high load periods

2. **Performance Optimization**
   - Review slow endpoints identified during testing
   - Optimize database queries
   - Implement caching for frequently accessed data

3. **Monitoring Enhancements**
   - Set up alerts for performance degradation
   - Monitor response times and error rates
   - Track resource utilization trends

## Test Files
- Artillery Report: artillery_report.json
- Performance Metrics: performance_metrics.csv
- Pod Status: pods_baseline.json, pods_posttest.json
- Resource Usage: cpu_memory_baseline.txt, cpu_memory_posttest.txt

EOF

# Analyze results and provide recommendations
log_info "Analyzing test results..."

# Check for errors in logs
ERROR_COUNT=$(kubectl logs -n "$NAMESPACE" -l component=frontend --tail=1000 | grep -i error | wc -l)
if [ "$ERROR_COUNT" -gt 0 ]; then
    log_warning "Found $ERROR_COUNT errors in frontend logs during test"
fi

BACKEND_ERROR_COUNT=$(kubectl logs -n "$NAMESPACE" -l component=backend --tail=1000 | grep -i error | wc -l)
if [ "$BACKEND_ERROR_COUNT" -gt 0 ]; then
    log_warning "Found $BACKEND_ERROR_COUNT errors in backend logs during test"
fi

# Check pod restarts
RESTARTS=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].status.containerStatuses[*].restartCount}' | awk '{sum+=$1} END {print sum}')
if [ "$RESTARTS" -gt 0 ]; then
    log_warning "Detected $RESTARTS pod restarts during load test"
fi

# Final report
log_success "Load test completed successfully!"
log_info "Results saved to: $REPORT_DIR"
log_info "Performance report: $REPORT_DIR/performance_report.md"

if [ "$ERROR_COUNT" -eq 0 ] && [ "$BACKEND_ERROR_COUNT" -eq 0 ] && [ "$RESTARTS" -eq 0 ]; then
    log_success "All tests passed with no errors or restarts"
else
    log_warning "Test completed with some issues detected"
fi

# Cleanup
cleanup_monitoring

echo ""
echo "=================================================="
echo "Load Test Summary:"
echo "=================================================="
echo "Report Directory: $REPORT_DIR"
echo "Test Duration: $DURATION seconds"
echo "Errors Found: $((ERROR_COUNT + BACKEND_ERROR_COUNT))"
echo "Pod Restarts: $RESTARTS"
echo "=================================================="
