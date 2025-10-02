#!/bin/bash

# Test Datadog US5 region connectivity
echo "🔍 Testing Datadog US5 region connectivity..."

# Check if we have the environment variables
if [ -z "$DATADOG_API_KEY" ] || [ -z "$DATADOG_APP_KEY" ]; then
    echo "❌ DATADOG_API_KEY or DATADOG_APP_KEY not set"
    echo "Please set these environment variables and try again"
    exit 1
fi

echo "✅ Datadog keys are set"
echo "API Key length: ${#DATADOG_API_KEY}"
echo "App Key length: ${#DATADOG_APP_KEY}"

# Test API key validation
echo ""
echo "🧪 Testing API key validation..."
VALIDATION_RESPONSE=$(curl -s -H "DD-API-KEY: $DATADOG_API_KEY" "https://api.us5.datadoghq.com/api/v1/validate")

if echo "$VALIDATION_RESPONSE" | grep -q '"valid":true'; then
    echo "✅ API key is valid for US5 region"
else
    echo "❌ API key validation failed"
    echo "Response: $VALIDATION_RESPONSE"
    exit 1
fi

# Test sending a simple event
echo ""
echo "🧪 Testing event creation..."
EVENT_RESPONSE=$(curl -s -X POST "https://api.us5.datadoghq.com/api/v1/events" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: $DATADOG_API_KEY" \
    -d '{
        "title": "Datadog US5 Region Test",
        "text": "Testing Datadog connectivity to US5 region",
        "priority": "normal",
        "tags": ["test", "us5", "connectivity"],
        "alert_type": "info"
    }')

if echo "$EVENT_RESPONSE" | grep -q '"status":"ok"'; then
    echo "✅ Event created successfully in US5 region"
    echo "Event ID: $(echo "$EVENT_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)"
else
    echo "❌ Event creation failed"
    echo "Response: $EVENT_RESPONSE"
    exit 1
fi

echo ""
echo "🎉 Datadog US5 region configuration is working correctly!"
