#!/bin/bash

# Load Testing Script with Artillery
# Implements comprehensive performance testing for the healthcare application

set -e

# Configuration
APP_URL=${1:-"http://localhost:3001"}
API_URL=${2:-"http://localhost:5001"}
DURATION=${3:-"60"}
VIRTUAL_USERS=${4:-"10"}
REPORT_DIR="load-tests/reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Create reports directory
mkdir -p $REPORT_DIR

log_info "Starting Load Testing Suite"
log_info "=========================="
log_info "Target App URL: $APP_URL"
log_info "Target API URL: $API_URL"
log_info "Duration: ${DURATION}s"
log_info "Virtual Users: $VIRTUAL_USERS"
log_info "Report Directory: $REPORT_DIR"

# Check if Artillery is installed
if ! command -v artillery &> /dev/null; then
    log_info "Installing Artillery..."
    npm install -g artillery
fi

# Check if targets are accessible
log_info "Checking target availability..."

if curl -s --max-time 10 $APP_URL >/dev/null 2>&1; then
    log_success "Frontend is accessible"
else
    log_error "Frontend is not accessible at $APP_URL"
    exit 1
fi

if curl -s --max-time 10 $API_URL/health >/dev/null 2>&1; then
    log_success "Backend API is accessible"
else
    log_error "Backend API is not accessible at $API_URL"
    exit 1
fi

# Create dynamic Artillery configuration
cat > $REPORT_DIR/artillery-config-${TIMESTAMP}.yml << EOF
config:
  target: '$API_URL'
  phases:
    # Warm-up phase
    - duration: 30
      arrivalRate: 2
      name: "Warm-up"
    # Load testing phase
    - duration: $DURATION
      arrivalRate: $VIRTUAL_USERS
      name: "Load Test"
    # Cool-down phase
    - duration: 30
      arrivalRate: 1
      name: "Cool-down"
  defaults:
    headers:
      Content-Type: 'application/json'

scenarios:
  # API Health Check Scenario
  - name: "API Health Check"
    weight: 20
    flow:
      - get:
          url: "/health"
          expect:
            - statusCode: 200

  # User Authentication Scenario
  - name: "User Authentication"
    weight: 15
    flow:
      - post:
          url: "/api/auth/login"
          json:
            email: "test@example.com"
            password: "password123"
          expect:
            - statusCode: 200
          capture:
            json: "$.token"
            as: "auth_token"

  # Get Appointments Scenario
  - name: "Get Appointments"
    weight: 25
    flow:
      - get:
          url: "/api/appointments"
          headers:
            Authorization: "Bearer {{ auth_token }}"
          expect:
            - statusCode: 200

  # Create Appointment Scenario
  - name: "Create Appointment"
    weight: 20
    flow:
      - post:
          url: "/api/appointments"
          headers:
            Authorization: "Bearer {{ auth_token }}"
          json:
            patientId: "patient123"
            doctorId: "doctor456"
            date: "2025-09-15"
            time: "10:00"
            type: "consultation"
          expect:
            - statusCode: 201

  # Update Appointment Scenario
  - name: "Update Appointment"
    weight: 10
    flow:
      - put:
          url: "/api/appointments/{{ appointment_id }}"
          headers:
            Authorization: "Bearer {{ auth_token }}"
          json:
            status: "confirmed"
          expect:
            - statusCode: 200

  # Search Patients Scenario
  - name: "Search Patients"
    weight: 10
    flow:
      - get:
          url: "/api/patients/search?q=john"
          headers:
            Authorization: "Bearer {{ auth_token }}"
          expect:
            - statusCode: 200

EOF

log_info "Running Artillery load test..."

# Run the load test
artillery run \
    --config $REPORT_DIR/artillery-config-${TIMESTAMP}.yml \
    --output $REPORT_DIR/artillery-report-${TIMESTAMP}.json \
    --overrides '{"config": {"target": "'$API_URL'"}}'

log_success "Load test completed"

# Generate HTML report
log_info "Generating HTML report..."
artillery report \
    $REPORT_DIR/artillery-report-${TIMESTAMP}.json \
    --output $REPORT_DIR/artillery-report-${TIMESTAMP}.html

# Analyze results
log_info "Analyzing test results..."

node -e "
const fs = require('fs');
const report = JSON.parse(fs.readFileSync('$REPORT_DIR/artillery-report-${TIMESTAMP}.json', 'utf8'));

console.log('=== LOAD TEST RESULTS ===');
console.log('Duration:', report.aggregate.duration + 'ms');
console.log('Total Requests:', report.aggregate.counters['http.requests']);
console.log('Requests/sec:', report.aggregate.rates['http.request_rate']);
console.log('Response Time (avg):', Math.round(report.aggregate.summaries['http.response_time'].mean) + 'ms');
console.log('Response Time (p95):', Math.round(report.aggregate.summaries['http.response_time'].p95) + 'ms');
console.log('Response Time (p99):', Math.round(report.aggregate.summaries['http.response_time'].p99) + 'ms');

// Check for errors
const errorCount = report.aggregate.counters['errors'] || 0;
const errorRate = (errorCount / report.aggregate.counters['http.requests']) * 100;

console.log('Errors:', errorCount);
console.log('Error Rate:', errorRate.toFixed(2) + '%');

// Performance thresholds
const avgResponseTime = report.aggregate.summaries['http.response_time'].mean;
const p95ResponseTime = report.aggregate.summaries['http.response_time'].p95;
const requestRate = report.aggregate.rates['http.request_rate'];

let score = 100;
let issues = [];

if (avgResponseTime > 1000) {
    score -= 20;
    issues.push('Average response time too high (>1000ms)');
}

if (p95ResponseTime > 2000) {
    score -= 15;
    issues.push('P95 response time too high (>2000ms)');
}

if (errorRate > 5) {
    score -= 25;
    issues.push('Error rate too high (>5%)');
}

if (requestRate < 10) {
    score -= 10;
    issues.push('Request rate too low (<10 req/sec)');
}

console.log('Performance Score:', Math.max(0, score) + '/100');

if (issues.length > 0) {
    console.log('Issues Found:');
    issues.forEach(issue => console.log('- ' + issue));
} else {
    console.log('All performance thresholds met!');
}

// Save analysis to file
const analysis = {
    timestamp: new Date().toISOString(),
    duration: report.aggregate.duration,
    totalRequests: report.aggregate.counters['http.requests'],
    requestRate: report.aggregate.rates['http.request_rate'],
    avgResponseTime: report.aggregate.summaries['http.response_time'].mean,
    p95ResponseTime: report.aggregate.summaries['http.response_time'].p95,
    p99ResponseTime: report.aggregate.summaries['http.response_time'].p99,
    errorCount: errorCount,
    errorRate: errorRate,
    performanceScore: Math.max(0, score),
    issues: issues,
    recommendations: issues.length > 0 ? [
        'Consider optimizing database queries',
        'Implement caching for frequently accessed data',
        'Add rate limiting to prevent overload',
        'Consider horizontal scaling',
        'Review error handling and logging'
    ] : ['Performance is excellent!']
};

fs.writeFileSync('$REPORT_DIR/performance-analysis-${TIMESTAMP}.json', JSON.stringify(analysis, null, 2));
"

log_success "Performance analysis completed"
log_info "Reports generated:"
log_info "  - JSON Report: $REPORT_DIR/artillery-report-${TIMESTAMP}.json"
log_info "  - HTML Report: $REPORT_DIR/artillery-report-${TIMESTAMP}.html"
log_info "  - Analysis: $REPORT_DIR/performance-analysis-${TIMESTAMP}.json"

# Display summary
echo ""
log_info "=== LOAD TEST SUMMARY ==="
echo "Duration: ${DURATION}s"
echo "Virtual Users: $VIRTUAL_USERS"
echo "Target: $API_URL"
echo ""
echo "Reports saved to: $REPORT_DIR"
echo ""
echo "To view HTML report:"
echo "  open $REPORT_DIR/artillery-report-${TIMESTAMP}.html"
echo ""
echo "To view JSON analysis:"
echo "  cat $REPORT_DIR/performance-analysis-${TIMESTAMP}.json | jq ."

log_success "Load testing completed successfully!"
