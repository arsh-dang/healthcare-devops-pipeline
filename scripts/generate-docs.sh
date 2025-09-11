#!/bin/bash

# Enhanced Documentation Generation Script
# Generates comprehensive API documentation and project docs

set -e

# Configuration
PROJECT_NAME="Healthcare DevOps Pipeline"
VERSION=${1:-"1.0.0"}
OUTPUT_DIR="docs/generated"
API_DOCS_DIR="$OUTPUT_DIR/api"
ARCHITECTURE_DOCS_DIR="$OUTPUT_DIR/architecture"
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

log_docs() {
    echo -e "${PURPLE}[DOCS]${NC} $1"
}

# Create output directories
mkdir -p $API_DOCS_DIR $ARCHITECTURE_DOCS_DIR

log_docs "Starting Enhanced Documentation Generation"
log_docs "=========================================="
log_info "Project: $PROJECT_NAME"
log_info "Version: $VERSION"
log_info "Output Directory: $OUTPUT_DIR"

# Generate API Documentation with OpenAPI/Swagger
generate_api_docs() {
    log_docs "Generating API Documentation..."

    # Create OpenAPI specification
    cat > $API_DOCS_DIR/openapi-spec.yaml << 'EOF'
openapi: 3.0.3
info:
  title: Healthcare Application API
  description: |
    Comprehensive API for healthcare management system with DevOps pipeline integration.

    ## Features
    - Patient management
    - Appointment scheduling
    - Doctor management
    - Medical records
    - Authentication & authorization
    - Real-time notifications
  version: '${VERSION}'
  contact:
    name: Healthcare DevOps Team
    email: devops@healthcare-app.com
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT

servers:
  - url: http://localhost:5001/api/v1
    description: Development server
  - url: https://api.healthcare-app.com/api/v1
    description: Production server

security:
  - bearerAuth: []

paths:
  /health:
    get:
      summary: Health check endpoint
      description: Check if the API is running and healthy
      tags:
        - System
      responses:
        '200':
          description: API is healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: "healthy"
                  timestamp:
                    type: string
                    format: date-time
                  version:
                    type: string
                    example: "1.0.0"

  /auth/login:
    post:
      summary: User authentication
      description: Authenticate user and return JWT token
      tags:
        - Authentication
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - email
                - password
              properties:
                email:
                  type: string
                  format: email
                  example: "doctor@hospital.com"
                password:
                  type: string
                  format: password
                  example: "securepassword123"
      responses:
        '200':
          description: Authentication successful
          content:
            application/json:
              schema:
                type: object
                properties:
                  token:
                    type: string
                    description: JWT access token
                  user:
                    type: object
                    properties:
                      id:
                        type: string
                      email:
                        type: string
                      role:
                        type: string
                        enum: [admin, doctor, nurse, patient]
        '401':
          description: Invalid credentials

  /patients:
    get:
      summary: Get all patients
      description: Retrieve list of all patients (admin/doctor only)
      tags:
        - Patients
      security:
        - bearerAuth: []
      parameters:
        - name: page
          in: query
          schema:
            type: integer
            minimum: 1
            default: 1
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
        - name: search
          in: query
          schema:
            type: string
      responses:
        '200':
          description: List of patients
          content:
            application/json:
              schema:
                type: object
                properties:
                  patients:
                    type: array
                    items:
                      $ref: '#/components/schemas/Patient'
                  pagination:
                    $ref: '#/components/schemas/Pagination'

    post:
      summary: Create new patient
      description: Register a new patient in the system
      tags:
        - Patients
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PatientInput'
      responses:
        '201':
          description: Patient created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Patient'

  /patients/{id}:
    get:
      summary: Get patient by ID
      description: Retrieve detailed information about a specific patient
      tags:
        - Patients
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '200':
          description: Patient details
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Patient'
        '404':
          description: Patient not found

    put:
      summary: Update patient
      description: Update patient information
      tags:
        - Patients
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PatientInput'
      responses:
        '200':
          description: Patient updated successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Patient'

    delete:
      summary: Delete patient
      description: Remove patient from the system
      tags:
        - Patients
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '204':
          description: Patient deleted successfully
        '404':
          description: Patient not found

  /appointments:
    get:
      summary: Get appointments
      description: Retrieve appointments with optional filtering
      tags:
        - Appointments
      security:
        - bearerAuth: []
      parameters:
        - name: date
          in: query
          schema:
            type: string
            format: date
        - name: doctorId
          in: query
          schema:
            type: string
        - name: patientId
          in: query
          schema:
            type: string
        - name: status
          in: query
          schema:
            type: string
            enum: [scheduled, confirmed, completed, cancelled]
      responses:
        '200':
          description: List of appointments
          content:
            application/json:
              schema:
                type: object
                properties:
                  appointments:
                    type: array
                    items:
                      $ref: '#/components/schemas/Appointment'

    post:
      summary: Create appointment
      description: Schedule a new appointment
      tags:
        - Appointments
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/AppointmentInput'
      responses:
        '201':
          description: Appointment created successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Appointment'

  /doctors:
    get:
      summary: Get all doctors
      description: Retrieve list of all doctors
      tags:
        - Doctors
      security:
        - bearerAuth: []
      responses:
        '200':
          description: List of doctors
          content:
            application/json:
              schema:
                type: object
                properties:
                  doctors:
                    type: array
                    items:
                      $ref: '#/components/schemas/Doctor'

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    Patient:
      type: object
      properties:
        id:
          type: string
          example: "507f1f77bcf86cd799439011"
        firstName:
          type: string
          example: "John"
        lastName:
          type: string
          example: "Doe"
        email:
          type: string
          format: email
          example: "john.doe@email.com"
        phone:
          type: string
          example: "+1-555-0123"
        dateOfBirth:
          type: string
          format: date
          example: "1980-01-15"
        address:
          type: object
          properties:
            street:
              type: string
            city:
              type: string
            state:
              type: string
            zipCode:
              type: string
        medicalRecordNumber:
          type: string
          example: "MRN123456"
        emergencyContact:
          type: object
          properties:
            name:
              type: string
            phone:
              type: string
            relationship:
              type: string
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    PatientInput:
      type: object
      required:
        - firstName
        - lastName
        - email
        - dateOfBirth
      properties:
        firstName:
          type: string
        lastName:
          type: string
        email:
          type: string
          format: email
        phone:
          type: string
        dateOfBirth:
          type: string
          format: date
        address:
          type: object
          properties:
            street:
              type: string
            city:
              type: string
            state:
              type: string
            zipCode:
              type: string
        emergencyContact:
          type: object
          properties:
            name:
              type: string
            phone:
              type: string
            relationship:
              type: string

    Appointment:
      type: object
      properties:
        id:
          type: string
        patientId:
          type: string
        doctorId:
          type: string
        date:
          type: string
          format: date
        time:
          type: string
          example: "10:00"
        duration:
          type: integer
          example: 30
        type:
          type: string
          enum: [consultation, follow-up, procedure, emergency]
        status:
          type: string
          enum: [scheduled, confirmed, in-progress, completed, cancelled, no-show]
        notes:
          type: string
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    AppointmentInput:
      type: object
      required:
        - patientId
        - doctorId
        - date
        - time
        - type
      properties:
        patientId:
          type: string
        doctorId:
          type: string
        date:
          type: string
          format: date
        time:
          type: string
        duration:
          type: integer
          default: 30
        type:
          type: string
          enum: [consultation, follow-up, procedure, emergency]
        notes:
          type: string

    Doctor:
      type: object
      properties:
        id:
          type: string
        firstName:
          type: string
        lastName:
          type: string
        email:
          type: string
          format: email
        phone:
          type: string
        specialty:
          type: string
          example: "Cardiology"
        licenseNumber:
          type: string
        department:
          type: string
        isActive:
          type: boolean
          default: true
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    Pagination:
      type: object
      properties:
        page:
          type: integer
        limit:
          type: integer
        total:
          type: integer
        totalPages:
          type: integer

  responses:
    UnauthorizedError:
      description: Authentication information is missing or invalid
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
                example: "Unauthorized"
              message:
                type: string
                example: "Invalid or missing authentication token"

    NotFoundError:
      description: The specified resource was not found
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
                example: "Not Found"
              message:
                type: string
                example: "Resource not found"

    ValidationError:
      description: Input validation failed
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: string
                example: "Validation Error"
              message:
                type: string
              details:
                type: array
                items:
                  type: object
                  properties:
                    field:
                      type: string
                    message:
                      type: string
EOF

    log_success "OpenAPI specification generated"
}

# Generate JSDoc documentation for backend
generate_jsdoc() {
    log_docs "Generating JSDoc documentation..."

    if command -v npx &> /dev/null; then
        # Create JSDoc configuration
        cat > jsdoc-config.json << 'EOF'
{
  "source": {
    "include": ["server/", "src/"],
    "includePattern": "\\.(js|jsx|ts|tsx)$",
    "exclude": ["node_modules/", "build/", "coverage/"]
  },
  "opts": {
    "destination": "'$API_DOCS_DIR'/jsdoc/",
    "recurse": true,
    "readme": "README.md"
  },
  "plugins": ["plugins/markdown"],
  "templates": {
    "default": {
      "outputSourceFiles": true
    }
  }
}
EOF

        # Generate JSDoc
        npx jsdoc -c jsdoc-config.json

        # Clean up config file
        rm jsdoc-config.json

        log_success "JSDoc documentation generated"
    else
        log_warning "npx not available - skipping JSDoc generation"
    fi
}

# Generate architecture documentation
generate_architecture_docs() {
    log_docs "Generating architecture documentation..."

    # System Architecture Overview
    cat > $ARCHITECTURE_DOCS_DIR/system-overview.md << EOF
# System Architecture Overview

## Healthcare DevOps Pipeline Architecture

### High-Level Architecture

\`\`\`mermaid
graph TB
    subgraph "CI/CD Pipeline"
        A[Jenkins] --> B[Build Stage]
        B --> C[Test Stage]
        C --> D[Code Quality]
        D --> E[Security Scan]
        E --> F[Deploy Stage]
        F --> G[Canary Release]
        G --> H[Blue-Green Deploy]
        H --> I[Production Release]
    end

    subgraph "Application Stack"
        J[React Frontend] --> K[Node.js API]
        K --> L[MongoDB]
        K --> M[Redis Cache]
    end

    subgraph "Infrastructure"
        N[Docker] --> O[Kubernetes]
        O --> P[Terraform]
        P --> Q[AWS/GCP/Azure]
    end

    subgraph "Monitoring & Observability"
        R[Prometheus] --> S[Grafana]
        R --> T[AlertManager]
        U[Datadog] --> V[APM & Logs]
        W[Jaeger] --> X[Distributed Tracing]
    end

    A --> J
    I --> N
    N --> R
    N --> U
    N --> W
\`\`\`

### Component Details

#### Frontend Layer
- **Technology**: React 18 with TypeScript
- **Features**:
  - Responsive UI with Material-UI
  - Real-time updates with WebSocket
  - PWA capabilities
  - Accessibility compliance (WCAG 2.1 AA)

#### Backend Layer
- **Technology**: Node.js with Express.js
- **Features**:
  - RESTful API design
  - JWT authentication
  - Rate limiting and security middleware
  - Database connection pooling
  - Background job processing

#### Data Layer
- **Primary Database**: MongoDB
- **Caching**: Redis
- **Features**:
  - Data encryption at rest
  - Automated backups
  - Read/write splitting
  - Connection pooling

#### Infrastructure Layer
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **Infrastructure as Code**: Terraform
- **Cloud Providers**: Multi-cloud support

#### DevOps Pipeline
- **CI/CD**: Jenkins with declarative pipelines
- **Version Control**: Git with GitFlow
- **Artifact Repository**: Docker Registry
- **Configuration Management**: Kubernetes ConfigMaps/Secrets

### Security Architecture

#### Authentication & Authorization
- JWT-based authentication
- Role-based access control (RBAC)
- Multi-factor authentication (MFA)
- Session management with Redis

#### Data Protection
- TLS 1.3 encryption in transit
- AES-256 encryption at rest
- Database field-level encryption
- Secure key management

#### Network Security
- VPC isolation
- Security groups and network ACLs
- Web Application Firewall (WAF)
- DDoS protection

#### Compliance
- HIPAA compliance for healthcare data
- SOC 2 Type II compliance
- GDPR compliance for EU data
- Regular security audits

### Performance Characteristics

#### Response Times
- API endpoints: <200ms average
- Page load: <2s
- Database queries: <50ms

#### Scalability
- Horizontal pod scaling
- Database read replicas
- CDN for static assets
- Auto-scaling based on metrics

#### Availability
- 99.9% uptime SLA
- Multi-zone deployment
- Automated failover
- Disaster recovery procedures

### Monitoring & Alerting

#### Application Metrics
- Request/response metrics
- Error rates and types
- Database connection pools
- Cache hit/miss ratios

#### Infrastructure Metrics
- CPU and memory usage
- Network I/O
- Disk I/O and space
- Container health

#### Business Metrics
- User registration rates
- Appointment booking rates
- System usage patterns
- Performance KPIs

### Deployment Strategy

#### Development Environment
- Local development with Docker Compose
- Hot reloading for frontend/backend
- Automated testing on commits

#### Staging Environment
- Full infrastructure deployment
- Integration testing
- Performance testing
- Security scanning

#### Production Environment
- Blue-green deployments
- Canary releases for high-risk changes
- Automated rollback capabilities
- Comprehensive monitoring

### Disaster Recovery

#### Backup Strategy
- Database backups every 6 hours
- Configuration backups daily
- Application artifacts versioning
- Infrastructure state backups

#### Recovery Procedures
- RTO: 4 hours
- RPO: 1 hour
- Automated failover to secondary region
- Manual intervention for critical incidents

#### Testing
- Regular disaster recovery drills
- Automated failover testing
- Data restoration testing
- Performance validation post-recovery
EOF

    # Deployment Architecture
    cat > $ARCHITECTURE_DOCS_DIR/deployment-architecture.md << EOF
# Deployment Architecture

## Blue-Green Deployment Strategy

### Overview
Blue-green deployment is a technique that reduces downtime and risk by running two identical production environments called Blue and Green.

### Process Flow

\`\`\`mermaid
sequenceDiagram
    participant User
    participant LoadBalancer
    participant Blue
    participant Green
    participant Jenkins

    Note over Jenkins: Deployment Process
    Jenkins->>Green: Deploy new version
    Jenkins->>Green: Run health checks
    Jenkins->>LoadBalancer: Switch traffic to Green
    LoadBalancer->>Green: Route all traffic
    Jenkins->>Blue: Monitor for issues
    Jenkins->>Blue: Scale down Blue environment
\`\`\`

### Benefits
- **Zero Downtime**: Traffic switching is instantaneous
- **Instant Rollback**: Switch back to blue if issues detected
- **Risk Reduction**: Test in production-like environment
- **Gradual Rollout**: Can implement canary releases

## Canary Deployment Strategy

### Overview
Canary deployment gradually rolls out changes to a small subset of users before full release.

### Process Flow

\`\`\`mermaid
sequenceDiagram
    participant User
    participant LoadBalancer
    participant Stable
    participant Canary
    participant Monitoring

    User->>LoadBalancer: Request
    LoadBalancer->>Stable: 90% traffic
    LoadBalancer->>Canary: 10% traffic
    Monitoring->>Canary: Health metrics
    Monitoring->>LoadBalancer: Performance analysis
    LoadBalancer->>Canary: Increase traffic (20%)
    LoadBalancer->>Canary: Full traffic (100%)
\`\`\`

### Benefits
- **Risk Mitigation**: Test with real users
- **Performance Validation**: Monitor impact on real traffic
- **Gradual Rollout**: Control exposure to new features
- **Automated Rollback**: Based on metrics thresholds

## Infrastructure Components

### Kubernetes Architecture

\`\`\`yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: healthcare-app
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: frontend
        image: healthcare-app-frontend:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
      - name: backend
        image: healthcare-app-backend:latest
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 1000m
            memory: 1Gi
\`\`\`

### Service Mesh Configuration

\`\`\`yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: healthcare-app
spec:
  http:
  - match:
    - headers:
        x-canary:
          exact: "true"
    route:
    - destination:
        host: healthcare-app-canary
  - route:
    - destination:
        host: healthcare-app-stable
      weight: 90
    - destination:
        host: healthcare-app-canary
      weight: 10
\`\`\`

### Monitoring Stack

\`\`\`yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: healthcare-app-alerts
spec:
  groups:
  - name: healthcare-app
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ \$value }}% which is above 5%"
\`\`\`
EOF

    log_success "Architecture documentation generated"
}

# Generate deployment documentation
generate_deployment_docs() {
    log_docs "Generating deployment documentation..."

    cat > $OUTPUT_DIR/deployment-guide.md << EOF
# Deployment Guide

## Prerequisites

### System Requirements
- Kubernetes cluster (v1.19+)
- kubectl configured
- Docker registry access
- Terraform (v1.0+)
- Helm (v3.0+)

### Required Tools
\`\`\`bash
# Install required tools
brew install kubectl terraform helm
# or
apt-get install kubectl terraform helm
\`\`\`

## Quick Start Deployment

### 1. Clone Repository
\`\`\`bash
git clone https://github.com/arsh-dang/healthcare-devops-pipeline.git
cd healthcare-devops-pipeline
\`\`\`

### 2. Configure Environment
\`\`\`bash
# Copy environment configuration
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit configuration
vim terraform/terraform.tfvars
\`\`\`

### 3. Deploy Infrastructure
\`\`\`bash
# Initialize Terraform
cd terraform
terraform init

# Plan deployment
terraform plan

# Apply configuration
terraform apply
\`\`\`

### 4. Deploy Application
\`\`\`bash
# Build and push Docker images
./scripts/build-and-push.sh

# Deploy to Kubernetes
kubectl apply -f k8s/
\`\`\`

## Environment Configuration

### Staging Environment
\`\`\`hcl
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
\`\`\`

### Production Environment
\`\`\`hcl
environment = "production"

# Application settings
app_version = "v1.2.3"
frontend_image = "healthcare-app-frontend:v1.2.3"
backend_image = "healthcare-app-backend:v1.2.3"

# Database settings
mongodb_root_password = "\${var.mongodb_production_password}"

# Monitoring settings
enable_monitoring = true
enable_datadog = true
datadog_api_key = "\${var.datadog_api_key}"
\`\`\`

## Blue-Green Deployment

### Manual Blue-Green Deployment
\`\`\`bash
# Deploy to green environment
kubectl set image deployment/healthcare-app-green \\
  frontend=healthcare-app-frontend:v1.2.3 \\
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
\`\`\`

### Automated Blue-Green Deployment
\`\`\`bash
# Use the production deployment script
./scripts/production-deploy.sh production v1.2.3
\`\`\`

## Monitoring Setup

### Grafana Access
\`\`\`bash
# Port forward Grafana
kubectl port-forward svc/grafana 3000:3000

# Access at: http://localhost:3000
# Default credentials: admin/admin
\`\`\`

### Prometheus Access
\`\`\`bash
# Port forward Prometheus
kubectl port-forward svc/prometheus 9090:9090

# Access at: http://localhost:9090
\`\`\`

### Datadog Integration
\`\`\`bash
# Set Datadog API key
export DATADOG_API_KEY=your-api-key

# Deploy Datadog agent
helm repo add datadog https://helm.datadoghq.com
helm install datadog datadog/datadog \\
  --set datadog.apiKey=\$DATADOG_API_KEY \\
  --set datadog.appKey=\$DATADOG_APP_KEY
\`\`\`

## Troubleshooting

### Common Issues

#### Pods Not Starting
\`\`\`bash
# Check pod status
kubectl get pods

# Check pod logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
\`\`\`

#### Database Connection Issues
\`\`\`bash
# Check MongoDB pod
kubectl get pods -l app=mongodb

# Check MongoDB logs
kubectl logs -l app=mongodb

# Test database connection
kubectl exec -it <mongodb-pod> -- mongo --eval "db.runCommand('ping')"
\`\`\`

#### Service Mesh Issues
\`\`\`bash
# Check Istio sidecar injection
kubectl get pods -o jsonpath='{.items[*].spec.containers[*].name}'

# Check Istio configuration
kubectl get virtualservice, destinationrule, gateway
\`\`\`

### Health Checks

#### Application Health
\`\`\`bash
# Frontend health
curl http://localhost:3001

# Backend health
curl http://localhost:5001/health

# Database health
curl http://localhost:5001/health/database
\`\`\`

#### Infrastructure Health
\`\`\`bash
# Kubernetes nodes
kubectl get nodes

# Cluster resources
kubectl top nodes
kubectl top pods

# Storage
kubectl get pvc
\`\`\`

## Backup and Recovery

### Database Backup
\`\`\`bash
# Create database backup
kubectl exec -it <mongodb-pod> -- mongodump --out /backup/\$(date +%Y%m%d_%H%M%S)

# Copy backup to local
kubectl cp <mongodb-pod>:/backup /local/backup/path
\`\`\`

### Configuration Backup
\`\`\`bash
# Backup Kubernetes resources
kubectl get all -o yaml > k8s-backup.yaml

# Backup Terraform state
cp terraform/terraform.tfstate terraform/terraform.tfstate.backup
\`\`\`

### Recovery Procedures
\`\`\`bash
# Restore from backup
kubectl apply -f k8s-backup.yaml

# Restore database
kubectl cp backup.tar.gz <mongodb-pod>:/tmp/
kubectl exec -it <mongodb-pod> -- tar xzf /tmp/backup.tar.gz -C /
kubectl exec -it <mongodb-pod> -- mongorestore /backup
\`\`\`
EOF

    log_success "Deployment documentation generated"
}

# Generate comprehensive README
generate_readme() {
    log_docs "Generating comprehensive README..."

    cat > $OUTPUT_DIR/README.md << EOF
# Healthcare DevOps Pipeline

[![Build Status](https://jenkins.healthcare-app.com/buildStatus/icon?job=healthcare-devops-pipeline)](https://jenkins.healthcare-app.com/job/healthcare-devops-pipeline/)
[![Quality Gate](https://sonarcloud.io/api/project_badges/measure?project=healthcare-devops-pipeline&metric=alert_status)](https://sonarcloud.io/dashboard?id=healthcare-devops-pipeline)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=healthcare-devops-pipeline&metric=security_rating)](https://sonarcloud.io/dashboard?id=healthcare-devops-pipeline)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=healthcare-devops-pipeline&metric=coverage)](https://sonarcloud.io/dashboard?id=healthcare-devops-pipeline)

A comprehensive healthcare management system with enterprise-grade DevOps pipeline, implementing all 7 stages of CI/CD with advanced deployment strategies and monitoring.

## 🚀 Features

### Core Functionality
- **Patient Management**: Complete patient lifecycle management
- **Appointment Scheduling**: Intelligent scheduling with conflict resolution
- **Doctor Management**: Staff scheduling and availability management
- **Medical Records**: Secure electronic health records
- **Real-time Notifications**: WebSocket-based notifications
- **Authentication & Authorization**: JWT-based auth with role-based access

### DevOps Pipeline
- **7-Stage CI/CD**: Complete automation from code to production
- **Blue-Green Deployments**: Zero-downtime releases
- **Canary Releases**: Gradual rollout with automated rollback
- **Advanced Monitoring**: Prometheus, Grafana, Datadog integration
- **Security Scanning**: Multi-layer security analysis
- **Load Testing**: Artillery-based performance testing
- **Chaos Engineering**: Automated resilience testing

### Enterprise Features
- **Multi-environment**: Development, staging, production
- **Infrastructure as Code**: Terraform-based infrastructure
- **Container Orchestration**: Kubernetes with service mesh
- **Monitoring & Alerting**: Comprehensive observability stack
- **Backup & Recovery**: Automated disaster recovery
- **Compliance**: HIPAA, SOC 2, GDPR compliance ready

## 🏗️ Architecture

### System Overview
\`\`\`mermaid
graph TB
    A[React Frontend] --> B[Node.js API]
    B --> C[MongoDB]
    B --> D[Redis Cache]
    B --> E[External APIs]

    F[Docker] --> G[Kubernetes]
    G --> H[Terraform]
    H --> I[Cloud Provider]

    J[Prometheus] --> K[Grafana]
    J --> L[AlertManager]
    M[Datadog] --> N[APM & Logs]
    O[Jaeger] --> P[Distributed Tracing]
\`\`\`

### Technology Stack

#### Frontend
- **React 18** with TypeScript
- **Material-UI** for components
- **Redux Toolkit** for state management
- **React Router** for navigation
- **Axios** for API calls
- **Socket.io** for real-time features

#### Backend
- **Node.js** with Express.js
- **TypeScript** for type safety
- **MongoDB** with Mongoose ODM
- **Redis** for caching and sessions
- **JWT** for authentication
- **bcrypt** for password hashing

#### DevOps & Infrastructure
- **Docker** for containerization
- **Kubernetes** for orchestration
- **Terraform** for infrastructure as code
- **Jenkins** for CI/CD pipeline
- **Helm** for package management
- **Istio** for service mesh

#### Monitoring & Security
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Datadog** for APM and logs
- **Jaeger** for distributed tracing
- **SonarQube** for code quality
- **OWASP ZAP** for security testing

## 📋 Prerequisites

### System Requirements
- **Node.js**: 18.0.0 or higher
- **Docker**: 20.10.0 or higher
- **Kubernetes**: 1.19.0 or higher
- **Terraform**: 1.0.0 or higher
- **kubectl**: Configured for your cluster

### Development Setup
\`\`\`bash
# Clone repository
git clone https://github.com/arsh-dang/healthcare-devops-pipeline.git
cd healthcare-devops-pipeline

# Install dependencies
npm install

# Start development environment
docker-compose up -d

# Run application
npm run dev
\`\`\`

## 🚀 Deployment

### Quick Start
\`\`\`bash
# Deploy to staging
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh production
\`\`\`

### Blue-Green Deployment
\`\`\`bash
# Deploy new version to green environment
./scripts/production-deploy.sh production v1.2.3

# Verify deployment
curl https://api.healthcare-app.com/health
\`\`\`

### Canary Deployment
\`\`\`bash
# Start canary deployment
kubectl apply -f k8s/canary/

# Monitor canary metrics
kubectl get pods -l environment=canary
\`\`\`

## 📊 Monitoring

### Access Monitoring Interfaces

#### Grafana Dashboards
\`\`\`bash
kubectl port-forward svc/grafana 3000:3000
# Access: http://localhost:3000
\`\`\`

#### Prometheus Metrics
\`\`\`bash
kubectl port-forward svc/prometheus 9090:9090
# Access: http://localhost:9090
\`\`\`

#### Jaeger Tracing
\`\`\`bash
kubectl port-forward svc/jaeger 16686:16686
# Access: http://localhost:16686
\`\`\`

### Key Metrics
- **Application Performance**: Response times, error rates, throughput
- **Infrastructure Health**: CPU, memory, disk usage
- **Business Metrics**: User registrations, appointment bookings
- **Security Events**: Failed authentication attempts, suspicious activities

## 🧪 Testing

### Run Test Suite
\`\`\`bash
# Unit tests
npm run test:unit

# Integration tests
npm run test:integration

# End-to-end tests
npm run test:e2e

# Load testing
./scripts/load-testing.sh

# Chaos engineering
./scripts/chaos-engineering.sh
\`\`\`

### Test Coverage
- **Unit Tests**: 90%+ coverage
- **Integration Tests**: API endpoints and database operations
- **E2E Tests**: Complete user workflows
- **Performance Tests**: Load testing with Artillery
- **Security Tests**: Automated vulnerability scanning

## 🔒 Security

### Security Features
- **Authentication**: JWT with refresh tokens
- **Authorization**: Role-based access control
- **Data Encryption**: TLS 1.3, AES-256 encryption
- **Security Headers**: OWASP recommended headers
- **Rate Limiting**: API rate limiting and DDoS protection
- **Audit Logging**: Comprehensive security event logging

### Security Scanning
\`\`\`bash
# Run security scan
./scripts/advanced-security-scan.sh

# View security reports
open security-reports/
\`\`\`

## 📚 API Documentation

### OpenAPI Specification
The API is fully documented using OpenAPI 3.0 specification.

\`\`\`bash
# Generate API docs
./scripts/generate-docs.sh

# View API documentation
open docs/generated/api/index.html
\`\`\`

### Key Endpoints

#### Authentication
- \`POST /api/auth/login\` - User login
- \`POST /api/auth/register\` - User registration
- \`POST /api/auth/refresh\` - Refresh access token

#### Patients
- \`GET /api/patients\` - List patients
- \`POST /api/patients\` - Create patient
- \`GET /api/patients/:id\` - Get patient details
- \`PUT /api/patients/:id\` - Update patient
- \`DELETE /api/patients/:id\` - Delete patient

#### Appointments
- \`GET /api/appointments\` - List appointments
- \`POST /api/appointments\` - Create appointment
- \`GET /api/appointments/:id\` - Get appointment details
- \`PUT /api/appointments/:id\` - Update appointment
- \`DELETE /api/appointments/:id\` - Delete appointment

## 🤝 Contributing

### Development Workflow
1. **Fork** the repository
2. **Create** a feature branch (\`git checkout -b feature/amazing-feature\`)
3. **Commit** your changes (\`git commit -m 'Add amazing feature'\`)
4. **Push** to the branch (\`git push origin feature/amazing-feature\`)
5. **Open** a Pull Request

### Code Standards
- **ESLint**: JavaScript/TypeScript linting
- **Prettier**: Code formatting
- **Husky**: Git hooks for quality checks
- **Commitizen**: Standardized commit messages

### Testing Requirements
- All new features must include unit tests
- Integration tests for API changes
- E2E tests for user-facing features
- 90%+ code coverage requirement

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Healthcare Domain Experts**: For medical workflow insights
- **DevOps Community**: For best practices and tools
- **Open Source Contributors**: For amazing tools and libraries
- **Security Researchers**: For vulnerability research and tools

## 📞 Support

### Documentation
- [API Documentation](./docs/generated/api/)
- [Deployment Guide](./docs/generated/deployment-guide.md)
- [Architecture Overview](./docs/generated/architecture/)

### Getting Help
- **Issues**: [GitHub Issues](https://github.com/arsh-dang/healthcare-devops-pipeline/issues)
- **Discussions**: [GitHub Discussions](https://github.com/arsh-dang/healthcare-devops-pipeline/discussions)
- **Documentation**: [Wiki](https://github.com/arsh-dang/healthcare-devops-pipeline/wiki)

### Community
- **Slack**: Join our [Slack community](https://healthcare-devops.slack.com)
- **Twitter**: Follow [@HealthcareDevOps](https://twitter.com/HealthcareDevOps)
- **Blog**: [DevOps Blog](https://blog.healthcare-devops.com)

---

**Built with ❤️ for healthcare professionals worldwide**
EOF

    log_success "Comprehensive README generated"
}

# Generate all documentation
generate_api_docs
generate_jsdoc
generate_architecture_docs
generate_deployment_docs
generate_readme

# Create documentation index
cat > $OUTPUT_DIR/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Healthcare DevOps Pipeline - Documentation</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            text-align: center;
            padding: 40px 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .card {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        .card:hover {
            transform: translateY(-5px);
        }
        .card h3 {
            color: #667eea;
            margin-top: 0;
        }
        .btn {
            display: inline-block;
            background: #667eea;
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 5px;
            margin: 5px;
            transition: background 0.2s;
        }
        .btn:hover {
            background: #5a6fd8;
        }
        .status {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: bold;
        }
        .status.generated {
            background: #d4edda;
            color: #155724;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏥 Healthcare DevOps Pipeline</h1>
        <p>Comprehensive Documentation Suite</p>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>Version:</strong> $VERSION</p>
    </div>

    <div class="grid">
        <div class="card">
            <h3>📚 API Documentation</h3>
            <p>OpenAPI 3.0 specification and interactive API documentation</p>
            <a href="api/openapi-spec.yaml" class="btn">OpenAPI Spec</a>
            <a href="api/jsdoc/index.html" class="btn">JSDoc</a>
            <span class="status generated">Generated</span>
        </div>

        <div class="card">
            <h3>🏗️ Architecture</h3>
            <p>System architecture, deployment strategies, and infrastructure design</p>
            <a href="architecture/system-overview.md" class="btn">System Overview</a>
            <a href="architecture/deployment-architecture.md" class="btn">Deployment</a>
            <span class="status generated">Generated</span>
        </div>

        <div class="card">
            <h3>🚀 Deployment Guide</h3>
            <p>Step-by-step deployment instructions and troubleshooting</p>
            <a href="deployment-guide.md" class="btn">Deployment Guide</a>
            <span class="status generated">Generated</span>
        </div>

        <div class="card">
            <h3>📖 Project README</h3>
            <p>Comprehensive project documentation and getting started guide</p>
            <a href="README.md" class="btn">View README</a>
            <span class="status generated">Generated</span>
        </div>
    </div>

    <div class="card" style="margin-top: 30px;">
        <h3>📊 Documentation Summary</h3>
        <ul>
            <li><strong>API Documentation:</strong> OpenAPI spec, JSDoc, interactive docs</li>
            <li><strong>Architecture Docs:</strong> System design, deployment strategies</li>
            <li><strong>Deployment Guide:</strong> Installation, configuration, troubleshooting</li>
            <li><strong>Project README:</strong> Overview, features, getting started</li>
            <li><strong>Generated Files:</strong> $(find $OUTPUT_DIR -type f | wc -l) files</li>
            <li><strong>Total Size:</strong> $(du -sh $OUTPUT_DIR | cut -f1)</li>
        </ul>
    </div>

    <div style="text-align: center; margin-top: 40px; color: #666;">
        <p>Generated by Enhanced Documentation Generator v1.0</p>
        <p>For questions or issues, please refer to the project repository</p>
    </div>
</body>
</html>
EOF

log_success "Documentation index generated"
log_docs "Documentation generation completed!"
log_info "Generated files:"
find $OUTPUT_DIR -type f | while read file; do
    log_info "  - $file"
done

log_info "Total files generated: $(find $OUTPUT_DIR -type f | wc -l)"
log_info "Total size: $(du -sh $OUTPUT_DIR | cut -f1)"
log_info ""
log_info "📖 Open documentation index:"
log_info "   open $OUTPUT_DIR/index.html"
