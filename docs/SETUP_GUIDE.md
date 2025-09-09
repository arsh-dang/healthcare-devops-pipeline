# Healthcare DevOps Pipeline - Setup Guide

This guide provides step-by-step instructions for setting up and running the Healthcare DevOps Pipeline.

##   Prerequisites

### System Requirements
- **Jenkins** 2.400+ with Blue Ocean plugin
- **Docker** 20.10+ and Docker Compose
- **Kubernetes** cluster (local or cloud)
- **Terraform** 1.0+
- **Node.js** 20.x
- **Git** for version control

### Jenkins Plugins Required
```bash
# Core CI/CD Plugins
- Pipeline
- Blue Ocean
- Docker Pipeline
- Kubernetes
- Terraform

# Quality & Security Plugins
- SonarQube Scanner
- HTML Publisher (for reports)

# Notification Plugins
- Slack Notification
- Email Extension
```

##   Environment Setup

### 1. Jenkins Configuration

#### A. Install Required Tools
```bash
# Install Node.js 20.x in Jenkins
# Go to: Manage Jenkins > Global Tool Configuration > NodeJS
# Add NodeJS 20.x installation

# Install Docker in Jenkins agent
# Ensure Docker is available in Jenkins PATH
```

#### B. Configure Credentials
Navigate to `Manage Jenkins > Manage Credentials` and add:

| Credential ID | Type | Description |
|---------------|------|-------------|
| `docker-hub-credentials` | Username/Password | Docker Hub authentication |
| `sonarqube-token` | Secret Text | SonarQube authentication token |
| `kubeconfig` | Secret File | Kubernetes cluster configuration |
| `slack-token` | Secret Text | Slack webhook URL (optional) |

#### C. SonarQube Integration
```bash
# 1. Start SonarQube locally
docker run -d --name sonarqube -p 9000:9000 sonarqube:community

# 2. Access SonarQube at http://localhost:9000
# Default credentials: admin/admin

# 3. Create new project: healthcare-app
# 4. Generate authentication token
# 5. Add token to Jenkins credentials as 'sonarqube-token'
```

### 2. Kubernetes Setup

#### A. Local Development (minikube)
```bash
# Install minikube
brew install minikube

# Start minikube cluster
minikube start --driver=docker --memory=8192 --cpus=4

# Enable necessary addons
minikube addons enable ingress
minikube addons enable metrics-server

# Get kubeconfig
kubectl config view --raw > kube-config-file.yaml
# Upload this file to Jenkins as 'kubeconfig' credential
```

#### B. Cloud Setup (Optional)
For cloud deployments, configure your preferred Kubernetes service:
- **AWS EKS**
- **Google GKE** 
- **Azure AKS**

### 3. Docker Registry Setup

#### A. Docker Hub (Recommended)
```bash
# 1. Create Docker Hub account
# 2. Create repository: yourusername/healthcare-app
# 3. Update DOCKER_REPO in Jenkinsfile with your username
```

#### B. Update Jenkinsfile
```groovy
environment {
    DOCKER_REPO = 'yourusername/healthcare-app'  // Update this
    // ... other configurations
}
```

##   Running the Pipeline

### 1. Create Jenkins Pipeline Job

#### A. New Pipeline Job
1. Jenkins Dashboard → New Item
2. Enter name: `healthcare-devops-pipeline`
3. Select: Pipeline
4. Click OK

#### B. Configure Pipeline
1. **Pipeline Definition**: Pipeline script from SCM
2. **SCM**: Git
3. **Repository URL**: Your Git repository URL
4. **Branch**: `*/main`
5. **Script Path**: `Jenkinsfile`

### 2. First Pipeline Run

#### A. Trigger Build
```bash
# Option 1: Manual trigger
# Click "Build Now" in Jenkins

# Option 2: Git push trigger
git add .
git commit -m "feat: initial pipeline setup"
git push origin main
```

#### B. Monitor Execution
1. **Blue Ocean View**: Better visual pipeline monitoring
2. **Console Output**: Detailed logs for each stage
3. **Stage View**: Overview of pipeline progression

### 3. Pipeline Stages Execution

#### Stage 1: Build
- Installs Node.js dependencies
- Builds React frontend
- Creates Docker images (frontend + backend)

#### Stage 2: Test
- **Unit Tests**: Jest with 98.35% coverage
- **Integration Tests**: API and database connectivity
- **Reports**: Test results published to Jenkins

#### Stage 3: Code Quality
- **SonarQube Analysis**: Code quality metrics
- **Quality Gates**: Configurable quality thresholds
- **Reports**: Available in Jenkins and SonarQube

#### Stage 4: Security
- **SAST Analysis**: Source code vulnerability scanning
- **Dependency Scan**: NPM package vulnerability check
- **Container Security**: Docker image scanning with Trivy
- **Secrets Detection**: TruffleHog source code scanning

#### Stage 5: Infrastructure as Code
- **Terraform Validation**: Configuration syntax check
- **Infrastructure Planning**: Resource change preview
- **Deployment**: Kubernetes infrastructure + monitoring
- **Monitoring Setup**: Prometheus + Grafana deployment

#### Stage 6: Deploy to Staging
- **Staging Deployment**: Kubernetes staging environment
- **Health Checks**: Application readiness validation
- **Connectivity Tests**: API endpoint verification
- **Performance Baseline**: Load testing preparation

#### Stage 7: Release to Production
- **Manual Approval**: Production deployment gate
- **Blue-Green Deployment**: Zero-downtime strategy
- **Validation**: Production health checks
- **Rollback**: Automatic rollback on failure

##   Monitoring and Observability

### Prometheus Setup
```bash
# Access Prometheus (after pipeline deployment)
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring

# Open browser: http://localhost:9090
```

### Grafana Setup
```bash
# Access Grafana (after pipeline deployment)
kubectl port-forward svc/grafana 3000:80 -n monitoring

# Open browser: http://localhost:3000
# Default credentials: admin/admin
```

### Key Metrics to Monitor
- **Application Health**: HTTP response codes, response times
- **Infrastructure**: CPU, memory, disk usage
- **Business Metrics**: User registrations, appointment bookings
- **Security**: Failed login attempts, vulnerability counts

## Troubleshooting

### Common Issues

#### 1. Jenkins Build Failures
```bash
# Check Jenkins logs
kubectl logs -f jenkins-pod-name

# Verify tool installations
node --version
docker --version
terraform --version
```

#### 2. Docker Build Issues
```bash
# Local Docker build test
docker build -f Dockerfile.frontend -t test-frontend .
docker build -f Dockerfile.backend -t test-backend .

# Check Docker daemon
docker info
```

#### 3. Kubernetes Deployment Issues
```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes

# Check deployment status
kubectl get pods -n healthcare
kubectl describe pod pod-name -n healthcare
```

#### 4. Terraform Issues
```bash
# Validate Terraform configuration
cd terraform
terraform validate
terraform plan

# Check Terraform state
terraform state list
```

### Debug Commands

#### Application Debugging
```bash
# Check application logs
kubectl logs -f deployment/healthcare-frontend -n healthcare
kubectl logs -f deployment/healthcare-backend -n healthcare

# Check service connectivity
kubectl exec -it pod-name -n healthcare -- curl http://localhost:3000/health
```

#### Infrastructure Debugging
```bash
# Check Terraform outputs
cd terraform
terraform output

# Verify monitoring stack
kubectl get all -n monitoring
kubectl describe pod prometheus-pod-name -n monitoring
```

##   Additional Resources

### Documentation
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [Docker Documentation](https://docs.docker.com/)

### Best Practices
- [DevOps Best Practices](./DEVOPS_BEST_PRACTICES.md)
- [Security Guidelines](./SECURITY_GUIDELINES.md)
- [Monitoring Best Practices](./MONITORING_GUIDE.md)

### Support
- Check `TASK_COMPLIANCE.md` for requirements mapping
- Review pipeline logs in Jenkins Blue Ocean
- Monitor application health via Grafana dashboards
- Use kubectl for Kubernetes troubleshooting

---

**Next Steps**: Follow the [Deployment Guide](./DEPLOYMENT_GUIDE.md) for detailed deployment instructions.
