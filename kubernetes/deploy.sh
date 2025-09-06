#!/bin/bash

# Exit script on error
set -e

echo "Healthcare Application Kubernetes Deployment (Terraform + Monitoring)"
echo "--------------------------------------------------------------------"

# Check if Colima is running
if ! colima status &> /dev/null; then
    echo "Starting Colima with Kubernetes..."
    colima start --kubernetes --cpu 2 --memory 4 --disk 20
    sleep 10  # Give some time for Kubernetes to initialize
fi

# Configure Docker for better reliability
echo "Configuring Docker for better network reliability..."
# Increase timeouts for Docker operations
export DOCKER_CLIENT_TIMEOUT=180
export COMPOSE_HTTP_TIMEOUT=180

# Function to build or pull images with retry logic
build_or_pull_image() {
    local image_name=$1
    local dockerfile=$2
    local fallback_image=$3
    local max_attempts=3
    local attempt=1
    
    echo "Building image: $image_name from $dockerfile (attempt 1/$max_attempts)"
    
    while [ $attempt -le $max_attempts ]; do
        if docker build -t $image_name -f $dockerfile . --network=host; then
            echo "Successfully built $image_name"
            return 0
        else
            echo "Attempt $attempt failed for $image_name"
            if [ -n "$fallback_image" ] && [ $attempt -eq $max_attempts ]; then
                echo "Using fallback image: $fallback_image"
                docker pull $fallback_image
                docker tag $fallback_image $image_name
                if [ $? -eq 0 ]; then
                    echo "Successfully pulled fallback image for $image_name"
                    return 0
                fi
            fi
            attempt=$((attempt+1))
            echo "Retrying in 5 seconds... (attempt $attempt/$max_attempts)"
            sleep 5
        fi
    done
    
    echo "Failed to build or pull $image_name after $max_attempts attempts"
    exit 1
}

# Build Docker images with retry logic
echo "Building Docker images..."
build_or_pull_image "healthcare-frontend:latest" "Dockerfile.frontend" "nginx:1.25.3-alpine"
build_or_pull_image "healthcare-backend:latest" "Dockerfile.backend" "node:20-alpine"

# Deploy infrastructure using Terraform
echo "Deploying infrastructure with Terraform..."
cd terraform

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply infrastructure
echo "Applying Terraform configuration..."
terraform apply -auto-approve \
    -var="environment=staging" \
    -var="namespace=healthcare" \
    -var='replica_count={"frontend"=2,"backend"=3}'

# Get the namespace from Terraform output
NAMESPACE=$(terraform output -raw namespace)
echo "Using Terraform-managed namespace: $NAMESPACE"

cd ..

# Deploy monitoring stack (not managed by Terraform yet)
echo "Deploying Prometheus and Grafana for monitoring..."
kubectl apply -f kubernetes/prometheus.yaml -n $NAMESPACE
kubectl apply -f kubernetes/grafana.yaml -n $NAMESPACE
kubectl apply -f kubernetes/prometheus-rules.yaml -n $NAMESPACE

# Configure ingress
echo "Configuring ingress..."
kubectl apply -f kubernetes/ingress.yaml -n $NAMESPACE

# Wait for deployments to be ready with appropriate error handling
echo "Waiting for all deployments to be ready..."
wait_for_deployment() {
    local deployment_name=$1
    if ! kubectl wait --for=condition=available --timeout=360s deployment/$deployment_name -n $NAMESPACE; then
        echo "Warning: $deployment_name not ready within timeout. You can check its status later with:"
        echo "kubectl get pods -n $NAMESPACE | grep $deployment_name"
    else
        echo "$deployment_name is ready!"
    fi
}

wait_for_deployment "backend"
wait_for_deployment "frontend"
wait_for_deployment "prometheus"
wait_for_deployment "grafana"

echo "Deployment completed successfully!"
echo "----------------------------------------"
echo "To access the application:"

# Get the kubernetes IP using Colima
COLIMA_IP=$(colima list --json | jq -r '.colima.address' || echo "127.0.0.1")
echo "Add this entry to your /etc/hosts file:"
echo "$COLIMA_IP healthcare.local"
echo ""
echo "Then access the following services:"
echo "- Healthcare App: http://healthcare.local"
echo "- API: http://healthcare.local/api"
echo "- Prometheus: http://healthcare.local/prometheus"
echo "- Grafana: http://healthcare.local/grafana"
echo "  (Grafana default credentials - Username: admin, Password: admin123)"

# Ensure the Nginx Ingress Controller is installed
echo ""
echo "Checking if Nginx Ingress Controller is installed..."
if ! kubectl get namespace ingress-nginx &> /dev/null; then
    echo "Installing Nginx Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    echo "Waiting for Nginx Ingress Controller to be ready..."
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s
fi

# Print infrastructure information
echo ""
echo "Infrastructure Information:"
echo "--------------------------"
echo "Core infrastructure (MongoDB, Backend, Frontend) deployed via Terraform"
echo "Monitoring stack (Prometheus, Grafana) deployed via Kubernetes manifests"
echo "Namespace: $NAMESPACE"
echo ""
echo "To view Terraform-managed resources:"
echo "cd terraform && terraform show"
echo ""
echo "To view all resources in the healthcare namespace:"
echo "kubectl get all -n $NAMESPACE"
echo ""

# Enable port forwarding for ingress controller
echo "Setting up port forwarding for Nginx Ingress Controller..."
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8081:80 &> /dev/null &
echo "Port forwarding enabled. Access the application at: http://localhost:8081"

# Also setup direct port forwarding to frontend service
echo "Setting up direct port forwarding to frontend service..."
kubectl port-forward -n $NAMESPACE service/frontend 3000:3000 &> /dev/null &
echo "Frontend service directly accessible at: http://localhost:3000"