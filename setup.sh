#!/bin/bash

# Quick Setup Script for Healthcare App DevOps Pipeline
# This script automates the initial environment setup

set -e

echo "🚀 Healthcare App DevOps Pipeline - Quick Setup"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS. Please adapt for your OS."
    exit 1
fi

print_status "Starting environment setup..."

# Step 1: Check and install Homebrew
echo "📦 Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    print_status "Homebrew already installed"
fi

# Step 2: Install required tools
echo "🔧 Installing required tools..."

tools=(
    "docker"
    "colima" 
    "kubectl"
    "helm"
    "terraform"
    "node"
    "jq"
)

for tool in "${tools[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo "Installing $tool..."
        brew install $tool
        print_status "$tool installed"
    else
        print_status "$tool already installed"
    fi
done

# Step 3: Install pnpm
echo "📦 Installing pnpm..."
if ! command -v pnpm &> /dev/null; then
    npm install -g pnpm
    print_status "pnpm installed"
else
    print_status "pnpm already installed"
fi

# Step 4: Start Docker environment
echo "🐳 Setting up Docker environment..."
if ! colima status &> /dev/null; then
    echo "Starting Colima with Kubernetes..."
    colima start --kubernetes --cpu 4 --memory 8 --disk 50
    print_status "Colima started with Kubernetes"
else
    print_status "Colima already running"
fi

# Step 5: Install project dependencies
echo "📦 Installing project dependencies..."
if [ -f "package.json" ]; then
    pnpm install
    print_status "Project dependencies installed"
else
    print_warning "package.json not found. Run this script from the project root directory."
fi

# Step 6: Make scripts executable
echo "🔐 Setting script permissions..."
if [ -f "scripts/advanced-security-scan.sh" ]; then
    chmod +x scripts/advanced-security-scan.sh
    print_status "Security scan script made executable"
fi

# Step 7: Start SonarQube
echo "📊 Starting SonarQube..."
if ! docker ps | grep -q sonarqube; then
    docker run -d --name sonarqube \
        -p 9000:9000 \
        -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
        sonarqube:latest
    print_status "SonarQube started on http://localhost:9000"
    print_warning "Wait 2-3 minutes for SonarQube to fully start"
else
    print_status "SonarQube already running"
fi

# Step 8: Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p security-reports
mkdir -p terraform/.terraform
mkdir -p postman
mkdir -p load-tests

# Step 9: Display next steps
echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Next Steps:"
echo "1. Install Jenkins: brew install --cask jenkins"
echo "2. Start Jenkins: brew services start jenkins"
echo "3. Access Jenkins at: http://localhost:8080"
echo "4. Access SonarQube at: http://localhost:9000 (admin/admin)"
echo "5. Follow the IMPLEMENTATION_GUIDE.md for detailed setup"
echo ""
echo "Quick Commands:"
echo "- Check Kubernetes: kubectl cluster-info"
echo "- Check Docker: docker ps"
echo "- Check SonarQube: curl http://localhost:9000/api/system/status"
echo ""

# Step 10: Test basic functionality
echo "🧪 Running basic tests..."

# Test Docker
if docker ps &> /dev/null; then
    print_status "Docker is working"
else
    print_error "Docker test failed"
fi

# Test Kubernetes
if kubectl cluster-info &> /dev/null; then
    print_status "Kubernetes is working"
else
    print_error "Kubernetes test failed"
fi

# Test Node.js
if node --version &> /dev/null; then
    print_status "Node.js is working ($(node --version))"
else
    print_error "Node.js test failed"
fi

echo ""
print_status "Environment setup completed successfully!"
print_warning "Please review IMPLEMENTATION_GUIDE.md for the complete setup process"
