# Jenkins Credentials Setup Guide

## Required Credentials for Pipeline

### 1. GitHub Token (ID: `github-token`)
- Kind: Secret text
- Secret: Your GitHub personal access token
- ID: `github-token`
- Description: GitHub API Token

**How to get GitHub token:**
1. Go to GitHub.com → Settings → Developer settings → Personal access tokens
2. Generate new token with repo permissions
3. Copy the token

### 2. Docker Hub Credentials (ID: `docker-hub-credentials`)
- Kind: Username with password
- Username: Your Docker Hub username
- Password: Your Docker Hub password/token
- ID: `docker-hub-credentials`
- Description: Docker Hub Login

### 3. SonarQube Credentials (ID: `sonarqube-token`)
- Kind: Username with password
- Username: admin
- Password: admin
- ID: `sonarqube-token`
- Description: SonarQube Authentication

**Note:** SonarQube default login is admin/admin for fresh installations

### 4. Kubernetes Config (ID: `kubeconfig`)
- Kind: Secret file
- File: Upload your ~/.kube/config file
- ID: `kubeconfig`
- Description: Kubernetes Configuration

**To get kubeconfig:**
```bash
cp ~/.kube/config ./kube-config-file
```
Then upload this file in Jenkins.

## Quick Setup Commands

Run these commands to prepare your credentials:

```bash
# Display your kubeconfig for copying
echo "Your kubeconfig location:"
ls -la ~/.kube/config

# Check if you're logged into Docker Hub
docker login

# Verify GitHub token (you'll need to create this)
echo "Go to: https://github.com/settings/tokens"
```

## Pipeline Configuration

After adding credentials, create a new Jenkins pipeline:
1. New Item → Pipeline
2. Name: `healthcare-app-pipeline`
3. Pipeline → Definition: "Pipeline script from SCM"
4. SCM: Git
5. Repository URL: Your GitHub repository URL
6. Credentials: Select your GitHub token
7. Branch: */main (or your branch)
8. Script Path: `Jenkinsfile`
9. Save

## Testing the Setup

Your pipeline will:
✅ Checkout code from GitHub
✅ Run tests (unit, integration, E2E)
✅ Perform security scanning
✅ Build Docker images
✅ Deploy to Kubernetes
✅ Set up monitoring
✅ Validate deployment

The entire pipeline should complete in 10-15 minutes.
