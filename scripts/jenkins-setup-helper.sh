#!/bin/bash

# Jenkins Configuration Helper Script
# Run this after Jenkins is installed and running

set -e

echo "Jenkins Configuration Helper"
echo "==============================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Check if Jenkins is running
if ! curl -s http://localhost:8080 > /dev/null; then
    print_error "Jenkins is not running on http://localhost:8080"
    echo "Please start Jenkins first:"
    echo "  brew install --cask jenkins"
    echo "  brew services start jenkins"
    exit 1
fi

print_status "Jenkins is running"

# Get initial admin password
JENKINS_HOME="/opt/homebrew/var/lib/jenkins"
if [ -f "$JENKINS_HOME/secrets/initialAdminPassword" ]; then
    ADMIN_PASSWORD=$(cat "$JENKINS_HOME/secrets/initialAdminPassword")
    echo ""
    echo "Initial Admin Password:"
    echo "=========================="
    echo "$ADMIN_PASSWORD"
    echo ""
    echo "Use this password to unlock Jenkins at http://localhost:8080"
    echo ""
fi

# Check SonarQube status
echo "Checking SonarQube..."
if curl -s http://localhost:9000/api/system/status | grep -q "UP"; then
    print_status "SonarQube is running"
else
    print_warning "SonarQube is not ready yet. Please wait a few minutes."
fi

# Generate SonarQube token instructions
echo ""
echo "SonarQube Token Generation:"
echo "==============================="
echo "1. Go to http://localhost:9000"
echo "2. Login with admin/admin"
echo "3. Go to Administration > Security > Users"
echo "4. Click on 'admin' user"
echo "5. Click 'Tokens' tab"
echo "6. Generate a new token named 'jenkins'"
echo "7. Copy the token for Jenkins configuration"
echo ""

# Docker Hub instructions
echo "Docker Hub Setup:"
echo "===================="
echo "1. Create account at https://hub.docker.com"
echo "2. Create repository: healthcare-app-frontend"
echo "3. Create repository: healthcare-app-backend"
echo "4. Generate access token in Security settings"
echo "5. Update Jenkinsfile with your Docker Hub username"
echo ""

# Kubeconfig setup
echo "Kubeconfig Setup:"
echo "====================="
echo "Your kubeconfig location: ~/.kube/config"
if [ -f ~/.kube/config ]; then
    print_status "Kubeconfig file exists"
else
    print_warning "Kubeconfig file not found"
    echo "Generating kubeconfig for Colima..."
    mkdir -p ~/.kube
    colima kubectl config view --raw > ~/.kube/config
    print_status "Kubeconfig generated"
fi

# Jenkins plugins list
echo ""
echo "Required Jenkins Plugins:"
echo "============================"
cat << EOF
Install these plugins via Jenkins UI (Manage Jenkins > Manage Plugins):

Essential Plugins:
- Pipeline
- Blue Ocean
- Docker Pipeline
- Kubernetes CLI Plugin
- NodeJS Plugin
- SonarQube Scanner

Testing & Quality:
- JUnit Plugin
- HTML Publisher Plugin
- Coverage Plugin
- Warnings Next Generation Plugin

Notifications:
- Email Extension Plugin
- Slack Notification Plugin (optional)

Security:
- Credentials Plugin
- Role-based Authorization Strategy
EOF

echo ""
echo "Jenkins Job Creation:"
echo "========================"
echo "1. Go to Jenkins Dashboard"
echo "2. Click 'New Item'"
echo "3. Enter name: 'healthcare-app-pipeline'"
echo "4. Select 'Pipeline'"
echo "5. In Pipeline section:"
echo "   - Definition: Pipeline script from SCM"
echo "   - SCM: Git"
echo "   - Repository URL: [Your GitHub repo URL]"
echo "   - Script Path: Jenkinsfile"
echo "6. Save and build"
echo ""

# Credentials setup checklist
echo "Credentials Checklist:"
echo "========================="
echo "Add these in Jenkins (Manage Jenkins > Manage Credentials):"
echo ""
echo "1. docker-hub-credentials (Username with password)"
echo "   - Username: [Your Docker Hub username]"
echo "   - Password: [Your Docker Hub token]"
echo ""
echo "2. sonar-token (Secret text)"
echo "   - Secret: [SonarQube token from step above]"
echo ""
echo "3. kubeconfig (Secret file)"
echo "   - File: ~/.kube/config"
echo ""

# Update Jenkinsfile with username
if [ -f "Jenkinsfile" ]; then
    echo "Update Required:"
    echo "=================="
    echo "Edit Jenkinsfile and replace 'yourusername' with your Docker Hub username:"
    echo "  DOCKER_REPO = 'yourusername/healthcare-app'"
    echo ""
    echo "Current line in Jenkinsfile:"
    grep "DOCKER_REPO" Jenkinsfile || echo "Line not found"
fi

echo ""
print_status "Configuration guide complete!"
echo ""
echo "Ready to proceed with:"
echo "1. Jenkins plugin installation"
echo "2. Credentials configuration"
echo "3. Pipeline job creation"
echo "4. First pipeline run"
echo ""
echo "See IMPLEMENTATION_GUIDE.md for detailed steps."
