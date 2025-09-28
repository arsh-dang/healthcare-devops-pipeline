#!/bin/bash

# Jenkins Datadog Integration Script
# This script integrates Datadog metrics and events into the Jenkins pipeline

set -e

# Configuration from Jenkins environment
DATADOG_API_KEY="${DATADOG_API_KEY}"
BUILD_NUMBER="${BUILD_NUMBER:-unknown}"
BUILD_URL="${BUILD_URL:-}"
GIT_COMMIT="${GIT_COMMIT:-unknown}"
GIT_BRANCH="${GIT_BRANCH:-main}"
JOB_NAME="${JOB_NAME:-healthcare-app-pipeline}"
NODE_NAME="${NODE_NAME:-unknown}"
WORKSPACE="${WORKSPACE:-/tmp}"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[DATADOG]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[DATADOG]${NC} $1"
}

log_error() {
    echo -e "${RED}[DATADOG]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[DATADOG]${NC} $1"
}

# Send pipeline start event
send_pipeline_start_event() {
    log_info "Sending pipeline start event to Datadog..."
    
    local timestamp=$(date +%s)
    local event_payload=$(cat <<EOF
{
    "title": "Healthcare App Pipeline Started",
    "text": "Healthcare application CI/CD pipeline has started execution",
    "date_happened": $timestamp,
    "priority": "normal",
    "tags": [
        "env:${ENVIRONMENT:-staging}",
        "service:healthcare-app",
        "build:${BUILD_NUMBER}",
        "branch:${GIT_BRANCH}",
        "commit:${GIT_COMMIT:0:8}",
        "jenkins:${NODE_NAME}",
        "pipeline:start"
    ],
    "alert_type": "info",
    "source_type_name": "jenkins",
    "url": "${BUILD_URL}"
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_event_response \
        -X POST "https://api.datadoghq.com/api/v1/events" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d "$event_payload")
    
    if [ "$response" = "200" ] || [ "$response" = "202" ]; then
        log_success "Pipeline start event sent successfully"
    else
        log_error "Failed to send pipeline start event (HTTP $response)"
        [ -f /tmp/datadog_event_response ] && cat /tmp/datadog_event_response
    fi
}

# Send build metrics
send_build_metrics() {
    local stage="$1"
    local duration="$2"
    local status="$3"
    
    log_info "Sending build metrics for stage: $stage"
    
    local timestamp=$(date +%s)
    local metrics_payload=$(cat <<EOF
{
    "series": [
        {
            "metric": "jenkins.build.duration",
            "points": [[$timestamp, $duration]],
            "tags": [
                "env:${ENVIRONMENT:-staging}",
                "service:healthcare-app",
                "build:${BUILD_NUMBER}",
                "stage:${stage}",
                "status:${status}",
                "branch:${GIT_BRANCH}"
            ],
            "type": "gauge"
        },
        {
            "metric": "jenkins.build.status",
            "points": [[$timestamp, $status]],
            "tags": [
                "env:${ENVIRONMENT:-staging}",
                "service:healthcare-app",
                "build:${BUILD_NUMBER}",
                "stage:${stage}",
                "branch:${GIT_BRANCH}"
            ],
            "type": "gauge"
        }
    ]
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_metrics_response \
        -X POST "https://api.datadoghq.com/api/v1/series" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d "$metrics_payload")
    
    if [ "$response" = "200" ] || [ "$response" = "202" ]; then
        log_success "Build metrics sent for stage: $stage"
    else
        log_error "Failed to send build metrics (HTTP $response)"
        [ -f /tmp/datadog_metrics_response ] && cat /tmp/datadog_metrics_response
    fi
}

# Send test results
send_test_results() {
    local test_type="$1"
    local passed="$2"
    local failed="$3"
    local total="$4"
    
    log_info "Sending test results: $test_type"
    
    local timestamp=$(date +%s)
    local metrics_payload=$(cat <<EOF
{
    "series": [
        {
            "metric": "jenkins.tests.passed",
            "points": [[$timestamp, $passed]],
            "tags": [
                "env:${ENVIRONMENT:-staging}",
                "service:healthcare-app",
                "build:${BUILD_NUMBER}",
                "test_type:${test_type}",
                "branch:${GIT_BRANCH}"
            ],
            "type": "gauge"
        },
        {
            "metric": "jenkins.tests.failed",
            "points": [[$timestamp, $failed]],
            "tags": [
                "env:${ENVIRONMENT:-staging}",
                "service:healthcare-app",
                "build:${BUILD_NUMBER}",
                "test_type:${test_type}",
                "branch:${GIT_BRANCH}"
            ],
            "type": "gauge"
        },
        {
            "metric": "jenkins.tests.total",
            "points": [[$timestamp, $total]],
            "tags": [
                "env:${ENVIRONMENT:-staging}",
                "service:healthcare-app",
                "build:${BUILD_NUMBER}",
                "test_type:${test_type}",
                "branch:${GIT_BRANCH}"
            ],
            "type": "gauge"
        }
    ]
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_test_response \
        -X POST "https://api.datadoghq.com/api/v1/series" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d "$metrics_payload")
    
    if [ "$response" = "200" ] || [ "$response" = "202" ]; then
        log_success "Test results sent for: $test_type"
    else
        log_error "Failed to send test results (HTTP $response)"
        [ -f /tmp/datadog_test_response ] && cat /tmp/datadog_test_response
    fi
}

# Send deployment metrics
send_deployment_metrics() {
    local environment="$1"
    local version="$2"
    local status="$3"
    
    log_info "Sending deployment metrics for: $environment"
    
    local timestamp=$(date +%s)
    local metrics_payload=$(cat <<EOF
{
    "series": [
        {
            "metric": "jenkins.deployment.status",
            "points": [[$timestamp, $status]],
            "tags": [
                "env:${environment}",
                "service:healthcare-app",
                "build:${BUILD_NUMBER}",
                "version:${version}",
                "branch:${GIT_BRANCH}"
            ],
            "type": "gauge"
        }
    ]
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_deployment_response \
        -X POST "https://api.datadoghq.com/api/v1/series" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d "$metrics_payload")
    
    if [ "$response" = "200" ] || [ "$response" = "202" ]; then
        log_success "Deployment metrics sent for: $environment"
    else
        log_error "Failed to send deployment metrics (HTTP $response)"
        [ -f /tmp/datadog_deployment_response ] && cat /tmp/datadog_deployment_response
    fi
}

# Send pipeline completion event
send_pipeline_completion_event() {
    local status="$1"  # success, failure, aborted
    local duration="$2"
    
    log_info "Sending pipeline completion event: $status"
    
    local timestamp=$(date +%s)
    local priority="normal"
    local alert_type="info"
    
    if [ "$status" = "failure" ]; then
        priority="high"
        alert_type="error"
    elif [ "$status" = "success" ]; then
        alert_type="success"
    fi
    
    local event_payload=$(cat <<EOF
{
    "title": "Healthcare App Pipeline $status",
    "text": "Healthcare application CI/CD pipeline completed with status: $status. Duration: ${duration}s. Build: #${BUILD_NUMBER}",
    "date_happened": $timestamp,
    "priority": "$priority",
    "tags": [
        "env:${ENVIRONMENT:-staging}",
        "service:healthcare-app",
        "build:${BUILD_NUMBER}",
        "branch:${GIT_BRANCH}",
        "commit:${GIT_COMMIT:0:8}",
        "jenkins:${NODE_NAME}",
        "pipeline:completion",
        "status:${status}"
    ],
    "alert_type": "$alert_type",
    "source_type_name": "jenkins",
    "url": "${BUILD_URL}"
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_completion_response \
        -X POST "https://api.datadoghq.com/api/v1/events" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d "$event_payload")
    
    if [ "$response" = "200" ] || [ "$response" = "202" ]; then
        log_success "Pipeline completion event sent successfully"
    else
        log_error "Failed to send pipeline completion event (HTTP $response)"
        [ -f /tmp/datadog_completion_response ] && cat /tmp/datadog_completion_response
    fi
}

# Send error event
send_error_event() {
    local error_message="$1"
    local stage="$2"
    
    log_info "Sending error event for stage: $stage"
    
    local timestamp=$(date +%s)
    local event_payload=$(cat <<EOF
{
    "title": "Healthcare App Pipeline Error",
    "text": "Healthcare application CI/CD pipeline failed in stage: $stage. Error: $error_message. Build: #${BUILD_NUMBER}",
    "date_happened": $timestamp,
    "priority": "high",
    "tags": [
        "env:${ENVIRONMENT:-staging}",
        "service:healthcare-app",
        "build:${BUILD_NUMBER}",
        "branch:${GIT_BRANCH}",
        "commit:${GIT_COMMIT:0:8}",
        "jenkins:${NODE_NAME}",
        "pipeline:error",
        "stage:${stage}"
    ],
    "alert_type": "error",
    "source_type_name": "jenkins",
    "url": "${BUILD_URL}"
}
EOF
)
    
    local response=$(curl -s -w "%{http_code}" -o /tmp/datadog_error_response \
        -X POST "https://api.datadoghq.com/api/v1/events" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DATADOG_API_KEY}" \
        -d "$event_payload")
    
    if [ "$response" = "200" ] || [ "$response" = "202" ]; then
        log_success "Error event sent successfully"
    else
        log_error "Failed to send error event (HTTP $response)"
        [ -f /tmp/datadog_error_response ] && cat /tmp/datadog_error_response
    fi
}

# Main function to handle different operations
main() {
    local operation="$1"
    shift
    
    case "$operation" in
        "pipeline-start")
            send_pipeline_start_event
            ;;
        "build-metrics")
            send_build_metrics "$1" "$2" "$3"
            ;;
        "test-results")
            send_test_results "$1" "$2" "$3" "$4"
            ;;
        "deployment")
            send_deployment_metrics "$1" "$2" "$3"
            ;;
        "pipeline-completion")
            send_pipeline_completion_event "$1" "$2"
            ;;
        "error")
            send_error_event "$1" "$2"
            ;;
        *)
            echo "Usage: $0 {pipeline-start|build-metrics|test-results|deployment|pipeline-completion|error}"
            echo ""
            echo "Examples:"
            echo "  $0 pipeline-start"
            echo "  $0 build-metrics 'Build' 120 1"
            echo "  $0 test-results 'unit' 45 2 47"
            echo "  $0 deployment 'staging' 'v1.2.3' 1"
            echo "  $0 pipeline-completion 'success' 300"
            echo "  $0 error 'Build failed' 'Build'"
            exit 1
            ;;
    esac
}

# Cleanup function
cleanup() {
    rm -f /tmp/datadog_*_response
}

# Set up cleanup on exit
trap cleanup EXIT

# Check if DATADOG_API_KEY is set
if [ -z "$DATADOG_API_KEY" ]; then
    log_error "DATADOG_API_KEY environment variable is not set"
    exit 1
fi

# Run main function
main "$@"
