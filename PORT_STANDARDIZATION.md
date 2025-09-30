# Port Standardization Guide

## Current Working Ports

### ✅ **Port Forwarding (Recommended for Development)**
- **Frontend**: `localhost:8082` → `frontend:80`
- **Backend**: `localhost:8083` → `backend:5001`
- **Grafana**: `localhost:3000` → `grafana:3000`
- **Prometheus**: `localhost:9090` → `prometheus:9090`
- **Jaeger**: `localhost:16686` → `jaeger:16686`

### ✅ **NodePort (Working after Terraform Fix)**
- **Frontend**: `localhost:32710` (NodePort 80:32710)
- **Backend**: `localhost:32711` (NodePort 5001:32711)
- **Grafana**: `localhost:31285` (NodePort 3000:31285)
- **Prometheus**: `localhost:32713` (NodePort 9090:32713)
- **Jaeger**: `localhost:32715` (NodePort 16686:32715)

### ❌ **Incorrect Ports (Need to be Fixed)**
- **Port 30285**: This port doesn't exist and is used in many scripts
- **Various other ports**: Many scripts use inconsistent ports

## Port Usage Strategy

### **For Jenkins Pipeline:**
- Use **Port Forwarding** (`localhost:8082`, `localhost:8083`) for testing
- Use **NodePort** (`localhost:32710`, `localhost:32711`) for external access

### **For Local Development:**
- Use **Port Forwarding** for consistent development experience
- Use **NodePort** for testing external access

### **For Production:**
- Use **Ingress** with proper domain names
- Use **LoadBalancer** services for cloud deployments

## Files That Need Port Updates

### **High Priority (Broken)**
1. `scripts/generate-docs.sh` - Uses `localhost:30285` (doesn't exist)
2. `scripts/validate-deployment.sh` - Uses `localhost:30285`
3. `scripts/load-testing.sh` - Uses `localhost:30285`
4. `scripts/advanced-security-scan.sh` - Uses `localhost:30285`
5. `scripts/README-health-check.md` - Documents `localhost:30285`

### **Medium Priority (Inconsistent)**
1. `Jenkinsfile` - Mixed usage of ports
2. `terraform/terraform.tfstate` - Contains old port references
3. `postman/healthcare-api.postman_collection.json` - May need updates
4. `load-tests/load-test-config.yml` - May need updates

### **Low Priority (Documentation)**
1. Various README files
2. Documentation generation scripts
3. API documentation

## Recommended Standard Ports

### **Development/Testing**
```bash
# Port Forwarding (Preferred)
FRONTEND_URL="http://localhost:8082"
BACKEND_URL="http://localhost:8083"
GRAFANA_URL="http://localhost:3000"
PROMETHEUS_URL="http://localhost:9090"
JAEGER_URL="http://localhost:16686"

# NodePort (Alternative)
FRONTEND_URL="http://localhost:32710"
BACKEND_URL="http://localhost:32711"
GRAFANA_URL="http://localhost:31285"
PROMETHEUS_URL="http://localhost:32713"
JAEGER_URL="http://localhost:32715"
```

### **Environment Variables**
```bash
export APP_URL="http://localhost:8082"
export API_URL="http://localhost:8083"
export GRAFANA_URL="http://localhost:3000"
export PROMETHEUS_URL="http://localhost:9090"
export JAEGER_URL="http://localhost:16686"
```

## Next Steps

1. ✅ **Fixed**: External services now have correct selectors
2. ✅ **Verified**: NodePorts are working
3. 🔄 **In Progress**: Update all scripts to use correct ports
4. ⏳ **Pending**: Update documentation
5. ⏳ **Pending**: Update Jenkins pipeline for consistency
6. ⏳ **Pending**: Update Postman collections
7. ⏳ **Pending**: Update load testing configurations

## Testing Commands

```bash
# Test Port Forwarding
curl http://localhost:8082/health
curl http://localhost:8083/health

# Test NodePort
curl http://localhost:32710/health
curl http://localhost:32711/health

# Test Monitoring
curl http://localhost:3000  # Grafana
curl http://localhost:9090  # Prometheus
curl http://localhost:16686 # Jaeger
```
