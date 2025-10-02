#!/bin/bash

echo "🔍 Testing Datadog App Key specifically..."
echo ""

# Check if App Key is provided
if [ -z "$1" ]; then
    echo "❌ Usage: $0 <APP_KEY>"
    echo ""
    echo "📋 **To get your Datadog App Key:**"
    echo "1. Go to: https://app.us5.datadoghq.com/organization-settings/application-keys"
    echo "2. Copy your Application Key"
    echo "3. Run: $0 'your-app-key'"
    echo ""
    echo "🔍 **Example:**"
    echo "  $0 'abc123def456'"
    exit 1
fi

APP_KEY="$1"

echo "✅ Testing with provided App Key"
echo "App Key: ${APP_KEY:0:8}...${APP_KEY: -4}"
echo ""

# Test 1: App Key authorization (try to get dashboards)
echo "🧪 Test 1: App Key authorization (Dashboard Access)..."
DASHBOARD_RESPONSE=$(curl -s -H "DD-APPLICATION-KEY: $APP_KEY" "https://api.us5.datadoghq.com/api/v1/dashboard")

if echo "$DASHBOARD_RESPONSE" | grep -q '"dashboards"'; then
    echo "✅ App Key is authorized for dashboard access"
    APP_KEY_OK=true
elif echo "$DASHBOARD_RESPONSE" | grep -q '"errors":\["Unauthorized"\]'; then
    echo "❌ App Key authorization failed - Unauthorized"
    APP_KEY_OK=false
else
    echo "⚠️  App Key response: $DASHBOARD_RESPONSE"
    APP_KEY_OK=false
fi

echo ""

# Test 2: App Key authorization (try to get monitors)
echo "🧪 Test 2: App Key authorization (Monitor Access)..."
MONITOR_RESPONSE=$(curl -s -H "DD-APPLICATION-KEY: $APP_KEY" "https://api.us5.datadoghq.com/api/v1/monitor")

if echo "$MONITOR_RESPONSE" | grep -q '"monitors"'; then
    echo "✅ App Key is authorized for monitor access"
    MONITOR_ACCESS_OK=true
elif echo "$MONITOR_RESPONSE" | grep -q '"errors":\["Unauthorized"\]'; then
    echo "❌ App Key authorization failed for monitors - Unauthorized"
    MONITOR_ACCESS_OK=false
else
    echo "⚠️  Monitor access response: $MONITOR_RESPONSE"
    MONITOR_ACCESS_OK=false
fi

echo ""

# Test 3: App Key authorization (try to get synthetic tests)
echo "🧪 Test 3: App Key authorization (Synthetic Test Access)..."
SYNTHETIC_RESPONSE=$(curl -s -H "DD-APPLICATION-KEY: $APP_KEY" "https://api.us5.datadoghq.com/api/v1/synthetics/tests")

if echo "$SYNTHETIC_RESPONSE" | grep -q '"tests"'; then
    echo "✅ App Key is authorized for synthetic test access"
    SYNTHETIC_ACCESS_OK=true
elif echo "$SYNTHETIC_RESPONSE" | grep -q '"errors":\["Unauthorized"\]'; then
    echo "❌ App Key authorization failed for synthetic tests - Unauthorized"
    SYNTHETIC_ACCESS_OK=false
else
    echo "⚠️  Synthetic test access response: $SYNTHETIC_RESPONSE"
    SYNTHETIC_ACCESS_OK=false
fi

echo ""

# Test 4: App Key authorization (try to get log pipelines)
echo "🧪 Test 4: App Key authorization (Log Pipeline Access)..."
LOG_PIPELINE_RESPONSE=$(curl -s -H "DD-APPLICATION-KEY: $APP_KEY" "https://api.us5.datadoghq.com/api/v1/logs/config/pipelines")

if echo "$LOG_PIPELINE_RESPONSE" | grep -q '"pipelines"'; then
    echo "✅ App Key is authorized for log pipeline access"
    LOG_PIPELINE_ACCESS_OK=true
elif echo "$LOG_PIPELINE_RESPONSE" | grep -q '"errors":\["Unauthorized"\]'; then
    echo "❌ App Key authorization failed for log pipelines - Unauthorized"
    LOG_PIPELINE_ACCESS_OK=false
else
    echo "⚠️  Log pipeline access response: $LOG_PIPELINE_RESPONSE"
    LOG_PIPELINE_ACCESS_OK=false
fi

echo ""

# Test 5: App Key authorization (try to get organization settings)
echo "🧪 Test 5: App Key authorization (Organization Settings Access)..."
ORG_RESPONSE=$(curl -s -H "DD-APPLICATION-KEY: $APP_KEY" "https://api.us5.datadoghq.com/api/v1/org")

if echo "$ORG_RESPONSE" | grep -q '"org"'; then
    echo "✅ App Key is authorized for organization settings access"
    ORG_ACCESS_OK=true
elif echo "$ORG_RESPONSE" | grep -q '"errors":\["Unauthorized"\]'; then
    echo "❌ App Key authorization failed for organization settings - Unauthorized"
    ORG_ACCESS_OK=false
else
    echo "⚠️  Organization settings access response: $ORG_RESPONSE"
    ORG_ACCESS_OK=false
fi

echo ""
echo "📊 **Datadog App Key Test Results:**"
echo "• Dashboard Access: $([ "$APP_KEY_OK" = true ] && echo "✅ Authorized" || echo "❌ Not Authorized")"
echo "• Monitor Access: $([ "$MONITOR_ACCESS_OK" = true ] && echo "✅ Authorized" || echo "❌ Not Authorized")"
echo "• Synthetic Test Access: $([ "$SYNTHETIC_ACCESS_OK" = true ] && echo "✅ Authorized" || echo "❌ Not Authorized")"
echo "• Log Pipeline Access: $([ "$LOG_PIPELINE_ACCESS_OK" = true ] && echo "✅ Authorized" || echo "❌ Not Authorized")"
echo "• Organization Settings Access: $([ "$ORG_ACCESS_OK" = true ] && echo "✅ Authorized" || echo "❌ Not Authorized")"
echo ""

# Count successful tests
SUCCESS_COUNT=0
[ "$APP_KEY_OK" = true ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ "$MONITOR_ACCESS_OK" = true ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ "$SYNTHETIC_ACCESS_OK" = true ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ "$LOG_PIPELINE_ACCESS_OK" = true ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
[ "$ORG_ACCESS_OK" = true ] && SUCCESS_COUNT=$((SUCCESS_COUNT + 1))

echo "📊 **Overall App Key Status: $SUCCESS_COUNT/5 tests passed**"
echo ""

if [ $SUCCESS_COUNT -eq 5 ]; then
    echo "🎉 **App Key has full permissions!**"
    echo "✅ All Datadog features should work correctly"
    exit 0
elif [ $SUCCESS_COUNT -gt 0 ]; then
    echo "⚠️  **App Key has partial permissions**"
    echo "Some features will work, others may fail"
    echo ""
    echo "📋 **To get full permissions:**"
    echo "1. Go to: https://app.us5.datadoghq.com/organization-settings/application-keys"
    echo "2. Update your App Key permissions"
    echo "3. Re-run this test"
    exit 1
else
    echo "❌ **App Key has no permissions!**"
    echo "Please check your App Key and permissions"
    echo ""
    echo "📋 **To fix:**"
    echo "1. Go to: https://app.us5.datadoghq.com/organization-settings/application-keys"
    echo "2. Update your App Key permissions"
    echo "3. Re-run this test"
    exit 1
fi
