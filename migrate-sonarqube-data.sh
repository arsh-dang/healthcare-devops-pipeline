#!/bin/bash

echo "🔄 SonarQube Data Migration Script"
echo "=================================="
echo ""

# Check if Docker volumes exist
if ! docker volume ls | grep -q sonarqube_data; then
    echo "❌ SonarQube Docker volume not found"
    exit 1
fi

echo "📋 Found SonarQube Docker volumes:"
docker volume ls | grep sonar
echo ""

# Create a temporary container to access the data
echo "📦 Creating temporary container to access SonarQube data..."
docker run --rm -d --name sonarqube-migration \
    -v sonarqube_data:/data \
    -v sonarqube_logs:/logs \
    -v sonarqube_extensions:/extensions \
    alpine:latest sleep 3600

echo "✅ Temporary container created"
echo ""

# Check the data in the volumes
echo "📋 SonarQube data structure:"
docker exec sonarqube-migration ls -la /data
echo ""

echo "📋 SonarQube logs structure:"
docker exec sonarqube-migration ls -la /logs
echo ""

echo "📋 SonarQube extensions structure:"
docker exec sonarqube-migration ls -la /extensions
echo ""

# Clean up
docker stop sonarqube-migration
echo "✅ Temporary container cleaned up"
echo ""

echo "💡 Data migration will be handled by Terraform when SonarQube is deployed"
echo "The PVC will be created fresh, but the Docker volumes contain valuable data"
echo "that should be preserved for future use."
