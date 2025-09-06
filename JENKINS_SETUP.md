# Jenkins DevOps Pipeline Setup Guide

## Overview

This guide provides step-by-step instructions for setting up a complete Jenkins DevOps pipeline for the Healthcare Appointments application. The pipeline includes 7 comprehensive stages: Build, Test, Code Quality, Security, Deploy, Release, and Monitoring.

## Prerequisites

### System Requirements
- Jenkins 2.400+ with Blue Ocean plugin
- Docker and Docker Compose
- Node.js 20.x
- kubectl CLI
- Git
- SonarQube (local or cloud)
- Access to a Kubernetes cluster

### Required Jenkins Plugins

Install the following plugins in Jenkins:
```
- Pipeline
- Blue Ocean
- Docker Pipeline
- Kubernetes CLI
- SonarQube Scanner
- NodeJS
- Email Extension
- Slack Notification
- HTML Publisher
- JUnit
- Coverage
- Warnings Next Generation
```

## Jenkins Configuration

### 1. Global Tool Configuration

#### Node.js Configuration
1. Go to `Manage Jenkins` > `Global Tool Configuration`
2. Add Node.js installation:
   - Name: `20.x`
   - Version: `NodeJS 20.x.x`
   - Install automatically: ✓

#### SonarQube Configuration
1. Go to `Manage Jenkins` > `Configure System`
2. Add SonarQube server:
   - Name: `SonarQube`
   - Server URL: `http://localhost:9000` (or your SonarQube URL)
   - Server authentication token: Add from credentials

### 2. Credentials Configuration

Add the following credentials in `Manage Jenkins` > `Manage Credentials`:

#### Docker Hub Credentials
- **ID**: `docker-hub-credentials`
- **Type**: Username with password
- **Username**: Your Docker Hub username
- **Password**: Your Docker Hub password/token

#### SonarQube Token
- **ID**: `sonar-token`
- **Type**: Secret text
- **Secret**: Your SonarQube authentication token

#### Kubernetes Config
- **ID**: `kubeconfig`
- **Type**: Secret file
- **File**: Your kubeconfig file for production cluster

#### Kubernetes Staging Config
- **ID**: `kubeconfig-staging`
- **Type**: Secret file
- **File**: Your kubeconfig file for staging cluster

#### GitHub Token (if using private repos)
- **ID**: `github-token`
- **Type**: Secret text
- **Secret**: Your GitHub personal access token

### 3. Pipeline Job Creation

1. Create a new Pipeline job in Jenkins
2. Configure the following settings:

#### General Settings
- **Project Name**: `healthcare-app-pipeline`
- **Description**: `Complete DevOps pipeline for Healthcare Appointments application`
- **GitHub project**: Check and add your repository URL

#### Build Triggers
- **GitHub hook trigger for GITScm polling**: ✓
- **Poll SCM**: `H/5 * * * *` (every 5 minutes)

#### Pipeline Configuration
- **Definition**: Pipeline script from SCM
- **SCM**: Git
- **Repository URL**: Your GitHub repository URL
- **Credentials**: Select your GitHub credentials
- **Branch**: `*/main` (or your default branch)
- **Script Path**: `Jenkinsfile`

## Environment Setup

### 1. SonarQube Setup

#### Option 1: Local SonarQube
```bash
# Using Docker
docker run -d --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest

# Access at http://localhost:9000
# Default credentials: admin/admin
```

#### Option 2: SonarCloud
1. Sign up at [SonarCloud.io](https://sonarcloud.io)
2. Create a new project
3. Get your organization key and project key
4. Update the `sonar-project.properties` file

### 2. Kubernetes Cluster Setup

#### Option 1: Local with Colima (macOS)
```bash
# Install Colima
brew install colima

# Start with Kubernetes
colima start --kubernetes

# Verify
kubectl cluster-info
```

#### Option 2: Cloud Provider
- AWS EKS
- Google GKE  
- Azure AKS
- DigitalOcean Kubernetes

### 3. Monitoring Setup

#### Prometheus & Grafana
```bash
# Deploy monitoring stack
kubectl apply -f kubernetes/prometheus.yaml
kubectl apply -f kubernetes/grafana.yaml
kubectl apply -f kubernetes/node-exporter.yaml
kubectl apply -f kubernetes/kube-state-metrics.yaml
```

## Pipeline Stages Overview

### Stage 1: Build 🏗️
- **Frontend Build**: Compiles React application using `pnpm build`
- **Docker Images**: Builds frontend and backend Docker images
- **Artifacts**: Archives build outputs for deployment

**Key Features**:
- Parallel execution for efficiency
- Build artifacts archiving
- Docker image tagging with build numbers

### Stage 2: Test 🧪
- **Unit Tests**: React component tests using Jest
- **Integration Tests**: API endpoint testing
- **Coverage Reports**: Code coverage analysis

**Key Features**:
- Parallel test execution
- Test result publishing
- Coverage reporting with thresholds

### Stage 3: Code Quality 📊
- **SonarQube Analysis**: Code quality, maintainability, and technical debt
- **ESLint**: JavaScript/React code style checking
- **Quality Gates**: Configurable quality thresholds

**Key Features**:
- Quality gate enforcement
- Trend analysis
- Technical debt tracking

### Stage 4: Security 🔒
- **Dependency Scanning**: npm audit for vulnerable packages
- **Container Security**: Trivy scanning for Docker images
- **Vulnerability Assessment**: Critical and high-severity issue detection

**Key Features**:
- Automated vulnerability detection
- Severity-based failure criteria
- Security report generation

### Stage 5: Deploy 🚀
- **Staging Deployment**: Automated deployment to staging environment
- **Docker Registry**: Push images to Docker Hub/registry
- **Smoke Tests**: Basic functionality verification

**Key Features**:
- Blue-green deployment strategy
- Environment-specific configurations
- Automated rollback on failure

### Stage 6: Release 🎯
- **Production Deployment**: Manual approval gate for production
- **Kubernetes Deployment**: Rolling updates with zero downtime
- **Release Tagging**: Git tag creation for versioning

**Key Features**:
- Manual approval workflow
- Production deployment strategies
- Release management integration

### Stage 7: Monitoring 📊
- **Prometheus Alerts**: Application and infrastructure monitoring
- **Grafana Dashboards**: Real-time metrics visualization
- **Health Checks**: Synthetic monitoring setup

**Key Features**:
- Real-time alerting
- Performance monitoring
- Incident response automation

## Running the Pipeline

### 1. Initial Setup
```bash
# Clone the repository
git clone <your-repo-url>
cd healthcare-app

# Update pipeline configuration
# Edit Jenkinsfile to match your environment
```

### 2. Trigger Pipeline
The pipeline can be triggered in several ways:

#### Automatic Triggers
- **Git Push**: Pushes to main/develop branches
- **Pull Request**: PR creation and updates
- **Scheduled**: Daily/weekly builds

#### Manual Triggers
- Jenkins UI: Click "Build Now"
- API Call: Jenkins REST API
- CLI: Jenkins CLI tool

### 3. Monitor Execution
- **Blue Ocean UI**: Modern pipeline visualization
- **Console Output**: Real-time build logs
- **Stage View**: Pipeline stage progression
- **Notifications**: Email/Slack alerts

## Troubleshooting

### Common Issues

#### Docker Build Failures
```bash
# Check Docker daemon
docker info

# Clean up space
docker system prune -f

# Verify Dockerfile syntax
docker build -t test .
```

#### Kubernetes Deployment Issues
```bash
# Check cluster connectivity
kubectl cluster-info

# Verify permissions
kubectl auth can-i create deployments

# Check pod status
kubectl get pods -n healthcare-production
kubectl describe pod <pod-name>
```

#### SonarQube Connection Issues
```bash
# Test connection
curl -u token: http://localhost:9000/api/system/status

# Check Jenkins logs
tail -f /var/log/jenkins/jenkins.log
```

### Performance Optimization

#### Pipeline Speed
- Use parallel stages where possible
- Cache dependencies (npm, Docker layers)
- Optimize Docker images (multi-stage builds)
- Use build agents with sufficient resources

#### Resource Management
- Set appropriate CPU/memory limits
- Use build agent pools
- Clean up artifacts regularly
- Monitor Jenkins disk usage

## Security Best Practices

### Credentials Management
- Use Jenkins credentials store
- Rotate secrets regularly
- Limit credential scope
- Enable audit logging

### Pipeline Security
- Scan for secrets in code
- Use least privilege access
- Validate input parameters
- Enable security scanning

### Infrastructure Security
- Secure Jenkins installation
- Use HTTPS/TLS everywhere
- Regular security updates
- Network segmentation

## Monitoring and Alerting

### Key Metrics to Monitor
- **Build Success Rate**: Percentage of successful builds
- **Build Duration**: Time from start to completion
- **Deployment Frequency**: How often code is deployed
- **Mean Time to Recovery**: Time to fix broken builds

### Alert Configuration
```yaml
# Example Prometheus alerts
- alert: JenkinsBuildFailure
  expr: jenkins_builds_failed_total > 0
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Jenkins build failed"

- alert: LongBuildTime
  expr: jenkins_build_duration_seconds > 1800
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "Build taking longer than 30 minutes"
```

## Maintenance

### Regular Tasks
- **Weekly**: Review build metrics and performance
- **Monthly**: Update plugins and dependencies
- **Quarterly**: Security audit and credential rotation
- **Annually**: Infrastructure and process review

### Backup Strategy
- Jenkins configuration backup
- Build artifacts retention policy
- Database backups (if applicable)
- Kubernetes cluster backup

## Support and Documentation

### Resources
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Blue Ocean Plugin](https://www.jenkins.io/projects/blueocean/)
- [Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)

### Getting Help
- Jenkins Community Forums
- Stack Overflow (jenkins tag)
- GitHub Issues for specific plugins
- Internal DevOps team documentation

---

This comprehensive pipeline provides enterprise-grade CI/CD capabilities with monitoring, security, and deployment automation. The modular design allows for easy customization and extension based on specific requirements.
