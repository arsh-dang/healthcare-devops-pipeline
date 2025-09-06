#!/bin/bash

# Terraform Workspace Initialization Script
# Manages workspaces for different environments

set -e

ENVIRONMENT=${1:-staging}

echo "🏗️ Initializing Terraform workspace for environment: $ENVIRONMENT"

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Create or select workspace
if terraform workspace list | grep -q "^[[:space:]]*$ENVIRONMENT[[:space:]]*$"; then
    echo "Selecting existing workspace: $ENVIRONMENT"
    terraform workspace select $ENVIRONMENT
else
    echo "Creating new workspace: $ENVIRONMENT"
    terraform workspace new $ENVIRONMENT
fi

echo "✅ Terraform workspace '$ENVIRONMENT' is ready"
echo "Current workspace: $(terraform workspace show)"

# Show workspace list
echo "Available workspaces:"
terraform workspace list
