# Datadog Cloud Integration - Healthcare Application

This directory contains the complete Datadog cloud integration for the Healthcare Application, implemented as Infrastructure as Code (IaC) with full automation.

## 🏗️ Architecture

The Datadog integration is built with:
- **Terraform IaC**: Complete infrastructure deployment
- **Automated Scripts**: Deployment and Jenkins integration
- **Cloud-based Monitoring**: No agent deployment required
- **API-driven Configuration**: Dashboards, monitors, and synthetic tests

## 📁 Directory Structure

```
datadog/
├── README.md                           # This file
├── dashboards/
│   └── healthcare-dashboard.json       # Healthcare app dashboard definition
├── alerts/
│   └── healthcare-alerts.json          # Alert definitions
└── scripts/
    ├── automated-setup.sh              # Complete automated setup
    ├── deploy-datadog.sh               # Terraform deployment script
    ├── setup-datadog.sh                # Manual setup script
    └── jenkins-datadog-integration.sh  # Jenkins pipeline integration
```

## 🚀 Quick Start

### Prerequisites

1. **Datadog Account**: Sign up at [datadoghq.com](https://www.datadoghq.com/)
2. **API Key**: Get your API key from [Application Keys](https://app.datadoghq.com/organization-settings/application-keys)
3. **Required Tools**:
   ```bash
   # Install required tools
   brew install terraform curl jq
   ```

### Automated Setup (Recommended)

```bash
# Set your Datadog API key
export DATADOG_API_KEY="your-datadog-api-key"

# Run complete automated setup
./datadog/scripts/automated-setup.sh
```

This will:
- ✅ Deploy all Datadog infrastructure via Terraform
- ✅ Create dashboards and monitors
- ✅ Set up synthetic tests
- ✅ Configure Jenkins integration
- ✅ Send initial metrics

## 📊 What Gets Created

### Dashboards
1. **Healthcare Application Dashboard**
   - Application health overview
   - Request rate and response time
   - Error rate monitoring
   - Database performance metrics
   - Infrastructure metrics (CPU, memory)
   - Business metrics (patient count, SLA)
   - API endpoint performance
   - Security events tracking

2. **Jenkins CI/CD Dashboard**
   - Pipeline execution time
   - Test results tracking
   - Deployment success rate
   - Build health monitoring

### Monitors (Alerts)
1. **High Error Rate** - API error rate > 5%
2. **High Response Time** - Response time > 2 seconds
3. **Database Connection Issues** - MongoDB connections > 80%
4. **High CPU Usage** - CPU usage > 80%
5. **High Memory Usage** - Memory usage > 85%
6. **Service Unavailable** - Health check failures
7. **Security Events** - Failed login attempts
8. **SLA Breach** - Uptime < 99.9%
9. **Deployment Failure** - Failed deployments
10. **Jenkins Pipeline Failure** - Build failures

### Synthetic Tests
1. **API Health Check** - HTTP endpoint monitoring
2. **Frontend Availability** - Browser-based testing

## 🔧 Manual Setup Options

### Option 1: Terraform Deployment Only
```bash
cd terraform
terraform init
terraform plan -var="datadog_api_key=your-key"
terraform apply -var="datadog_api_key=your-key"
```

### Option 2: Manual Dashboard Creation
```bash
# Create dashboard via API
curl -X POST "https://api.datadoghq.com/api/v1/dashboard" \
  -H "Content-Type: application/json" \
  -H "DD-API-KEY: your-api-key" \
  -d @datadog/dashboards/healthcare-dashboard.json
```

### Option 3: Manual Monitor Creation
```bash
# Create monitors via API
jq -c '.alerts[]' datadog/alerts/healthcare-alerts.json | while read alert; do
  curl -X POST "https://api.datadoghq.com/api/v1/monitor" \
    -H "Content-Type: application/json" \
    -H "DD-API-KEY: your-api-key" \
    -d "$alert"
done
```

## 🔗 Jenkins Integration

The Jenkins pipeline automatically integrates with Datadog:

### Pipeline Stages with Datadog Integration
1. **Datadog Setup** - Deploys infrastructure
2. **Build** - Sends build metrics
3. **Test** - Tracks test results
4. **Deploy** - Monitors deployment status
5. **Monitoring** - Sends completion events

### Metrics Sent by Jenkins
- `jenkins.build.duration` - Build stage duration
- `jenkins.build.status` - Build success/failure
- `jenkins.tests.passed` - Test pass count
- `jenkins.tests.failed` - Test failure count
- `jenkins.deployment.status` - Deployment status
- `jenkins.pipeline.success` - Overall pipeline success
- `jenkins.pipeline.duration` - Total pipeline duration

### Events Sent by Jenkins
- Pipeline start/completion events
- Build stage events
- Error events with context
- Deployment events

## 📈 Custom Metrics

The integration sends custom healthcare metrics:

### Application Metrics
- `healthcare.app.health` - Application health status
- `healthcare.api.requests` - API request count
- `healthcare.api.errors` - API error count
- `healthcare.api.response_time` - API response time

### Database Metrics
- `mongodb.connections.current` - Current connections
- `mongodb.connections.available` - Available connections
- `mongodb.operations.rate` - Operation rate

### Business Metrics
- `healthcare.patients.active` - Active patient count
- `healthcare.sla.uptime` - SLA uptime percentage
- `healthcare.deployment.status` - Deployment status

### Security Metrics
- `healthcare.security.failed_logins` - Failed login attempts

## 🔔 Notification Setup

### Slack Integration
1. Go to [Datadog Integrations](https://app.datadoghq.com/account/settings#integrations)
2. Enable Slack integration
3. Configure webhook URLs
4. Set up notification channels

### Email Notifications
1. Configure SMTP settings in Datadog
2. Set up email recipients
3. Configure escalation policies

### PagerDuty Integration
1. Enable PagerDuty integration in Datadog
2. Configure service keys
3. Set up escalation policies

## 🛠️ Troubleshooting

### Common Issues

1. **API Key Invalid**
   ```bash
   # Test API key
   curl -X GET "https://api.datadoghq.com/api/v1/validate" \
     -H "DD-API-KEY: your-api-key"
   ```

2. **Terraform Provider Issues**
   ```bash
   # Reinitialize Terraform
   cd terraform
   rm -rf .terraform
   terraform init
   ```

3. **Jenkins Integration Not Working**
   - Check DATADOG_API_KEY credential in Jenkins
   - Verify script permissions: `chmod +x datadog/scripts/*.sh`
   - Check Jenkins console logs for errors

4. **Metrics Not Appearing**
   - Verify metric names match dashboard queries
   - Check metric tags for consistency
   - Ensure metrics are being sent to correct environment

### Debug Mode
```bash
# Enable debug logging
export DD_LOG_LEVEL=DEBUG
./datadog/scripts/automated-setup.sh
```

## 📚 Documentation Links

- [Datadog Documentation](https://docs.datadoghq.com/)
- [Terraform Datadog Provider](https://registry.terraform.io/providers/DataDog/datadog/latest/docs)
- [Datadog API Reference](https://docs.datadoghq.com/api/)
- [Jenkins Datadog Plugin](https://plugins.jenkins.io/datadog/)

## 🔄 Updates and Maintenance

### Updating Dashboards
```bash
# Update dashboard configuration
vim datadog/dashboards/healthcare-dashboard.json

# Apply changes
cd terraform
terraform apply -target=datadog_dashboard.healthcare_app_dashboard
```

### Adding New Monitors
```bash
# Add new monitor to alerts file
vim datadog/alerts/healthcare-alerts.json

# Apply changes
cd terraform
terraform apply -target=datadog_monitor
```

### Scaling Synthetic Tests
```bash
# Add new synthetic test
vim terraform/datadog.tf

# Apply changes
cd terraform
terraform apply -target=datadog_synthetics_test
```

## 📞 Support

For issues with this Datadog integration:
1. Check the troubleshooting section above
2. Review Jenkins console logs
3. Check Datadog UI for metric delivery
4. Verify API key permissions

---

**Note**: This integration is designed for cloud-based Datadog monitoring. No Datadog agents are deployed to your infrastructure - all monitoring is done via API calls and cloud-based synthetic tests.
