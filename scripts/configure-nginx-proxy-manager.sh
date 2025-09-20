#!/bin/bash

# Nginx Proxy Manager Configuration Script
# This script configures Nginx Proxy Manager with the required proxy hosts

set -e

# Configuration variables
NPM_HOST="http://192.168.5.1:81"
NPM_USERNAME="admin@example.com"
NPM_PASSWORD="changeme"
NODE_IP="192.168.5.1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Configuring Nginx Proxy Manager...${NC}"

# Function to login and get token
login_npm() {
    echo "Logging into Nginx Proxy Manager..."
    local response=$(curl -s -X POST "${NPM_HOST}/api/tokens" \
        -H "Content-Type: application/json" \
        -d "{\"identity\":\"${NPM_USERNAME}\",\"secret\":\"${NPM_PASSWORD}\"}")

    local token=$(echo "$response" | jq -r '.token')
    if [ "$token" = "null" ] || [ -z "$token" ]; then
        echo -e "${RED}Failed to login to Nginx Proxy Manager${NC}"
        echo "Response: $response"
        exit 1
    fi

    echo -e "${GREEN}Successfully logged in${NC}"
    echo "$token"
}

# Function to create proxy host
create_proxy_host() {
    local token="$1"
    local domain="$2"
    local forward_host="$3"
    local forward_port="$4"
    local custom_locations="$5"

    echo "Creating proxy host for $domain..."

    local data="{
        \"domain_names\":[\"$domain\"],
        \"forward_host\":\"$forward_host\",
        \"forward_port\":$forward_port,
        \"forward_scheme\":\"http\",
        \"certificate_id\":null,
        \"ssl_forced\":false,
        \"hsts_enabled\":false,
        \"hsts_subdomains\":false,
        \"http2_support\":false,
        \"block_exploits\":false,
        \"caching_enabled\":false,
        \"websocket_support\":false,
        \"advanced_config\":\"\",
        \"enabled\":true,
        \"locations\":[$custom_locations],
        \"meta\":{
            \"letsencrypt_agree\":false,
            \"dns_challenge\":false
        }
    }"

    local response=$(curl -s -X POST "${NPM_HOST}/api/nginx/proxy-hosts" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$data")

    local id=$(echo "$response" | jq -r '.id')
    if [ "$id" = "null" ] || [ -z "$id" ]; then
        echo -e "${RED}Failed to create proxy host for $domain${NC}"
        echo "Response: $response"
        return 1
    fi

    echo -e "${GREEN}Successfully created proxy host for $domain (ID: $id)${NC}"
    return 0
}

# Main configuration
main() {
    # Login to get token
    local token=$(login_npm)

    # Create main healthcare app proxy host with custom locations
    local custom_locations="
        {
            \"path\":\"/api\",
            \"forward_host\":\"${NODE_IP}\",
            \"forward_port\":30001,
            \"forward_scheme\":\"http\",
            \"advanced_config\":\"\"
        },
        {
            \"path\":\"/grafana\",
            \"forward_host\":\"${NODE_IP}\",
            \"forward_port\":32679,
            \"forward_scheme\":\"http\",
            \"advanced_config\":\"\"
        },
        {
            \"path\":\"/prometheus\",
            \"forward_host\":\"${NODE_IP}\",
            \"forward_port\":32680,
            \"forward_scheme\":\"http\",
            \"advanced_config\":\"\"
        },
        {
            \"path\":\"/alertmanager\",
            \"forward_host\":\"${NODE_IP}\",
            \"forward_port\":32681,
            \"forward_scheme\":\"http\",
            \"advanced_config\":\"\"
        },
        {
            \"path\":\"/jaeger\",
            \"forward_host\":\"${NODE_IP}\",
            \"forward_port\":32682,
            \"forward_scheme\":\"http\",
            \"advanced_config\":\"\"
        }
    "

    create_proxy_host "$token" "healthcare-app.local" "$NODE_IP" 32678 "$custom_locations"

    echo -e "${GREEN}Nginx Proxy Manager configuration completed!${NC}"
    echo ""
    echo "Access your application at:"
    echo "- Main App: http://healthcare-app.local"
    echo "- API: http://healthcare-app.local/api"
    echo "- Grafana: http://healthcare-app.local/grafana"
    echo "- Prometheus: http://healthcare-app.local/prometheus"
    echo "- Alertmanager: http://healthcare-app.local/alertmanager"
    echo "- Jaeger: http://healthcare-app.local/jaeger"
    echo ""
    echo "Note: Add '192.168.5.1 healthcare-app.local' to your /etc/hosts file"
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}jq is required but not installed. Please install jq first.${NC}"
    exit 1
fi

# Run main function
main
