#!/bin/bash

echo "=========================================="
echo "🚀 Jenkins Pipeline Setup for Healthcare DevOps"
echo "=========================================="
echo

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to show step
show_step() {
    echo "📍 STEP $1: $2"
    echo "----------------------------------------"
}

show_step "1" "Jenkins Installation Check"

if command_exists jenkins; then
    echo "✅ Jenkins already installed"
    jenkins --version
elif command_exists brew; then
    echo "📦 Installing Jenkins via Homebrew..."
    brew install jenkins-lts
else
    echo "❌ Please install Jenkins manually:"
    echo "   - macOS: brew install jenkins-lts"
    echo "   - Ubuntu: sudo apt install jenkins"
    echo "   - Windows: Download from jenkins.io"
    exit 1
fi

echo

show_step "2" "Jenkins Service Setup"

if command_exists brew; then
    echo "🔧 Starting Jenkins service..."
    brew services start jenkins-lts
    
    echo "⏳ Waiting for Jenkins to start (30 seconds)..."
    sleep 30
    
    echo "📋 Jenkins Setup Information:"
    echo "   URL: http://localhost:8080"
    echo "   Initial Admin Password Location:"
    echo "   $(brew --prefix)/var/jenkins_home/secrets/initialAdminPassword"
    echo
    
    if [ -f "$(brew --prefix)/var/jenkins_home/secrets/initialAdminPassword" ]; then
        echo "🔑 Initial Admin Password:"
        cat "$(brew --prefix)/var/jenkins_home/secrets/initialAdminPassword"
    fi
else
    echo "🔧 Start Jenkins manually and note the initial admin password"
fi

echo

show_step "3" "Required Jenkins Plugins"

echo "📦 Install these plugins in Jenkins:"
echo "   ✅ Git"
echo "   ✅ Pipeline"
echo "   ✅ Docker Pipeline"
echo "   ✅ Kubernetes CLI"
echo "   ✅ Terraform"
echo "   ✅ NodeJS"
echo "   ✅ OWASP Dependency-Check"
echo "   ✅ SonarQube Scanner"
echo

show_step "4" "Pipeline Configuration"

echo "🔗 GitHub Repository:"
echo "   Repository URL: https://github.com/arsh-dang/healthcare-devops-pipeline.git"
echo "   Branch: main"
echo "   Jenkinsfile: Jenkinsfile (in root)"
echo

echo "🛠️  Pipeline Configuration Steps:"
echo "   1. Open Jenkins: http://localhost:8080"
echo "   2. New Item → Pipeline"
echo "   3. Pipeline Name: 'Healthcare-DevOps-Pipeline'"
echo "   4. Pipeline Definition: 'Pipeline script from SCM'"
echo "   5. SCM: Git"
echo "   6. Repository URL: https://github.com/arsh-dang/healthcare-devops-pipeline.git"
echo "   7. Branch: */main"
echo "   8. Script Path: Jenkinsfile"
echo "   9. Save and Build"

echo

show_step "5" "Environment Setup"

echo "🔧 Required Tools (verify installation):"

# Check Docker
if command_exists docker; then
    echo "   ✅ Docker: $(docker --version)"
else
    echo "   ❌ Docker: Not installed"
fi

# Check Kubectl
if command_exists kubectl; then
    echo "   ✅ Kubectl: $(kubectl version --client --short 2>/dev/null || echo 'Installed')"
else
    echo "   ❌ Kubectl: Not installed"
fi

# Check Terraform
if command_exists terraform; then
    echo "   ✅ Terraform: $(terraform version | head -n1)"
else
    echo "   ❌ Terraform: Not installed"
fi

# Check Node.js
if command_exists node; then
    echo "   ✅ Node.js: $(node --version)"
else
    echo "   ❌ Node.js: Not installed"
fi

# Check npm
if command_exists npm; then
    echo "   ✅ npm: $(npm --version)"
else
    echo "   ❌ npm: Not installed"
fi

echo

show_step "6" "Jenkins Global Tool Configuration"

echo "🛠️  Configure these tools in Jenkins:"
echo "   Go to: Manage Jenkins → Global Tool Configuration"
echo
echo "   📦 Git:"
echo "      Name: Default"
echo "      Path: $(which git 2>/dev/null || echo '/usr/bin/git')"
echo
echo "   📦 NodeJS:"
echo "      Name: NodeJS-20"
echo "      Version: NodeJS 20.x"
echo "      Global packages: npm@latest"
echo
echo "   📦 Docker:"
echo "      Name: Docker"
echo "      Path: $(which docker 2>/dev/null || echo '/usr/local/bin/docker')"
echo
echo "   📦 Terraform:"
echo "      Name: Terraform"
echo "      Version: Latest"
echo

echo "=========================================="
echo "🎯 NEXT STEPS FOR PIPELINE DEPLOYMENT"
echo "=========================================="
echo

echo "1. 🌐 Open Jenkins: http://localhost:8080"
echo "2. 🔐 Use initial admin password shown above"
echo "3. 📦 Install suggested plugins + required plugins"
echo "4. 👤 Create admin user"
echo "5. 🔧 Configure global tools"
echo "6. ➕ Create new pipeline job"
echo "7. 🚀 Run the pipeline"

echo
echo "🔗 Pipeline will automatically:"
echo "   • Checkout code from GitHub"
echo "   • Run tests with 100% coverage"
echo "   • Execute security scanning"
echo "   • Deploy infrastructure with Terraform"
echo "   • Build and deploy containers"
echo "   • Set up monitoring"

echo
echo "=========================================="
echo "✅ Jenkins Setup Script Complete!"
echo "=========================================="
