#!/bin/bash

echo "🔍 Datadog US5 Region Authorization Test"
echo "========================================"
echo ""

# Check if arguments are provided
if [ $# -ne 2 ]; then
    echo "❌ Usage: $0 <API_KEY> <APP_KEY>"
    echo ""
    echo "📋 **To get your Datadog keys:**"
    echo "1. Go to: https://app.us5.datadoghq.com/organization-settings/application-keys"
    echo "2. Copy your API Key and Application Key"
    echo "3. Run: $0 'your-api-key' 'your-app-key'"
    echo ""
    echo "🔍 **Example:**"
    echo "  $0 'abc123def456' 'xyz789uvw012'"
    exit 1
fi

API_KEY="$1"
APP_KEY="$2"

echo "✅ Testing with provided keys"
echo "API Key: ${API_KEY:0:8}...${API_KEY: -4}"
echo "App Key: ${APP_KEY:0:8}...${APP_KEY: -4}"
echo ""

# Run the actual test
echo "🧪 Running Datadog authorization test..."
echo ""

if [ -f "./test-datadog-keys-us5.sh" ]; then
    ./test-datadog-keys-us5.sh "$API_KEY" "$APP_KEY"
    TEST_RESULT=$?
    
    echo ""
    echo "📊 **Test completed with exit code: $TEST_RESULT**"
    
    if [ $TEST_RESULT -eq 0 ]; then
        echo "🎉 **SUCCESS: Both Datadog keys are authorized for US5 region!**"
        echo "✅ Your Jenkins pipeline should now work with Datadog"
        echo "✅ Dashboards and metrics should be visible"
    else
        echo "❌ **FAILED: Some tests failed**"
        echo "Please check your Datadog keys and region configuration"
    fi
else
    echo "❌ Test script not found: test-datadog-keys-us5.sh"
    exit 1
fi
