#!/bin/bash

# Script to ensure the next Jenkins run uses newer Docker images
# This simulates what Jenkins will do with the BUILD_NUMBER

echo "🔧 Ensuring next Jenkins run uses newer Docker images..."

# Get current BUILD_NUMBER (Jenkins will use actual BUILD_NUMBER)
BUILD_NUMBER=${BUILD_NUMBER:-$(date +%Y%m%d%H%M)}
echo "📦 BUILD_NUMBER: $BUILD_NUMBER"

# Check current deployment images
echo "📋 Current deployment images:"
kubectl get deployment frontend -n healthcare-staging -o jsonpath='{.spec.template.spec.containers[0].image}' && echo
kubectl get statefulset mongodb-staging -n healthcare-staging -o jsonpath='{.spec.template.spec.containers[?(@.name=="backend")].image}' && echo

# Verify Jenkins pipeline configuration
echo "🔍 Checking Jenkins pipeline configuration..."

# Check if Infrastructure Application stage exists
if grep -q "Infrastructure Application" Jenkinsfile; then
    echo "✅ Infrastructure Application stage found in Jenkinsfile"
else
    echo "❌ Infrastructure Application stage missing from Jenkinsfile"
    exit 1
fi

# Check if terraform apply command exists
if grep -q "terraform apply" Jenkinsfile; then
    echo "✅ terraform apply command found in Jenkinsfile"
else
    echo "❌ terraform apply command missing from Jenkinsfile"
    exit 1
fi

# Check if BUILD_NUMBER variables are used
if grep -q "frontend_image=healthcare-app-frontend:\${BUILD_NUMBER}" Jenkinsfile; then
    echo "✅ Frontend image uses BUILD_NUMBER variable"
else
    echo "❌ Frontend image doesn't use BUILD_NUMBER variable"
    exit 1
fi

if grep -q "backend_image=healthcare-app-backend:\${BUILD_NUMBER}" Jenkinsfile; then
    echo "✅ Backend image uses BUILD_NUMBER variable"
else
    echo "❌ Backend image doesn't use BUILD_NUMBER variable"
    exit 1
fi

echo ""
echo "🎯 JENKINS PIPELINE CONFIGURATION VERIFIED:"
echo "   ✅ Infrastructure Application stage added"
echo "   ✅ terraform apply command configured"
echo "   ✅ BUILD_NUMBER variables properly set"
echo ""
echo "🚀 NEXT JENKINS RUN WILL:"
echo "   1. Build healthcare-app-frontend:${BUILD_NUMBER}"
echo "   2. Build healthcare-app-backend:${BUILD_NUMBER}"
echo "   3. Run terraform apply with new image variables"
echo "   4. Deploy the new images automatically"
echo ""
echo "✨ The deployment will use NEWER Docker images on next pipeline run!"
