# 🚀 Healthcare DevOps Pipeline - Updated Quick Reference

## 📁 **Project Structure (Post-Cleanup)**

```
healthcare-app/
├── 🏗️ terraform/                        # Infrastructure as Code
│   ├── main.tf                         # Complete Terraform configuration
│   ├── init-workspace.sh               # Workspace management script
│   └── .terraform/                     # Terraform state and providers
├── ☸️ kubernetes/                       # Monitoring & Configuration
│   ├── prometheus.yaml                 # Metrics collection
│   ├── grafana.yaml                    # Dashboard visualization
│   ├── prometheus-rules.yaml           # Alert rules
│   ├── config-map.yaml                 # Application config
│   ├── ingress.yaml                    # Traffic routing
│   └── deploy.sh                       # Automated deployment
├── ⚛️ src/                              # React Frontend
├── 🚀 server/                           # Express.js Backend
├── 🧪 postman/                          # API Testing
├── 📊 load-tests/                       # Performance Testing
├── 🔧 scripts/                          # Automation Scripts
├── 🐳 Dockerfile.frontend               # Frontend container
├── 🐳 Dockerfile.backend                # Backend container
├── 🔧 Jenkinsfile                       # Complete CI/CD Pipeline
├── 📋 .eslintrc.json                    # Code quality config
├── 📦 pnpm-lock.yaml                    # Package lock (pnpm)
└── 📚 Documentation Files              # Setup & assessment docs
```

## ⚡ **Quick Commands**

### **Deploy with Terraform (Recommended)**
```bash
# Deploy infrastructure
cd terraform
terraform init
terraform apply -var="environment=staging"

# Deploy monitoring
NAMESPACE=$(terraform output -raw namespace)
kubectl apply -f ../kubernetes/prometheus.yaml -n $NAMESPACE
kubectl apply -f ../kubernetes/grafana.yaml -n $NAMESPACE
```

### **Run Complete Pipeline**
```bash
# Start Jenkins and trigger pipeline
brew services start jenkins
# Open http://localhost:8080 and run healthcare-app-pipeline
```

### **Quick Validation**
```bash
# Validate entire setup
./scripts/validate-deployment.sh

# Check Terraform infrastructure
cd terraform && terraform show

# Check running services
kubectl get all -n $(terraform output -raw namespace)
```

### **Access Services**
```bash
# Get namespace
NAMESPACE=$(cd terraform && terraform output -raw namespace)

# Port forward services
kubectl port-forward svc/frontend 3000:3000 -n $NAMESPACE &
kubectl port-forward svc/backend 5000:5000 -n $NAMESPACE &
kubectl port-forward svc/grafana 3001:3000 -n $NAMESPACE &

# Access URLs
# Frontend: http://localhost:3000
# Backend API: http://localhost:5000/health
# Grafana: http://localhost:3001 (admin/admin123)
```

## 🎯 **Pipeline Stages Overview**

| Stage | Description | Tool/Technology |
|-------|-------------|----------------|
| 1️⃣ **Build** | Frontend/Backend compilation | React, Express.js, Docker |
| 2️⃣ **Test** | Unit, Integration, API tests | Jest, Supertest, Newman |
| 3️⃣ **Code Quality** | Static analysis, coverage | SonarQube, ESLint |
| 4️⃣ **Security** | Vulnerability scanning | Trivy, Semgrep, TruffleHog |
| 5️⃣ **Infrastructure** | Deploy with IaC | **Terraform** |
| 6️⃣ **Deploy** | Application deployment | Kubernetes (Terraform-managed) |
| 7️⃣ **Monitor** | Observability setup | Prometheus, Grafana |

## 🏆 **High HD Criteria Checklist**

- ✅ **All 7 Stages**: Complete pipeline with automation
- ✅ **Infrastructure as Code**: Terraform manages all resources
- ✅ **Advanced Testing**: Multi-level testing strategy
- ✅ **Security Integration**: Multi-tool vulnerability scanning
- ✅ **Production Ready**: Auto-scaling, monitoring, rollback
- ✅ **Clean Architecture**: No redundancies, best practices

## 🛠️ **Troubleshooting**

### **Common Issues**
```bash
# Terraform workspace issues
cd terraform
terraform workspace list
terraform workspace select staging

# Pod not starting
kubectl describe pod <pod-name> -n $NAMESPACE
kubectl logs <pod-name> -n $NAMESPACE

# Service not accessible
kubectl get svc -n $NAMESPACE
kubectl port-forward svc/<service-name> <local-port>:<service-port> -n $NAMESPACE
```

### **Reset Environment**
```bash
# Destroy Terraform infrastructure
cd terraform
terraform destroy -var="environment=staging"

# Clean up Kubernetes
kubectl delete namespace $(terraform output -raw namespace) --ignore-not-found

# Restart Colima
colima delete && colima start --kubernetes
```

## 📈 **Performance & Scaling**

### **Auto-Scaling Configuration**
- **Frontend**: 2-6 replicas (70% CPU threshold)
- **Backend**: 3-9 replicas (70% CPU, 80% Memory)
- **MongoDB**: Production: 3 replicas, Staging: 1 replica

### **Resource Allocation**
- **Staging**: 2 frontend, 3 backend replicas
- **Production**: 3 frontend, 5 backend replicas
- **Storage**: 10Gi staging, 100Gi production

This updated structure provides enterprise-grade DevOps with complete Infrastructure as Code implementation!
