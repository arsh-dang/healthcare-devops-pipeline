# Healthcare Appointments Microservices Application

This application is configured as a microservices architecture using **Terraform for Infrastructure as Code** and Kubernetes for orchestration. The application consists of three main services:

1. **Frontend Service**: React application served through Nginx
2. **Backend Service**: Express.js API
3. **Database Service**: MongoDB

## Infrastructure as Code with Terraform

### Prerequisites

- macOS (as Colima is designed for macOS)
- [Terraform](https://terraform.io) installed
- [Colima](https://github.com/abiosoft/colima) installed
- kubectl CLI tool
- Docker
- jq (for JSON processing)

### Installation

If you don't have the prerequisites installed, you can install them using Homebrew:

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install prerequisites
brew install terraform colima docker kubectl jq
```

## Deployment Options

### Option 1: Full Terraform Deployment (Recommended)

1. **Deploy Infrastructure with Terraform**:
   ```bash
   cd terraform
   
   # Initialize Terraform
   terraform init
   
   # Plan the deployment
   terraform plan -var="environment=staging"
   
   # Apply the infrastructure
   terraform apply -var="environment=staging"
   ```

2. **Deploy Monitoring Stack**:
   ```bash
   # Get the namespace from Terraform
   NAMESPACE=$(terraform output -raw namespace)
   
   # Deploy monitoring components
   kubectl apply -f ../kubernetes/prometheus.yaml -n $NAMESPACE
   kubectl apply -f ../kubernetes/grafana.yaml -n $NAMESPACE
   kubectl apply -f ../kubernetes/prometheus-rules.yaml -n $NAMESPACE
   ```

### Option 2: Automated Deployment Script

1. Make the deployment script executable:
   ```bash
   chmod +x kubernetes/deploy.sh
   ```

2. Run the deployment script:
   ```bash
   ./kubernetes/deploy.sh
   ```

3. The script will:
   - Start Colima with Kubernetes if it's not already running
   - Build the necessary Docker images
   - Deploy infrastructure using Terraform
   - Deploy monitoring components
   - Configure routing through an Ingress controller
   - Set up port forwarding for local access

### Infrastructure Components

The Terraform configuration deploys:

- **Namespace**: Environment-specific namespace management
- **StatefulSet**: MongoDB with persistent storage and auto-scaling
- **Deployments**: Frontend and backend services with health checks
- **Services**: ClusterIP services for internal communication
- **ConfigMaps**: Application configuration management
- **Secrets**: Secure credential management
- **HPA**: Horizontal Pod Autoscalers for dynamic scaling
- **Network Policies**: Security isolation between services

### Manual Kubernetes Deployment (Legacy)

For learning purposes, you can also deploy monitoring components individually:

```bash
# Start Colima with Kubernetes
colima start --kubernetes

# Apply monitoring components to Terraform-managed namespace
NAMESPACE="healthcare-staging"  # Or use terraform output
kubectl apply -f kubernetes/prometheus.yaml -n $NAMESPACE
kubectl apply -f kubernetes/grafana.yaml -n $NAMESPACE
kubectl apply -f kubernetes/prometheus-rules.yaml -n $NAMESPACE
kubectl apply -f kubernetes/ingress.yaml -n $NAMESPACE
```
- **PersistentVolumeClaim** for MongoDB data persistence
- **Ingress** for external access and routing
- **ConfigMap** for configuration management
- **HPA** for automatic scaling based on resource utilization
- **Prometheus & Grafana** for monitoring and visualization

## Monitoring and Observability

### Prometheus

The application includes Prometheus for metrics collection and monitoring:

- Collects metrics from services via service endpoints
- Monitors Kubernetes cluster health and performance
- Stores time-series data for analysis
- Provides alerting capabilities

To access Prometheus UI:

```bash
kubectl port-forward svc/prometheus-service 9090:9090
```

Then visit http://localhost:9090 in your browser.

### Grafana

Grafana is deployed for visualizing metrics and creating dashboards:

- Pre-configured dashboards for monitoring application services
- Real-time visualization of performance metrics
- Customizable alerts and notifications
- Integration with Prometheus data source

To access Grafana:

```bash
kubectl port-forward svc/grafana 3000:3000
```

Then visit http://localhost:3000 in your browser.
- Default credentials: admin/admin (you'll be prompted to change on first login)

### Default Dashboards

The Grafana deployment includes several pre-configured dashboards:
- Kubernetes Cluster Overview
- Node Resource Utilization
- MongoDB Performance
- Backend API Performance
- Frontend Metrics

## Auto Scaling with HPA

The application uses Horizontal Pod Autoscaler (HPA) to automatically scale services based on resource usage:

- **Backend HPA**: Scales backend pods based on CPU utilization
  - Target CPU utilization: 80%
  - Min replicas: 1
  - Max replicas: 10

- **Frontend HPA**: Scales frontend pods based on CPU utilization
  - Target CPU utilization: 70% 
  - Min replicas: 2
  - Max replicas: 8

To view current HPA status:

```bash
kubectl get hpa
```

To modify HPA settings:

```bash
kubectl edit hpa backend-hpa
kubectl edit hpa frontend-hpa
```

## API Endpoints

### Appointments

- `GET /api/appointments` - List all appointments
- `POST /api/appointments` - Create a new appointment
- `GET /api/appointments/:id` - Get a specific appointment
- `PUT /api/appointments/:id` - Update an appointment
- `DELETE /api/appointments/:id` - Delete an appointment

## Scaling

With Kubernetes, you can easily scale any component:

```bash
# Scale the backend to 3 replicas
kubectl scale deployment/backend --replicas=3
```

## Monitoring and Logs

```bash
# Get pod status
kubectl get pods

# View logs for a specific service
kubectl logs -l app=backend

# Stream logs from all frontend pods
kubectl logs -f -l app=frontend
```

## Troubleshooting

- If you encounter connection issues, check pod status: `kubectl get pods`
- Verify services are running: `kubectl get svc`
- Check Ingress configuration: `kubectl describe ingress healthcare-ingress`
- View detailed logs: `kubectl logs <pod-name>`
- For Colima-specific issues: `colima status` or `colima logs`

### Ingress Controller Setup

If the Ingress controller is not automatically deployed with Colima, you can install it manually:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```
