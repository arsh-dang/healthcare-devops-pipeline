# Healthcare Application Infrastructure as Code (IaC)

## Overview

This directory contains the complete Terraform configuration for deploying the Healthcare Application to production with enterprise-grade features including monitoring, alerting, backups, and security.

## Architecture

The Terraform configuration deploys:
- **Application Stack**: React frontend, Node.js backend, MongoDB database
- **Monitoring Stack**: Prometheus, Grafana, Alertmanager, Jaeger
- **Security**: Network policies, RBAC, encryption, vulnerability scanning
- **Backup & Recovery**: Automated database backups with retention policies
- **Alerting**: Multi-channel notifications (Email/Slack) with intelligent routing

## Quick Start

### 1. Prerequisites
```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 2. Configure Variables
```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

### 3. Initialize and Deploy
```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var-file="terraform.tfvars"

# Apply the configuration
terraform apply -var-file="terraform.tfvars"
```

## Configuration Files

### Core Files
- `main.tf` - Main infrastructure configuration
- `variables.tf` - Variable definitions (auto-generated)
- `outputs.tf` - Output definitions (auto-generated)
- `terraform.tfvars.example` - Example configuration file

### Key Components

#### 1. Application Deployment
```hcl
# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
  # React application with nginx
}

# Backend StatefulSet
resource "kubernetes_stateful_set" "mongodb" {
  # Node.js backend + MongoDB in single pod
}
```

#### 2. Monitoring Stack
```hcl
# Prometheus Alerting Rules
resource "kubernetes_config_map" "prometheus_alerting_rules" {
  # 15+ alerting rules for comprehensive monitoring
}

# Alertmanager Configuration
resource "kubernetes_config_map" "alertmanager_config" {
  # Multi-channel alerting with email and Slack
}

# Grafana Dashboards
resource "kubernetes_config_map" "grafana_dashboards" {
  # Performance monitoring dashboard
}
```

#### 3. Security & Compliance
```hcl
# Network Policies
resource "kubernetes_network_policy" "default_deny" {
  # Zero-trust security model
}

# RBAC Configuration
resource "kubernetes_cluster_role" "datadog_cluster_agent" {
  # Proper access controls
}
```

#### 4. Backup & Recovery
```hcl
# Database Backup
resource "kubernetes_cron_job_v1" "mongodb_backup" {
  # Daily automated backups
}

# Backup Storage
resource "kubernetes_persistent_volume_claim" "backup_storage" {
  # 50Gi persistent storage for backups
}
```

## Configuration Variables

### Required Variables

#### SMTP Configuration (Email Alerts)
```hcl
smtp_host     = "smtp.gmail.com"
smtp_port     = "587"
smtp_username = "your-smtp-username"
smtp_password = "your-smtp-password"
alert_email_from = "healthcare-alerts@company.com"
```

#### Slack Configuration (Optional)
```hcl
slack_webhook_critical = "https://hooks.slack.com/services/YOUR/WEBHOOK"
slack_webhook_warning  = "https://hooks.slack.com/services/YOUR/WEBHOOK"
slack_channel_critical = "#healthcare-critical"
slack_channel_warning  = "#healthcare-alerts"
```

#### Email Recipients
```hcl
critical_alert_email = "healthcare-critical@company.com"
warning_alert_email  = "healthcare-alerts@company.com"
general_alert_email  = "healthcare-team@company.com"
```

### Optional Variables

#### Resource Scaling
```hcl
replica_count = {
  frontend = 2
  backend  = 3
}
```

#### Security Features
```hcl
enable_encryption = true
enable_network_policies = true
enable_data_transfer_controls = true
```

## Deployment Scenarios

### 1. Development Environment
```bash
terraform apply -var-file="terraform.tfvars" \
  -var="environment=staging" \
  -var="replica_count={frontend=1,backend=1}"
```

### 2. Production Environment
```bash
terraform apply -var-file="terraform.tfvars" \
  -var="environment=production-green" \
  -var="enable_datadog=true"
```

### 3. Blue-Green Deployment
```bash
# Deploy green environment
terraform apply -var-file="terraform.tfvars" \
  -var="environment=production-green"

# Switch traffic (manual step)
kubectl patch ingress healthcare-app-ingress -n healthcare-production-green \
  --type='json' -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/name", "value": "frontend"}]'

# Scale down blue environment
kubectl scale deployment -l environment=production-blue --replicas=0
```

## Monitoring & Alerting

### Alert Categories
- **Critical**: Database down, service unavailable, high error rates
- **Warning**: High resource usage, slow responses, connection issues
- **Info**: Deployments, pod restarts, performance trends

### Alert Channels
- **Email**: Team-specific distribution lists
- **Slack**: Channel-based notifications with rich formatting
- **PagerDuty**: Escalation for critical alerts (configurable)

### Dashboards
- **Performance Dashboard**: Response times, error rates, resource usage
- **Security Dashboard**: Vulnerability status, access patterns
- **Business Dashboard**: User metrics, API usage statistics

## Security Features

### Network Security
- Default deny network policies
- Service-specific ingress rules
- External access restrictions

### Access Control
- RBAC for service accounts
- Least privilege principles
- Audit logging enabled

### Data Protection
- Encryption at rest
- TLS for data in transit
- Backup encryption

## Backup & Recovery

### Automated Backups
- Daily MongoDB backups at 2 AM
- Compressed and integrity-verified
- 7-day retention with cleanup

### Recovery Procedures
```bash
# List available backups
kubectl get pvc -n healthcare-production-green

# Restore from specific backup
kubectl create job restore-job --from=cronjob/mongodb-backup
kubectl logs job/restore-job
```

## Troubleshooting

### Common Issues

1. **Terraform State Lock**
```bash
terraform force-unlock LOCK_ID
```

2. **Resource Quotas Exceeded**
```bash
kubectl describe resourcequotas
kubectl get resourcequotas
```

3. **Network Policy Conflicts**
```bash
kubectl get networkpolicies -A
kubectl describe networkpolicy POLICY_NAME
```

### Debug Commands
```bash
# Check deployment status
kubectl get deployments -n healthcare-production-green
kubectl describe deployment frontend

# Check pod logs
kubectl logs -f deployment/frontend -n healthcare-production-green

# Check service endpoints
kubectl get endpoints -n healthcare-production-green

# Validate configurations
kubectl get configmaps -n healthcare-production-green
kubectl describe configmap alertmanager-config
```

## Maintenance

### Regular Tasks
1. **Weekly**: Review alert history and adjust thresholds
2. **Monthly**: Update Terraform modules and provider versions
3. **Quarterly**: Security assessment and compliance review

### Updates
```bash
# Update Terraform providers
terraform init -upgrade

# Update Kubernetes manifests
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Integration with CI/CD

### Jenkins Pipeline Integration
```groovy
stage('Infrastructure Deployment') {
    steps {
        dir('terraform') {
            sh '''
                terraform init
                terraform plan -var-file="terraform.tfvars" -out=tfplan
                terraform apply tfplan
            '''
        }
    }
}

stage('Health Checks') {
    steps {
        sh '''
            # Wait for services to be ready
            kubectl wait --for=condition=available --timeout=300s deployment/frontend -n healthcare-production-green
            kubectl wait --for=condition=available --timeout=300s statefulset/mongodb-staging -n healthcare-production-green
        '''
    }
}
```

## Cost Optimization

### Resource Rightsizing
- Monitor actual resource usage
- Adjust CPU/memory limits based on metrics
- Use horizontal pod autoscaling

### Storage Optimization
- Implement backup compression
- Regular cleanup of old logs
- Use appropriate storage classes

## Compliance

### GDPR Compliance
- Data processing inventory
- Audit logging enabled
- Data subject rights implementation
- Breach notification procedures

### HIPAA Compliance
- Security controls implemented
- Access logging configured
- Encryption enabled
- Regular security assessments

## Support

### Documentation
- [Terraform Documentation](https://www.terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Prometheus Documentation](https://prometheus.io/docs)

### Getting Help
1. Check Terraform state: `terraform show`
2. Review Kubernetes events: `kubectl get events -n healthcare-production-green`
3. Check pod logs: `kubectl logs -f deployment/frontend -n healthcare-production-green`
4. Validate configurations: `kubectl get configmaps -n healthcare-production-green`

---

*Infrastructure as Code for Healthcare Application*
*Version: 1.0.0*
*Last Updated: $(date)*
