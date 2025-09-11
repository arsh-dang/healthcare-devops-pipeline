#!/bin/bash

# Chaos Engineering Script - Chaos Monkey Implementation
# Simulates various failure scenarios to test system resilience

set -e

# Configuration
NAMESPACE=${1:-"healthcare-staging"}
DURATION=${2:-"300"}
CHAOS_LEVEL=${3:-"moderate"}  # low, moderate, high, extreme
REPORT_DIR="chaos-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

log_chaos() {
    echo -e "${PURPLE}[CHAOS]${NC} $1"
}

# Create reports directory
mkdir -p $REPORT_DIR

log_chaos "Starting Chaos Engineering Experiment"
log_chaos "===================================="
log_info "Namespace: $NAMESPACE"
log_info "Duration: ${DURATION}s"
log_info "Chaos Level: $CHAOS_LEVEL"
log_info "Report Directory: $REPORT_DIR"

# Check if kubectl is available and namespace exists
if ! kubectl cluster-info >/dev/null 2>&1; then
    log_error "Kubernetes cluster not accessible"
    exit 1
fi

if ! kubectl get namespace $NAMESPACE >/dev/null 2>&1; then
    log_error "Namespace $NAMESPACE does not exist"
    exit 1
fi

# Get initial state
log_info "Capturing initial system state..."
INITIAL_PODS=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)
INITIAL_DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE --no-headers | wc -l)

log_info "Initial state: $INITIAL_PODS pods, $INITIAL_DEPLOYMENTS deployments"

# Chaos experiment configuration based on level
case $CHAOS_LEVEL in
    "low")
        POD_KILL_PROBABILITY=10
        NETWORK_DELAY_PROBABILITY=5
        RESOURCE_STRESS_PROBABILITY=5
        ;;
    "moderate")
        POD_KILL_PROBABILITY=20
        NETWORK_DELAY_PROBABILITY=10
        RESOURCE_STRESS_PROBABILITY=10
        ;;
    "high")
        POD_KILL_PROBABILITY=30
        NETWORK_DELAY_PROBABILITY=20
        RESOURCE_STRESS_PROBABILITY=20
        ;;
    "extreme")
        POD_KILL_PROBABILITY=50
        NETWORK_DELAY_PROBABILITY=30
        RESOURCE_STRESS_PROBABILITY=30
        ;;
    *)
        log_error "Invalid chaos level: $CHAOS_LEVEL"
        exit 1
        ;;
esac

log_chaos "Chaos Configuration:"
log_chaos "  - Pod Kill Probability: ${POD_KILL_PROBABILITY}%"
log_chaos "  - Network Delay Probability: ${NETWORK_DELAY_PROBABILITY}%"
log_chaos "  - Resource Stress Probability: ${RESOURCE_STRESS_PROBABILITY}%"

# Initialize chaos report
CHAOS_REPORT="$REPORT_DIR/chaos-experiment-${TIMESTAMP}.json"
cat > $CHAOS_REPORT << EOF
{
  "experiment": {
    "timestamp": "$(date -Iseconds)",
    "namespace": "$NAMESPACE",
    "duration": $DURATION,
    "chaos_level": "$CHAOS_LEVEL",
    "configuration": {
      "pod_kill_probability": $POD_KILL_PROBABILITY,
      "network_delay_probability": $NETWORK_DELAY_PROBABILITY,
      "resource_stress_probability": $RESOURCE_STRESS_PROBABILITY
    }
  },
  "events": [],
  "metrics": {
    "pod_kills": 0,
    "network_delays": 0,
    "resource_stresses": 0,
    "system_recoveries": 0,
    "total_disruptions": 0
  },
  "observations": []
}
EOF

# Function to log chaos event
log_chaos_event() {
    local event_type=$1
    local description=$2
    local target=$3
    local timestamp=$(date -Iseconds)

    log_chaos "$event_type: $description (Target: $target)"

    # Update JSON report
    jq --arg timestamp "$timestamp" \
       --arg event_type "$event_type" \
       --arg description "$description" \
       --arg target "$target" \
       '.events += [{"timestamp": $timestamp, "type": $event_type, "description": $description, "target": $target}]' \
       $CHAOS_REPORT > ${CHAOS_REPORT}.tmp && mv ${CHAOS_REPORT}.tmp $CHAOS_REPORT
}

# Function to update metrics
update_metrics() {
    local metric=$1
    local increment=${2:-1}

    jq --arg metric "$metric" --argjson increment "$increment" \
       '.metrics[$metric] += $increment' \
       $CHAOS_REPORT > ${CHAOS_REPORT}.tmp && mv ${CHAOS_REPORT}.tmp $CHAOS_REPORT
}

# Function to add observation
add_observation() {
    local observation=$1
    local timestamp=$(date -Iseconds)

    jq --arg timestamp "$timestamp" \
       --arg observation "$observation" \
       '.observations += [{"timestamp": $timestamp, "observation": $observation}]' \
       $CHAOS_REPORT > ${CHAOS_REPORT}.tmp && mv ${CHAOS_REPORT}.tmp $CHAOS_REPORT
}

# Chaos monkey functions
kill_random_pod() {
    local pods=($(kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name" | grep -v "monitoring\|prometheus\|grafana\|alertmanager"))
    local pod_count=${#pods[@]}

    if [ $pod_count -gt 0 ]; then
        local random_index=$((RANDOM % pod_count))
        local target_pod=${pods[$random_index]}

        log_chaos_event "POD_KILL" "Terminating pod to simulate failure" "$target_pod"
        kubectl delete pod $target_pod -n $NAMESPACE --grace-period=0 --force
        update_metrics "pod_kills"
        update_metrics "total_disruptions"

        # Wait a moment for system to react
        sleep 5

        # Check if system recovers
        if kubectl get pods -n $NAMESPACE | grep -q "$target_pod.*Running"; then
            add_observation "Pod $target_pod recovered successfully"
            update_metrics "system_recoveries"
        else
            add_observation "Pod $target_pod failed to recover - system may be unstable"
        fi
    fi
}

inject_network_delay() {
    local pods=($(kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name" | grep -v "monitoring\|prometheus\|grafana\|alertmanager"))
    local pod_count=${#pods[@]}

    if [ $pod_count -gt 0 ]; then
        local random_index=$((RANDOM % pod_count))
        local target_pod=${pods[$random_index]}

        log_chaos_event "NETWORK_DELAY" "Injecting network delay to simulate connectivity issues" "$target_pod"

        # Use kubectl debug to inject network delay (if available)
        if kubectl debug --help >/dev/null 2>&1; then
            kubectl debug $target_pod -n $NAMESPACE --image=busybox --target=healthcare-app -- \
                tc qdisc add dev eth0 root netem delay 500ms 100ms distribution normal
        else
            log_warning "kubectl debug not available - simulating network delay"
        fi

        update_metrics "network_delays"
        update_metrics "total_disruptions"

        # Wait for delay to take effect
        sleep 10

        add_observation "Network delay injected on $target_pod - monitoring system response"
    fi
}

stress_resources() {
    local pods=($(kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name" | grep -v "monitoring\|prometheus\|grafana\|alertmanager"))
    local pod_count=${#pods[@]}

    if [ $pod_count -gt 0 ]; then
        local random_index=$((RANDOM % pod_count))
        local target_pod=${pods[$random_index]}

        log_chaos_event "RESOURCE_STRESS" "Injecting resource stress to simulate overload" "$target_pod"

        # Execute stress test in the pod
        kubectl exec $target_pod -n $NAMESPACE -- sh -c "
            # Install stress if not available
            if ! command -v stress >/dev/null 2>&1; then
                apk add --no-cache stress || apt-get update && apt-get install -y stress || yum install -y stress || echo 'Stress tool not available'
            fi

            # Run stress test for 30 seconds
            stress --cpu 2 --timeout 30 &
        " || log_warning "Could not inject resource stress - stress tool not available"

        update_metrics "resource_stresses"
        update_metrics "total_disruptions"

        add_observation "Resource stress injected on $target_pod - monitoring performance impact"
    fi
}

# Function to check system health
check_system_health() {
    local healthy_pods=$(kubectl get pods -n $NAMESPACE --no-headers | grep -c "Running")
    local total_pods=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)

    if [ $total_pods -gt 0 ]; then
        local health_percentage=$((healthy_pods * 100 / total_pods))
        add_observation "System health: $healthy_pods/$total_pods pods running ($health_percentage%)"

        if [ $health_percentage -lt 80 ]; then
            log_warning "System health degraded: $health_percentage% of pods running"
        fi
    fi
}

# Main chaos experiment loop
log_chaos "Starting chaos experiment for ${DURATION} seconds..."

END_TIME=$((SECONDS + DURATION))
CHAOS_EVENTS=0

while [ $SECONDS -lt $END_TIME ]; do
    # Random delay between chaos events (10-60 seconds)
    delay=$((10 + RANDOM % 51))
    sleep $delay

    # Generate random number for chaos decision
    chaos_roll=$((RANDOM % 100 + 1))

    if [ $chaos_roll -le $POD_KILL_PROBABILITY ]; then
        kill_random_pod
        CHAOS_EVENTS=$((CHAOS_EVENTS + 1))
    elif [ $chaos_roll -le $(($POD_KILL_PROBABILITY + $NETWORK_DELAY_PROBABILITY)) ]; then
        inject_network_delay
        CHAOS_EVENTS=$((CHAOS_EVENTS + 1))
    elif [ $chaos_roll -le $(($POD_KILL_PROBABILITY + $NETWORK_DELAY_PROBABILITY + $RESOURCE_STRESS_PROBABILITY)) ]; then
        stress_resources
        CHAOS_EVENTS=$((CHAOS_EVENTS + 1))
    fi

    # Periodic health check
    if [ $((SECONDS % 30)) -eq 0 ]; then
        check_system_health
    fi
done

# Final system health check
log_info "Chaos experiment completed - performing final health check..."
check_system_health

# Generate final report
FINAL_PODS=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)
FINAL_DEPLOYMENTS=$(kubectl get deployments -n $NAMESPACE --no-headers | wc -l)

jq --argjson final_pods "$FINAL_PODS" \
   --argjson final_deployments "$FINAL_DEPLOYMENTS" \
   --argjson chaos_events "$CHAOS_EVENTS" \
   '.experiment.final_state = {"pods": $final_pods, "deployments": $final_deployments, "chaos_events": $chaos_events}' \
   $CHAOS_REPORT > ${CHAOS_REPORT}.tmp && mv ${CHAOS_REPORT}.tmp $CHAOS_REPORT

log_success "Chaos experiment completed!"
log_info "Summary:"
log_info "  - Duration: ${DURATION}s"
log_info "  - Chaos Events: $CHAOS_EVENTS"
log_info "  - Initial Pods: $INITIAL_PODS"
log_info "  - Final Pods: $FINAL_PODS"
log_info "  - Report: $CHAOS_REPORT"

# Display key findings
echo ""
log_chaos "=== CHAOS EXPERIMENT RESULTS ==="
echo "Total Chaos Events: $CHAOS_EVENTS"
echo "System Resilience: $([ $FINAL_PODS -ge $INITIAL_PODS ] && echo "MAINTAINED" || echo "DEGRADED")"
echo ""
echo "Key Findings:"
jq -r '.observations[]?.observation' $CHAOS_REPORT 2>/dev/null || echo "No observations recorded"

echo ""
echo "Recommendations:"
if [ $FINAL_PODS -lt $INITIAL_PODS ]; then
    echo "- System showed signs of instability under chaos"
    echo "- Consider implementing better pod disruption budgets"
    echo "- Review resource limits and requests"
    echo "- Implement circuit breakers for external dependencies"
else
    echo "- System demonstrated good resilience"
    echo "- Chaos engineering practices are effective"
    echo "- Continue regular chaos experiments"
fi

log_success "Chaos engineering report saved to: $CHAOS_REPORT"
