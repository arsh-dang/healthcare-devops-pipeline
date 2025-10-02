#!/bin/bash

echo "🔍 Testing Datadog keys from Jenkins context..."
echo ""

# This script will be run in Jenkins context where the credentials are available
if [ -z "$DATADOG_API_KEY" ] || [ -z "$DATADOG_APP_KEY" ]; then
    echo "❌ DATADOG_API_KEY or DATADOG_APP_KEY not available in Jenkins context"
    echo "Please ensure the credentials are properly configured in Jenkins"
    exit 1
fi

echo "✅ Found Datadog keys in Jenkins context"
echo "API Key length: ${#DATADOG_API_KEY}"
echo "App Key length: ${#DATADOG_APP_KEY}"
echo ""

# Test 1: API Key validation
echo "🧪 Test 1: API Key validation..."
VALIDATION_RESPONSE=$(curl -s -H "DD-API-KEY: $DATADOG_API_KEY" "https://api.us5.datadoghq.com/api/v1/validate")

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
DASHBOARD_RESPONSE=$(curl -s -H "DD-API-KEY: $DATADOG_API_KEY" -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" "https://api.us5.datadoghq.com/api/v1/dashboard")

if echo "$DASHBOARD_RESPONSE" | grep -q '"dashboards"'; then
    echo "✅ App Key is authorized for US5 region"
    APP_KEY_OK=true
elif echo "$DASHBOARD_RESPONSE" | grep -q '"errors":\["Unauthorized"\]'; then
    echo "❌ App Key authorization failed - Unauthorized"
    APP_KEY_OK=false
else
    echo "⚠️  App Key response: $DASHBOARD_RESPONSE"
    APP_KEY_OK=false
fi

echo ""

# Test 3: Event creation
echo "🧪 Test 3: Event creation..."
EVENT_RESPONSE=$(curl -s -X POST "https://api.us5.datadoghq.com/api/v1/events" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: $DATADOG_API_KEY" \
    -d '{
        "title": "Jenkins Datadog Key Test",
        "text": "Testing Datadog keys from Jenkins context",
        "priority": "normal",
        "tags": ["test", "us5", "jenkins", "healthcare-app"],
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

# Test 4: Monitor creation (requires App Key)
echo "🧪 Test 4: Monitor creation..."
MONITOR_RESPONSE=$(curl -s -X POST "https://api.us5.datadoghq.com/api/v1/monitor" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: $DATADOG_API_KEY" \
    -H "DD-APPLICATION-KEY: $DATADOG_APP_KEY" \
    -d '{
        "name": "Jenkins Test Monitor",
        "type": "metric alert",
        "query": "avg(last_5m):avg:healthcare.test{env:test} > 0",
        "message": "Test monitor from Jenkins",
        "tags": ["env:test", "service:healthcare-app", "test:jenkins"],
        "options": {
            "thresholds": {
                "critical": 0
            },
            "notify_audit": false,
            "notify_no_data": true,
            "no_data_timeframe": 10,
            "include_tags": true
        }
    }')

if echo "$MONITOR_RESPONSE" | grep -q '"id"'; then
    echo "✅ Monitor creation successful"
    MONITOR_ID=$(echo "$MONITOR_RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    echo "📊 Monitor created with ID: $MONITOR_ID"
    MONITOR_OK=true
elif echo "$MONITOR_RESPONSE" | grep -q '"errors":\["Unauthorized"\]'; then
    echo "❌ Monitor creation failed - App Key lacks monitor permissions"
    MONITOR_OK=false
else
    echo "⚠️  Monitor creation response: $MONITOR_RESPONSE"
    MONITOR_OK=false
fi

echo ""
echo "📊 **Jenkins Datadog Key Test Results:**"
echo "• API Key: $([ "$API_KEY_OK" = true ] && echo "✅ Authorized" || echo "❌ Not Authorized")"
echo "• App Key: $([ "$APP_KEY_OK" = true ] && echo "✅ Authorized" || echo "❌ Not Authorized")"
echo "• Event Creation: $([ "$EVENT_OK" = true ] && echo "✅ Working" || echo "❌ Failed")"
echo "• Monitor Creation: $([ "$MONITOR_OK" = true ] && echo "✅ Working" || echo "❌ Failed")"
echo ""

if [ "$API_KEY_OK" = true ] && [ "$APP_KEY_OK" = true ] && [ "$EVENT_OK" = true ] && [ "$MONITOR_OK" = true ]; then
    echo "🎉 **All Datadog tests passed from Jenkins!**"
    echo "✅ Both keys are properly authorized for US5 region"
    echo "✅ Dashboards and monitors should work correctly"
    exit 0
else
    echo "❌ **Some tests failed from Jenkins!**"
    echo "Please check your Datadog keys and permissions"
    exit 1
fi
