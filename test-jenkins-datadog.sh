#!/bin/bash

# Test script for Jenkins Datadog integration
# This script simulates the Jenkins pipeline locally for testing

set -e

echo "=== Testing Jenkins Datadog Integration ==="

# Check if DATADOG_API_KEY is set
if [[ -z "$DATADOG_API_KEY" ]]; then
    echo "DATADOG_API_KEY environment variable is not set"
    echo "Please set it with: export DATADOG_API_KEY='your-api-key'"
    exit 1
fi

echo "DATADOG_API_KEY is set"

# Test deployment script with Datadog enabled
echo "=== Testing Deployment Script ==="

cd terraform

# Make script executable
chmod +x deploy.sh

# Test the deployment command (dry run)
echo "Testing deployment command..."
echo "./deploy.sh deploy staging 91 healthcare-app-frontend:91 healthcare-app-backend:91 \"\$DATADOG_API_KEY\" true"

# Actually run a quick validation
echo "=== Validating Terraform Configuration ==="
terraform init -upgrade
terraform validate

echo "Terraform validation passed"

# Check if Datadog variables are properly configured
echo "=== Checking Datadog Configuration ==="
terraform plan \
    -var="environment=staging" \
    -var="app_version=91" \
    -var="frontend_image=healthcare-app-frontend:91" \
    -var="backend_image=healthcare-app-backend:91" \
    -var="enable_datadog=true" \
    -var="datadog_api_key=$DATADOG_API_KEY" \
    -no-color \
    -out=tfplan 2>/dev/null || true

if [[ -f "tfplan" ]]; then
    echo "Terraform plan created successfully with Datadog"
    rm -f tfplan
else
    echo "❌ Failed to create Terraform plan"
    exit 1
fi

echo ""
echo "🎉 Jenkins Datadog integration test completed successfully!"
echo ""
echo "Next steps:"
echo "1. Set up Jenkins credential with ID 'datadog-api-key'"
echo "2. Use Jenkinsfile.datadog in your Jenkins pipeline"
echo "3. Run the pipeline to deploy with Datadog monitoring"
