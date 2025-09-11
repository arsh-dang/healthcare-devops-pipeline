# Deployment Guide

## Prerequisites

### System Requirements
- Kubernetes cluster (v1.19+)
- kubectl configured
- Docker registry access
- Terraform (v1.0+)
- Helm (v3.0+)

### Required Tools
```bash
# Install required tools
brew install kubectl terraform helm
# or
apt-get install kubectl terraform helm
```

## Quick Start Deployment

### 1. Clone Repository
```bash
git clone https://github.com/arsh-dang/healthcare-devops-pipeline.git
cd healthcare-devops-pipeline
```

### 2. Configure Environment
```bash
# Copy environment configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit configuration
vim terraform/terraform.tfvars
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
```

### 4. Deploy Application
```bash
# Build and push Docker images
./scripts/build-and-push.sh

# Deploy to Kubernetes
kubectl apply -f k8s/
```

## Environment Configuration

### Staging Environment
```hcl
environment = "staging"

# Application settings
app_version = "latest"
frontend_image = "healthcare-app-frontend:staging"
backend_image = "healthcare-app-backend:staging"

# Database settings
mongodb_root_password = "staging-password"

# Monitoring settings
enable_monitoring = true
enable_datadog = true
```

### Production Environment
```hcl
environment = "production"

# Application settings
app_version = "v1.2.3"
frontend_image = "healthcare-app-frontend:v1.2.3"
backend_image = "healthcare-app-backend:v1.2.3"

# Database settings
mongodb_root_password = "${var.mongodb_production_password}"

# Monitoring settings
enable_monitoring = true
enable_datadog = true
datadog_api_key = "${var.datadog_api_key}"
```

## Blue-Green Deployment

### Manual Blue-Green Deployment
```bash
# Deploy to green environment
kubectl set image deployment/healthcare-app-green \
  frontend=healthcare-app-frontend:v1.2.3 \
  backend=healthcare-app-backend:v1.2.3

# Wait for deployment
kubectl rollout status deployment/healthcare-app-green

# Switch traffic to green
kubectl patch service healthcare-app -p '{
  "spec": {
    "selector": {
      "environment": "green"
    }
  }
}'

# Verify deployment
curl https://api.healthcare-app.com/health
```

### Automated Blue-Green Deployment
```bash
# Use the production deployment script
./scripts/production-deploy.sh production v1.2.3
```

## Monitoring Setup

### Grafana Access
```bash
# Port forward Grafana
kubectl port-forward svc/grafana 3000:3000

# Access at: http://localhost:3000
# Default credentials: admin/admin
```

### Prometheus Access
```bash
# Port forward Prometheus
kubectl port-forward svc/prometheus 9090:9090

# Access at: http://localhost:9090
```

### Datadog Integration
```bash
# Set Datadog API key
export DATADOG_API_KEY=your-api-key

# Deploy Datadog agent
helm repo add datadog https://helm.datadoghq.com
helm install datadog datadog/datadog \
  --set datadog.apiKey=$DATADOG_API_KEY \
  --set datadog.appKey=$DATADOG_APP_KEY
```

## Troubleshooting

### Common Issues

#### Pods Not Starting
```bash
# Check pod status
kubectl get pods

# Check pod logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

#### Database Connection Issues
```bash
# Check MongoDB pod
kubectl get pods -l app=mongodb

# Check MongoDB logs
kubectl logs -l app=mongodb

# Test database connection
kubectl exec -it <mongodb-pod> -- mongo --eval "db.runCommand('ping')"
```

#### Service Mesh Issues
```bash
# Check Istio sidecar injection
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].name}'

# Check Istio configuration
kubectl get virtualservice, destinationrule, gateway
```

### Health Checks

#### Application Health
```bash
# Frontend health
curl http://localhost:3001

# Backend health
curl http://localhost:5001/health

# Database health
curl http://localhost:5001/health/database
```

#### Infrastructure Health
```bash
# Kubernetes nodes
kubectl get nodes

# Cluster resources
kubectl top nodes
kubectl top pods

# Storage
kubectl get pvc
```

## Backup and Recovery

### Database Backup
```bash
# Create database backup
kubectl exec -it <mongodb-pod> -- mongodump --out /backup/$(date +%Y%m%d_%H%M%S)

# Copy backup to local
kubectl cp <mongodb-pod>:/backup /local/backup/path
```

### Configuration Backup
```bash
# Backup Kubernetes resources
kubectl get all -o yaml > k8s-backup.yaml

# Backup Terraform state
cp terraform/terraform.tfstate terraform/terraform.tfstate.backup
```

### Recovery Procedures
```bash
# Restore from backup
kubectl apply -f k8s-backup.yaml

# Restore database
kubectl cp backup.tar.gz <mongodb-pod>:/tmp/
kubectl exec -it <mongodb-pod> -- tar xzf /tmp/backup.tar.gz -C /
kubectl exec -it <mongodb-pod> -- mongorestore /backup
```
