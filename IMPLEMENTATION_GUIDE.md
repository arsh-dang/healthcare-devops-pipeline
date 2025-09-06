# Implementation Guide - Next Steps

## Phase 1: Environment Setup (30-60 minutes)

### Step 1: Install Required Tools

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install docker colima kubectl helm terraform
brew install --cask jenkins

# Install Node.js and pnpm
brew install node
npm install -g pnpm

# Start Docker environment
colima start --kubernetes --cpu 4 --memory 8 --disk 50
```

### Step 2: Jenkins Setup

```bash
# Start Jenkins
brew services start jenkins

# Get initial admin password
cat /opt/homebrew/var/lib/jenkins/secrets/initialAdminPassword

# Access Jenkins at http://localhost:8080
```

**Jenkins Plugin Installation** (Install these via Jenkins UI: Manage Jenkins > Manage Plugins):
- Pipeline
- Blue Ocean
- Docker Pipeline
- Kubernetes CLI
- SonarQube Scanner
- NodeJS Plugin
- Email Extension
- HTML Publisher
- JUnit
- Coverage

### Step 3: SonarQube Setup

```bash
# Start SonarQube with Docker
docker run -d --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest

# Access SonarQube at http://localhost:9000
# Default credentials: admin/admin
```

## Phase 2: Jenkins Configuration (45-90 minutes)

### Step 1: Global Tool Configuration

1. **Navigate to**: Manage Jenkins > Global Tool Configuration

2. **Add Node.js**:
   - Name: `20.x`
   - Install automatically: ✓
   - Version: NodeJS 20.x.x

3. **Add SonarQube Scanner**:
   - Name: `SonarQube Scanner`
   - Install automatically: ✓

### Step 2: System Configuration

1. **Navigate to**: Manage Jenkins > Configure System

2. **Add SonarQube Server**:
   - Name: `SonarQube`
   - Server URL: `http://localhost:9000`
   - Server authentication token: (Generate in SonarQube and add to Jenkins credentials)

### Step 3: Credentials Setup

Navigate to: Manage Jenkins > Manage Credentials > System > Global credentials

**Add these credentials**:

1. **Docker Hub Credentials**:
   - Kind: Username with password
   - ID: `docker-hub-credentials`
   - Username: [Your Docker Hub username]
   - Password: [Your Docker Hub password/token]

2. **SonarQube Token**:
   - Kind: Secret text
   - ID: `sonar-token`
   - Secret: [SonarQube authentication token]

3. **Kubeconfig**:
   - Kind: Secret file
   - ID: `kubeconfig`
   - File: Upload your kubeconfig file

## Phase 3: Project Setup (30 minutes)

### Step 1: Update Project Configuration

```bash
# Navigate to your project directory
cd /Users/arshdang/Documents/SIT223/7.3HD/healthcare-app

# Update Docker registry in Jenkinsfile
# Replace 'yourusername' with your actual Docker Hub username
sed -i '' 's/yourusername/[YOUR_DOCKER_USERNAME]/g' Jenkinsfile

# Make scripts executable
chmod +x scripts/advanced-security-scan.sh

# Install project dependencies
pnpm install
```

### Step 2: Git Repository Setup

```bash
# Initialize git repository (if not already done)
git init
git add .
git commit -m "Initial commit with advanced DevOps pipeline"

# Add remote repository (replace with your GitHub repo)
git remote add origin https://github.com/[USERNAME]/healthcare-app.git
git push -u origin main
```

## Phase 4: Jenkins Pipeline Creation (15 minutes)

### Step 1: Create Pipeline Job

1. **Navigate to**: Jenkins Dashboard
2. **Click**: "New Item"
3. **Enter**: `healthcare-app-pipeline`
4. **Select**: "Pipeline"
5. **Click**: "OK"

### Step 2: Configure Pipeline

**Pipeline Configuration**:
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: Your GitHub repository URL
- **Credentials**: Add GitHub credentials if private repo
- **Branches to build**: `*/main`
- **Script Path**: `Jenkinsfile`

**Build Triggers**:
- ☑ GitHub hook trigger for GITScm polling
- ☑ Poll SCM: `H/5 * * * *`

### Step 3: Save and Test

1. **Click**: "Save"
2. **Click**: "Build Now" to test the pipeline

## Phase 5: Kubernetes Setup (30 minutes)

### Step 1: Deploy Application to Kubernetes

```bash
# Apply Kubernetes configurations
kubectl apply -f kubernetes/config-map.yaml
kubectl apply -f kubernetes/mongodb-statefulset.yaml
kubectl apply -f kubernetes/backend-deployment.yaml
kubectl apply -f kubernetes/frontend-deployment.yaml
kubectl apply -f kubernetes/ingress.yaml

# Check deployment status
kubectl get pods
kubectl get services
```

### Step 2: Setup Monitoring

```bash
# Deploy Prometheus and Grafana
kubectl apply -f kubernetes/prometheus.yaml
kubectl apply -f kubernetes/grafana.yaml
kubectl apply -f kubernetes/advanced-monitoring.yaml

# Port forward to access services
kubectl port-forward svc/prometheus-service 9090:9090 &
kubectl port-forward svc/grafana 3000:3000 &
```

## Phase 6: Testing and Validation (45 minutes)

### Step 1: Run Initial Pipeline

1. **Trigger**: Manual build in Jenkins
2. **Monitor**: Blue Ocean view for real-time progress
3. **Verify**: All stages complete successfully

### Step 2: Validate Deployments

```bash
# Check application health
curl http://localhost:5000/health

# Check Kubernetes pods
kubectl get pods -l app=healthcare-app

# Check HPA status
kubectl get hpa
```

### Step 3: Test Monitoring

1. **Access Grafana**: http://localhost:3000 (admin/admin)
2. **Import Dashboards**: Use the dashboard JSON from advanced-monitoring.yaml
3. **Verify Metrics**: Check that application metrics are flowing

## Phase 7: Demo Preparation (30 minutes)

### Step 1: Create Demo Environment

```bash
# Ensure all services are running
kubectl get all

# Test application functionality
# Frontend: http://localhost:3000
# Backend API: http://localhost:5000/api/appointments
# Monitoring: http://localhost:3000 (Grafana)
```

### Step 2: Prepare Demo Script

1. **Review**: DEMO_SCRIPT.md for presentation flow
2. **Practice**: Run through the complete pipeline
3. **Screenshots**: Capture key pipeline stages and monitoring dashboards

### Step 3: Record Demo Video

**Recording Checklist**:
- ☑ Clone repository and pipeline setup
- ☑ Pipeline execution with all 7 stages
- ☑ Real-time monitoring in Grafana
- ☑ Application functionality demonstration
- ☑ Security scan results
- ☑ Quality gate validation

## Phase 8: Documentation and Submission

### Step 1: Final Documentation Review

Ensure these documents are complete:
- ☑ JENKINS_SETUP.md
- ☑ HD_ASSESSMENT.md
- ☑ DEMO_SCRIPT.md
- ☑ README.md updates

### Step 2: Repository Finalization

```bash
# Final commit with all enhancements
git add .
git commit -m "Complete DevOps pipeline with advanced features"
git push origin main

# Create release tag
git tag -a v1.0.0 -m "Production-ready healthcare app with full DevOps pipeline"
git push origin v1.0.0
```

## Troubleshooting Guide

### Common Issues and Solutions

**Jenkins Build Fails - Node.js not found**:
```bash
# Solution: Ensure Node.js tool is configured correctly
# Jenkins > Global Tool Configuration > NodeJS > Add NodeJS 20.x
```

**Docker Build Fails**:
```bash
# Solution: Ensure Docker is running
colima status
colima start --kubernetes
```

**SonarQube Connection Issues**:
```bash
# Solution: Check SonarQube is running
docker ps | grep sonarqube
# Restart if needed: docker restart sonarqube
```

**Kubernetes Deployment Issues**:
```bash
# Solution: Check cluster status
kubectl cluster-info
kubectl get nodes

# Check pod logs
kubectl logs -l app=healthcare-app
```

**Pipeline Permissions Issues**:
```bash
# Solution: Ensure Jenkins has proper permissions
# Add Jenkins user to docker group
sudo usermod -aG docker jenkins
```

## Success Validation Checklist

Before demo/submission, verify:

- ☑ Jenkins pipeline runs successfully through all 7 stages
- ☑ Application deploys to Kubernetes successfully
- ☑ Monitoring dashboards show real-time metrics
- ☑ Security scans complete without critical issues
- ☑ Quality gates pass in SonarQube
- ☑ All documentation is complete and accurate
- ☑ Demo video is recorded and under 10 minutes
- ☑ GitHub repository is accessible with proper permissions

## Timeline Summary

- **Phase 1-2**: 2-3 hours (Environment and Jenkins setup)
- **Phase 3-4**: 1 hour (Project and pipeline configuration)
- **Phase 5-6**: 1.5 hours (Kubernetes deployment and testing)
- **Phase 7-8**: 1 hour (Demo preparation and documentation)

**Total Estimated Time**: 5-6 hours for complete implementation

## Next Immediate Action

**Start with Phase 1**: Install the required tools and set up your environment. This foundation is crucial for everything else to work properly.
