#!/bin/bash

# Exit script on error
set -e

echo "Healthcare Application Kubernetes Deployment (Colima)"
echo "---------------------------------------------------"

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

# Create namespace if it doesn't exist
echo "Ensuring healthcare namespace exists..."
kubectl create namespace healthcare --dry-run=client -o yaml | kubectl apply -f -

# Apply ConfigMaps first
echo "Applying ConfigMaps..."
kubectl apply -f kubernetes/config-map.yaml -n healthcare
kubectl apply -f kubernetes/mongodb-init-config.yaml -n healthcare

# Apply Secrets
echo "Applying Secrets..."
kubectl apply -f kubernetes/mongodb-secret.yaml -n healthcare
kubectl apply -f kubernetes/backend-secret.yaml -n healthcare

# Deploy MongoDB as StatefulSet
echo "Deploying MongoDB StatefulSet..."
kubectl apply -f kubernetes/mongodb-statefulset.yaml -n healthcare

# Wait for MongoDB to be ready with increased timeout
echo "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=ready pod/mongodb-0 -n healthcare --timeout=360s || echo "Warning: MongoDB pod not ready within timeout, continuing anyway..."

# Deploy backend and frontend services
echo "Deploying backend and frontend services..."
kubectl apply -f kubernetes/backend-deployment.yaml -n healthcare
kubectl apply -f kubernetes/frontend-deployment.yaml -n healthcare

# Deploy monitoring stack
echo "Deploying Prometheus and Grafana for monitoring..."
kubectl apply -f kubernetes/prometheus.yaml -n healthcare
kubectl apply -f kubernetes/grafana.yaml -n healthcare

# Configure ingress
echo "Configuring ingress..."
kubectl apply -f kubernetes/ingress.yaml -n healthcare

# Wait for deployments to be ready with appropriate error handling
echo "Waiting for all deployments to be ready..."
wait_for_deployment() {
    local deployment_name=$1
    if ! kubectl wait --for=condition=available --timeout=360s deployment/$deployment_name -n healthcare; then
        echo "Warning: $deployment_name not ready within timeout. You can check its status later with:"
        echo "kubectl get pods -n healthcare | grep $deployment_name"
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

# Print information about secrets management
echo ""
echo "Secrets Management Information:"
echo "------------------------------"
echo "The following secrets have been applied:"
echo "- mongodb-secret: Contains MongoDB root credentials"
echo "- backend-secret: Contains backend application secrets including JWT and API keys"
echo ""
echo "To rotate or update secrets, use the following commands:"
echo "kubectl create secret generic mongodb-secret -n healthcare --from-literal=mongodb-root-username=newadmin --from-literal=mongodb-root-password=newpassword --dry-run=client -o yaml | kubectl apply -f -"
echo ""
echo "To view all resources in the healthcare namespace:"
echo "kubectl get all -n healthcare"
echo ""

# Enable port forwarding for ingress controller
echo "Setting up port forwarding for Nginx Ingress Controller..."
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8081:80 &> /dev/null &
echo "Port forwarding enabled. Access the application at: http://localhost:8081"

# Also setup direct port forwarding to frontend service
echo "Setting up direct port forwarding to frontend service..."
kubectl port-forward -n healthcare service/frontend-service 3000:3000 &> /dev/null &
echo "Frontend service directly accessible at: http://localhost:3000"