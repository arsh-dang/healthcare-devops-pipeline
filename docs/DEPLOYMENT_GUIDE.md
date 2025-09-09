# Healthcare DevOps Pipeline - Deployment Guide

This guide covers the deployment process, environments, and operational procedures for the Healthcare DevOps Pipeline.

##    Deployment Architecture

### Infrastructure Overview
```
┌─────────────────────────────────────────────────────────────┐
│                     Jenkins CI/CD Pipeline                  │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────────────────┐ │
│  │  Build  │ │  Test   │ │Security │ │  Infrastructure     │ │
│  └─────────┘ └─────────┘ └─────────┘ └─────────────────────┘ │
└─────────────────────────┬───────────────────────────────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │                                   │
   ┌────▼────┐                         ┌────▼────┐
   │ STAGING │                         │  PROD   │
   │ Environment                       │ Environment
   │                                   │
   │ ┌─────────────┐                   │ ┌─────────────┐
   │ │  Frontend   │                   │ │  Frontend   │
   │ │  (React)    │                   │ │  (React)    │
   │ └─────────────┘                   │ └─────────────┘
   │ ┌─────────────┐                   │ ┌─────────────┐
   │ │  Backend    │                   │ │  Backend    │
   │ │  (Node.js)  │                   │ │  (Node.js)  │
   │ └─────────────┘                   │ └─────────────┘
   │ ┌─────────────┐                   │ ┌─────────────┐
   │ │  MongoDB    │                   │ │  MongoDB    │
   │ │             │                   │ │             │
   │ └─────────────┘                   │ └─────────────┘
   └─────────────────┘                   └─────────────────┘
          │                                       │
   ┌──────▼──────┐                         ┌──────▼──────┐
   │ Monitoring  │                         │ Monitoring  │
   │ - Prometheus│                         │ - Prometheus│
   │ - Grafana   │                         │ - Grafana   │
   └─────────────┘                         └─────────────┘
```

### Environment Configuration

#### Staging Environment
- **Purpose**: Pre-production testing and validation
- **Resources**: Minimal resource allocation
- **Access**: Development team and stakeholders
- **Data**: Test datasets and anonymized data

#### Production Environment
- **Purpose**: Live application serving real users
- **Resources**: High availability with auto-scaling
- **Access**: Restricted to operations team
- **Data**: Real healthcare data (HIPAA compliant)

##   Deployment Process

### 1. Automated Deployment Flow

#### Pipeline Trigger
```bash
# Automatic triggers
- Git push to main branch
- Pull request merge
- Manual Jenkins build trigger

# Deployment stages
1. Code checkout and validation
2. Build Docker images
3. Run comprehensive tests
4. Quality and security analysis
5. Deploy infrastructure with Terraform
6. Deploy to staging environment
7. Manual approval gate
8. Blue-green production deployment
```

### 2. Staging Deployment

#### Automatic Staging Deployment
```yaml
# Kubernetes staging configuration
apiVersion: apps/v1
kind: Deployment
metadata:
  name: healthcare-frontend-staging
  namespace: healthcare-staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: healthcare-frontend
      environment: staging
  template:
    metadata:
      labels:
        app: healthcare-frontend
        environment: staging
    spec:
      containers:
      - name: frontend
        image: yourusername/healthcare-app:frontend-latest
        ports:
        - containerPort: 80
        env:
        - name: REACT_APP_API_URL
          value: "http://backend-service:5000"
        - name: NODE_ENV
          value: "staging"
```

#### Staging Validation
```bash
# Health check endpoints
curl http://staging.healthcare.local/health
curl http://staging.healthcare.local/api/health

# Database connectivity test
kubectl exec -it mongodb-staging-0 -n healthcare-staging -- mongosh --eval "db.runCommand('ping')"

# Load testing (basic)
ab -n 100 -c 10 http://staging.healthcare.local/
```

### 3. Production Deployment

#### Blue-Green Deployment Strategy
```bash
# Current deployment pattern
┌─────────────┐     ┌─────────────┐
│    BLUE     │     │    GREEN    │
│ (Current)   │     │   (New)     │
│             │     │             │
│ v1.0.0      │ ──▶ │ v1.1.0      │
│             │     │             │
└─────────────┘     └─────────────┘
       │                   │
       └─────────┬─────────┘
                 │
        ┌────────▼────────┐
        │  Load Balancer  │
        │   (Ingress)     │
        └─────────────────┘
```

#### Manual Approval Process
```groovy
// Jenkins pipeline approval
stage('Production Approval') {
    steps {
        script {
            input message: 'Deploy to Production?', 
                  ok: 'Deploy',
                  parameters: [
                      booleanParam(
                          defaultValue: false,
                          description: 'Confirm production deployment',
                          name: 'CONFIRM_DEPLOY'
                      )
                  ]
        }
    }
}
```

#### Production Deployment Validation
```bash
# Comprehensive health checks
1. Application health endpoints
2. Database connectivity
3. External API integrations
4. Performance baseline validation
5. Security scan validation
6. Monitoring system alerts

# Rollback capability
kubectl rollout undo deployment/healthcare-frontend -n healthcare-production
kubectl rollout undo deployment/healthcare-backend -n healthcare-production
```

##   Infrastructure as Code

### Terraform Configuration

#### Main Infrastructure
```hcl
# terraform/main.tf
resource "kubernetes_namespace" "healthcare" {
  metadata {
    name = var.namespace
    labels = {
      environment = var.environment
      app         = "healthcare"
    }
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "healthcare-frontend"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }
  
  spec {
    replicas = var.replica_count.frontend
    
    selector {
      match_labels = {
        app = "healthcare-frontend"
      }
    }
    
    template {
      metadata {
        labels = {
          app = "healthcare-frontend"
        }
      }
      
      spec {
        container {
          name  = "frontend"
          image = "${var.docker_registry}/${var.docker_repo}:frontend-${var.build_number}"
          
          port {
            container_port = 80
          }
          
          env {
            name  = "REACT_APP_API_URL"
            value = "http://${kubernetes_service.backend.metadata[0].name}:5000"
          }
          
          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          
          readiness_probe {
            http_get {
              path = "/ready"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}
```

#### Monitoring Integration
```hcl
# terraform/monitoring.tf
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  
  data = {
    "prometheus.yml" = file("${path.module}/configs/prometheus.yml")
  }
}

resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
  
  spec {
    replicas = 1
    
    selector {
      match_labels = {
        component = "prometheus"
      }
    }
    
    template {
      metadata {
        labels = {
          component = "prometheus"
        }
      }
      
      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:latest"
          
          port {
            container_port = 9090
          }
          
          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }
        }
        
        volume {
          name = "prometheus-config"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }
      }
    }
  }
}
```

### Deployment Commands

#### Terraform Deployment
```bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan -var="environment=production" -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Verify deployment
terraform output
```

#### Kubernetes Verification
```bash
# Check deployment status
kubectl get deployments -n healthcare-production
kubectl get pods -n healthcare-production
kubectl get services -n healthcare-production

# Check application health
kubectl exec -it deployment/healthcare-frontend -n healthcare-production -- curl http://localhost/health
```

##   Monitoring and Observability

### Prometheus Configuration
```yaml
# configs/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'healthcare-frontend'
    static_configs:
      - targets: ['healthcare-frontend:80']
    metrics_path: '/metrics'
    
  - job_name: 'healthcare-backend'
    static_configs:
      - targets: ['healthcare-backend:5000']
    metrics_path: '/api/metrics'
    
  - job_name: 'kubernetes-pods'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

### Grafana Dashboards
```json
{
  "dashboard": {
    "title": "Healthcare Application Metrics",
    "panels": [
      {
        "title": "Application Health",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"healthcare-frontend\"}",
            "legendFormat": "Frontend Status"
          },
          {
            "expr": "up{job=\"healthcare-backend\"}",
            "legendFormat": "Backend Status"
          }
        ]
      },
      {
        "title": "Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "http_request_duration_seconds{job=\"healthcare-backend\"}",
            "legendFormat": "Response Time"
          }
        ]
      }
    ]
  }
}
```

### Alert Rules
```yaml
# configs/alert-rules.yml
groups:
  - name: healthcare-alerts
    rules:
      - alert: ApplicationDown
        expr: up{job=~"healthcare-.*"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Healthcare application is down"
          description: "{{ $labels.job }} has been down for more than 1 minute"
          
      - alert: HighResponseTime
        expr: http_request_duration_seconds{job="healthcare-backend"} > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
          description: "Backend response time is above 2 seconds for 5 minutes"
```

##   Security Considerations

### Deployment Security
```bash
# Security scanning before deployment
1. Container image vulnerability scanning (Trivy)
2. Source code security analysis (TruffleHog)
3. Dependency vulnerability checking
4. Infrastructure security validation

# Runtime security
1. Pod security policies
2. Network policies
3. RBAC configuration
4. Secret management with Kubernetes secrets
```

### HIPAA Compliance
```yaml
# Security configurations for healthcare data
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-credentials
  namespace: healthcare-production
type: Opaque
data:
  username: <base64-encoded-username>
  password: <base64-encoded-password>

---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: healthcare-network-policy
  namespace: healthcare-production
spec:
  podSelector:
    matchLabels:
      app: healthcare
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: healthcare
```

## Rollback Procedures

### Automatic Rollback
```groovy
// Jenkins pipeline rollback
post {
    failure {
        script {
            if (env.STAGE_NAME == 'Release to Production') {
                echo "Production deployment failed - initiating rollback"
                sh '''
                    kubectl rollout undo deployment/healthcare-frontend -n healthcare-production
                    kubectl rollout undo deployment/healthcare-backend -n healthcare-production
                    kubectl rollout status deployment/healthcare-frontend -n healthcare-production
                    kubectl rollout status deployment/healthcare-backend -n healthcare-production
                '''
            }
        }
    }
}
```

### Manual Rollback
```bash
# Check deployment history
kubectl rollout history deployment/healthcare-frontend -n healthcare-production

# Rollback to previous version
kubectl rollout undo deployment/healthcare-frontend -n healthcare-production

# Rollback to specific revision
kubectl rollout undo deployment/healthcare-frontend -n healthcare-production --to-revision=2

# Verify rollback status
kubectl rollout status deployment/healthcare-frontend -n healthcare-production
```

##   Performance Optimization

### Resource Optimization
```yaml
# Resource requests and limits
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"

# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: healthcare-frontend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: healthcare-frontend
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Database Optimization
```javascript
// MongoDB optimization
db.appointments.createIndex({ "patient.email": 1 })
db.appointments.createIndex({ "doctor.id": 1, "date": 1 })
db.appointments.createIndex({ "status": 1, "createdAt": -1 })

// Connection pooling
const mongoOptions = {
  maxPoolSize: 10,
  minPoolSize: 2,
  maxIdleTimeMS: 30000,
  serverSelectionTimeoutMS: 5000,
}
```

---

**Next Steps**: Review the [Monitoring Guide](./MONITORING_GUIDE.md) for detailed observability setup.
