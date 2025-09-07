#!/bin/bash

# Terraform Workspace Initialization Script
# Manages workspaces for different environments

ENVIRONMENT=${1:-staging}

echo "🏗️ Initializing Terraform workspace for environment: $ENVIRONMENT"

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# List current workspaces for debugging
echo "Current workspaces:"
terraform workspace list

# Check if workspace exists and select/create accordingly
if terraform workspace select $ENVIRONMENT 2>/dev/null; then
    echo "✅ Selected existing workspace: $ENVIRONMENT"
else
    echo "Creating new workspace: $ENVIRONMENT"
    if terraform workspace new $ENVIRONMENT; then
        echo "✅ Workspace '$ENVIRONMENT' created successfully"
    else
        echo "⚠️ Workspace creation might have failed, but continuing..."
        # Try to select again in case it was created by another process
        terraform workspace select $ENVIRONMENT || {
            echo "❌ Failed to create or select workspace: $ENVIRONMENT"
            exit 1
        }
    fi
fi

echo "✅ Terraform workspace '$ENVIRONMENT' is ready"
echo "Current workspace: $(terraform workspace show)"

# Show final workspace list
echo "Available workspaces:"
terraform workspace list

# Exit successfully
exit 0
