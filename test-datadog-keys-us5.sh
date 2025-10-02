#!/bin/bash

echo "🔍 Testing Datadog US5 region authorization..."
echo ""

# Check if keys are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "❌ Usage: $0 <API_KEY> <APP_KEY>"
    echo ""
    echo "Example:"
    echo "  $0 'your-api-key' 'your-app-key'"
    exit 1
fi

API_KEY="$1"
APP_KEY="$2"

echo "✅ Testing with provided keys"
echo "API Key length: ${#API_KEY}"
echo "App Key length: ${#APP_KEY}"
echo ""

# Test 1: API Key validation
echo "🧪 Test 1: API Key validation..."
VALIDATION_RESPONSE=$(curl -s -H "DD-API-KEY: $API_KEY" "https://api.us5.datadoghq.com/api/v1/validate")

if echo "$VALIDATION_RESPONSE" | grep -q '"valid":true'; then
    echo "✅ API Key is valid for US5 region"
    API_KEY_OK=true
else
    echo "❌ API Key validation failed"
    echo "Response: $VALIDATION_RESPONSE"
    API_KEY_OK=false
fi

echo ""

# Test 2: App Key authorization (try to get dashboards)
echo "🧪 Test 2: App Key authorization..."
DASHBOARD_RESPONSE=$(curl -s -H "DD-API-KEY: $API_KEY" -H "DD-APPLICATION-KEY: $APP_KEY" "https://api.us5.datadoghq.com/api/v1/dashboard")

if echo "$DASHBOARD_RESPONSE" | grep -q '"dashboards"'; then
    echo "✅ App Key is authorized for US5 region"
    APP_KEY_OK=true
else
    echo "❌ App Key authorization failed"
    echo "Response: $DASHBOARD_RESPONSE"
    APP_KEY_OK=false
fi

echo ""

# Test 3: Event creation
echo "🧪 Test 3: Event creation..."
EVENT_RESPONSE=$(curl -s -X POST "https://api.us5.datadoghq.com/api/v1/events" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: $API_KEY" \
    -d '{
        "title": "Datadog US5 Authorization Test",
        "text": "Testing Datadog connectivity and authorization to US5 region",
        "priority": "normal",
        "tags": ["test", "us5", "authorization", "healthcare-app"],
        "alert_type": "info"
    }')

if echo "$EVENT_RESPONSE" | grep -q '"status":"ok"'; then
    echo "✅ Event creation successful"
    EVENT_ID=$(echo "$EVENT_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    echo "📝 Event created with ID: $EVENT_ID"
    EVENT_OK=true
else
    echo "❌ Event creation failed"
    echo "Response: $EVENT_RESPONSE"
    EVENT_OK=false
fi

echo ""
echo "📊 **Authorization Test Results:**"
echo "• API Key: $([ "$API_KEY_OK" = true ] && echo "✅ Authorized" || echo "❌ Not Authorized")"
echo "• App Key: $([ "$APP_KEY_OK" = true ] && echo "✅ Authorized" || echo "❌ Not Authorized")"
echo "• Event Creation: $([ "$EVENT_OK" = true ] && echo "✅ Working" || echo "❌ Failed")"
echo ""

if [ "$API_KEY_OK" = true ] && [ "$APP_KEY_OK" = true ] && [ "$EVENT_OK" = true ]; then
    echo "🎉 **All Datadog US5 region tests passed!**"
    echo "✅ Both keys are properly authorized for US5 region"
    echo "✅ Dashboards and metrics should work correctly"
    echo ""
    echo "🔍 **Next steps:**"
    echo "1. Check your Datadog dashboard at: https://app.us5.datadoghq.com/"
    echo "2. Run your Jenkins pipeline to see events and metrics"
    echo "3. Look for the test event we just created"
    exit 0
else
    echo "❌ **Some tests failed!**"
    echo "Please check your Datadog keys and region configuration"
    echo ""
    echo "🔍 **Troubleshooting:**"
    echo "• Verify your keys are for US5 region"
    echo "• Check that your keys have the correct permissions"
    echo "• Ensure your Datadog account is active"
    exit 1
fi
