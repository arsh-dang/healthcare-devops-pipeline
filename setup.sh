#!/bin/bash

# Healthcare DevOps Pipeline - Quick Setup Script
# This script helps you get started with the healthcare application quickly

set -e

echo "🚀 Healthcare DevOps Pipeline - Quick Setup"
echo "=========================================="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status
print_status() {
    echo "✅ $1"
}

# Function to print error
print_error() {
    echo "❌ $1"
}

# Check prerequisites
echo "📋 Checking prerequisites..."

if command_exists node; then
    print_status "Node.js is installed: $(node --version)"
else
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

if command_exists npm; then
    print_status "npm is installed: $(npm --version)"
else
    print_error "npm is not installed. Please install npm."
    exit 1
fi

if command_exists docker; then
    print_status "Docker is installed: $(docker --version)"
else
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if command_exists docker-compose; then
    print_status "Docker Compose is installed: $(docker-compose --version)"
else
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo ""
echo "🔧 Setting up the project..."

# Make scripts executable
echo "Making scripts executable..."
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x terraform/*.sh 2>/dev/null || true
print_status "Scripts are now executable"

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        print_status "Environment file created from template"
        echo "⚠️  Please edit .env file with your actual configuration values"
    else
        print_error ".env.example template not found"
    fi
else
    print_status "Environment file already exists"
fi

# Install dependencies
echo "Installing project dependencies..."
if npm install; then
    print_status "Dependencies installed successfully"
else
    print_error "Failed to install dependencies"
    exit 1
fi

echo ""
echo "🎯 Setup complete! You can now:"
echo ""
echo "1. Start local development environment:"
echo "   docker-compose up -d"
echo ""
echo "2. Run tests:"
echo "   npm test"
echo ""
echo "3. Start development server:"
echo "   npm run dev"
echo ""
echo "4. Access the application:"
echo "   - Frontend: http://localhost:3000"
echo "   - Backend API: http://localhost:5000"
echo "   - Health Check: http://localhost:5000/health"
echo ""
echo "5. For production deployment:"
echo "   cd terraform && ./deploy.sh deploy staging"
echo ""
echo "📚 For more information, see README.md"
echo ""
echo "Happy coding! 🎉"
