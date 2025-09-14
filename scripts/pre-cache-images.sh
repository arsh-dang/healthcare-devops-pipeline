#!/bin/bash

# Script to pre-cache Docker base images for healthcare app builds
# This helps prevent build failures due to missing base images

set -e

echo "=== Healthcare App Base Image Pre-caching Script ==="
echo "This script will download and cache required base images locally"
echo ""

# Required base images for the healthcare app
BASE_IMAGES=(
    "node:20-alpine"
    "nginx:1.25.3-alpine"
)

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    exit 1
fi

echo "Checking Docker connectivity..."
if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running or not accessible"
    exit 1
fi

echo "Pre-caching base images..."
echo ""

SUCCESS_COUNT=0
TOTAL_COUNT=${#BASE_IMAGES[@]}

for image in "${BASE_IMAGES[@]}"; do
    echo "Processing: $image"

    # Check if image already exists locally
    if docker images "$image" | grep -q "$(basename "$image")"; then
        echo "  ✓ Already cached: $image"
        ((SUCCESS_COUNT++))
        continue
    fi

    # Try to pull the image
    echo "  Pulling: $image"
    if docker pull "$image"; then
        echo "  ✓ Successfully cached: $image"
        ((SUCCESS_COUNT++))
    else
        echo "  ✗ Failed to pull: $image"
        echo "    This may be due to network issues. The build will fail if this image is needed."
    fi

    echo ""
done

echo "=== Summary ==="
echo "Successfully cached: $SUCCESS_COUNT/$TOTAL_COUNT base images"
echo ""

if [ "$SUCCESS_COUNT" -eq "$TOTAL_COUNT" ]; then
    echo "✅ All base images are now cached locally!"
    echo "Your Jenkins builds should now work even without internet connectivity."
else
    echo "⚠️  Some base images could not be cached."
    echo "This may cause build failures when network connectivity is poor."
    echo ""
    echo "To retry, ensure you have internet connectivity and run this script again."
    exit 1
fi

echo ""
echo "You can verify the cached images with: docker images"
echo "The cached images will be used automatically by your Jenkins pipeline."
