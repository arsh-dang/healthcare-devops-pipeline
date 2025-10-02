#!/bin/bash

echo "🔍 Testing Datadog keys as Jenkins would with arshdang/password@123..."
echo ""

# Check if we can access Jenkins credentials
JENKINS_URL="http://localhost:8080"
JENKINS_USER="arshdang"
JENKINS_PASS="password@123"

echo "🔐 Testing Jenkins authentication..."
AUTH_RESPONSE=$(curl -s -u "$JENKINS_USER:$JENKINS_PASS" "$JENKINS_URL/api/json" 2>/dev/null)

if echo "$AUTH_RESPONSE" | grep -q '"mode":"NORMAL"'; then
    echo "✅ Jenkins authentication successful with arshdang/password@123"
    
    echo ""
    echo "📋 Checking Datadog credentials in Jenkins..."
    
    # Check if credentials exist
    API_KEY_EXISTS=$(curl -s -u "$JENKINS_USER:$JENKINS_PASS" "$JENKINS_URL/credentials/store/system/domain/_/credential/datadog-api-key/api/json" 2>/dev/null | grep -o '"id":"datadog-api-key"' || echo "")
    APP_KEY_EXISTS=$(curl -s -u "$JENKINS_USER:$JENKINS_PASS" "$JENKINS_URL/credentials/store/system/domain/_/credential/datadog-app-key/api/json" 2>/dev/null | grep -o '"id":"datadog-app-key"' || echo "")
    
    if [ -n "$API_KEY_EXISTS" ] && [ -n "$APP_KEY_EXISTS" ]; then
        echo "✅ Both Datadog credentials found in Jenkins"
        echo ""
        echo "🧪 **Note: Cannot retrieve actual credential values via API for security reasons**"
        echo "📋 **To test the actual keys, you need to:**"
        echo "1. Run the Jenkins pipeline with the test stage"
        echo "2. Or manually set the environment variables and run the test script"
        echo ""
        echo "🔍 **Expected test results based on pipeline logs:**"
        echo "• API Key: ✅ WORKING (Events and metrics successful)"
        echo "• App Key: ❌ NEEDS PERMISSIONS (Dashboards and monitors failed)"
        echo ""
        echo "📋 **To fix the App Key permissions:**"
        echo "1. Go to: https://app.us5.datadoghq.com/organization-settings/application-keys"
        echo "2. Update your App Key permissions"
        echo "3. Re-run the pipeline to test"
    else
        echo "❌ Datadog credentials not found in Jenkins"
        echo "Please ensure both 'datadog-api-key' and 'datadog-app-key' are configured"
    fi
else
    echo "❌ Jenkins authentication failed"
    echo "Please check Jenkins credentials and connectivity"
fi
