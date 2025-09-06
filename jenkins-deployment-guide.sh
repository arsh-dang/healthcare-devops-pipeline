#!/bin/bash

echo "=============================================="
echo "🚀 Jenkins Pipeline Deployment Guide"
echo "=============================================="
echo

echo "📋 STEP 1: Jenkins Access"
echo "----------------------------"
echo "✅ Jenkins is running on: http://localhost:8080"
echo "✅ Only regular Jenkins is active (jenkins-lts stopped)"
echo

echo "📋 STEP 2: Create New Pipeline Job"
echo "----------------------------"
echo "1. Open Jenkins at: http://localhost:8080"
echo "2. Click 'New Item'"
echo "3. Enter name: 'healthcare-devops-pipeline'"
echo "4. Select 'Pipeline' type"
echo "5. Click 'OK'"
echo

echo "📋 STEP 3: Configure Pipeline"
echo "----------------------------"
echo "In the Pipeline configuration:"
echo "• Definition: Pipeline script from SCM"
echo "• SCM: Git"
echo "• Repository URL: https://github.com/arsh-dang/healthcare-devops-pipeline"
echo "• Branch: */main"
echo "• Script Path: Jenkinsfile"
echo

echo "📋 STEP 4: Required Jenkins Plugins"
echo "----------------------------"
echo "Install these plugins (Manage Jenkins → Plugins):"
echo "• Git"
echo "• Pipeline"
echo "• Docker Pipeline"
echo "• Kubernetes"
echo "• SonarQube Scanner"
echo "• Coverage"
echo "• HTML Publisher"
echo

echo "📋 STEP 5: Configure Global Tools"
echo "----------------------------"
echo "Go to Manage Jenkins → Global Tool Configuration:"
echo
echo "🔧 Node.js:"
echo "• Name: NodeJS-20"
echo "• Version: NodeJS 20.x"
echo "• Global npm packages: pnpm"
echo
echo "🔧 Docker:"
echo "• Name: docker"
echo "• Installation: Install automatically"
echo
echo "🔧 Terraform:"
echo "• Name: terraform"
echo "• Version: Latest"
echo

echo "📋 STEP 6: Configure Kubernetes"
echo "----------------------------"
echo "Go to Manage Jenkins → Nodes and Clouds → Configure Clouds:"
echo "• Add Kubernetes cloud"
echo "• Kubernetes URL: https://127.0.0.1:54043"
echo "• Namespace: default"
echo "• Test connection"
echo

echo "📋 STEP 7: Environment Variables"
echo "----------------------------"
echo "Set these in Manage Jenkins → System:"
echo "• KUBECONFIG: ~/.kube/config"
echo "• DOCKER_HOST: unix:///var/run/docker.sock"
echo

echo "📋 STEP 8: Run the Pipeline"
echo "----------------------------"
echo "1. Save the pipeline configuration"
echo "2. Click 'Build Now'"
echo "3. Monitor the 7-stage execution:"
echo "   Stage 1: Checkout ✅"
echo "   Stage 2: Test & Coverage ✅" 
echo "   Stage 3: Security Scanning ✅"
echo "   Stage 4: Infrastructure as Code ✅"
echo "   Stage 5: Build & Package ✅"
echo "   Stage 6: Deploy ✅"
echo "   Stage 7: Monitor ✅"
echo

echo "📋 PIPELINE STAGES OVERVIEW"
echo "=============================================="
echo "🔄 Stage 1: Checkout"
echo "   • Git clone from repository"
echo "   • Workspace preparation"
echo
echo "🧪 Stage 2: Test & Coverage"
echo "   • npm install dependencies"
echo "   • Run Jest tests with coverage"
echo "   • Validate 100% coverage threshold"
echo "   • Generate coverage reports"
echo
echo "🔒 Stage 3: Security Scanning"
echo "   • SAST code analysis"
echo "   • Dependency vulnerability scan"
echo "   • Container security scan"
echo "   • Secrets detection"
echo
echo "🏗️ Stage 4: Infrastructure as Code"
echo "   • Terraform workspace setup"
echo "   • Terraform plan validation"
echo "   • Infrastructure deployment"
echo "   • Output collection"
echo
echo "📦 Stage 5: Build & Package"
echo "   • Docker image builds"
echo "   • Multi-stage optimization"
echo "   • Image tagging and registry push"
echo
echo "🚀 Stage 6: Deploy"
echo "   • Kubernetes namespace validation"
echo "   • Application deployment"
echo "   • Health check validation"
echo "   • Service availability check"
echo
echo "📊 Stage 7: Monitor"
echo "   • Prometheus setup"
echo "   • Grafana dashboard deployment"
echo "   • Alert rule configuration"
echo "   • Monitoring validation"
echo

echo "📈 EXPECTED RESULTS"
echo "=============================================="
echo "✅ All 7 stages should complete successfully"
echo "✅ 100% test coverage achieved and reported"
echo "✅ Security scans pass with no critical issues"
echo "✅ Infrastructure deployed via Terraform"
echo "✅ Application running in Kubernetes"
echo "✅ Monitoring active with Prometheus/Grafana"
echo

echo "🎯 HIGH HD DEMONSTRATION"
echo "=============================================="
echo "This pipeline demonstrates:"
echo "• Complete Infrastructure as Code"
echo "• 100% automated deployment"
echo "• Comprehensive testing and security"
echo "• Production-ready monitoring"
echo "• Enterprise DevOps best practices"
echo

echo "🔧 TROUBLESHOOTING"
echo "=============================================="
echo "If pipeline fails:"
echo "• Check Docker daemon is running"
echo "• Verify Kubernetes cluster is active"
echo "• Ensure required tools are installed"
echo "• Check Jenkins console output for errors"
echo
echo "Jenkins URL: http://localhost:8080"
echo "=============================================="
