# Healthcare Application Alerting Setup Guide

## Overview
This guide covers the setup of production-grade alerting for the Healthcare Application using Alertmanager, Prometheus, and Slack/email notifications.

## Prerequisites

### 1. Slack Webhook Setup
1. Go to https://api.slack.com/apps
2. Create a new app or use existing one
3. Add "Incoming Webhooks" feature
4. Create a webhook for each channel:
   - `#healthcare-critical` - Critical alerts
   - `#healthcare-alerts` - Warning alerts
   - `#healthcare-notifications` - General notifications
   - `#database-alerts` - Database-specific alerts
   - `#frontend-alerts` - Frontend-specific alerts
   - `#backend-alerts` - Backend-specific alerts

### 2. Email Configuration
1. Set up SMTP credentials for `healthcare-alerts@company.com`
2. Configure the following email addresses:
   - `healthcare-critical@company.com` - Critical alerts
   - `healthcare-alerts@company.com` - Warning alerts
   - `healthcare-team@company.com` - General notifications
   - `database-team@company.com` - Database alerts
   - `frontend-team@company.com` - Frontend alerts
   - `backend-team@company.com` - Backend alerts

## Configuration Steps

### 1. Update Alertmanager Configuration
Edit `monitoring/alertmanager.yml` and replace:
- `YOUR/SLACK/WEBHOOK` with actual Slack webhook URLs
- `your-smtp-password` with actual SMTP password
- Email addresses with actual team email addresses

### 2. Deploy Alertmanager
```bash
# Apply the configuration
kubectl apply -f monitoring/alertmanager.yml
kubectl apply -f monitoring/alerting_rules.yml
```

### 3. Verify Configuration
```bash
# Check Alertmanager status
kubectl get pods -l app=alertmanager
kubectl logs -l app=alertmanager

# Check Prometheus rules
kubectl get prometheusrules
kubectl describe prometheusrules healthcare-alerts
```

## Alert Categories

### Critical Alerts (Immediate Action Required)
- Database down
- Backend service down
- Frontend service down
- High error rate (>10%)
- Database disk space low (<10% free)

### Warning Alerts (Monitor Closely)
- High CPU usage (>80%)
- High memory usage (>90%)
- Slow response time (>2s 95th percentile)
- Database connection pool exhausted (>90%)

### Info Alerts (Awareness)
- Deployment completed
- Pod restarted
- High request rate
- Certificate expiry warning

## Testing Alerts

### Manual Alert Testing
```bash
# Test critical alert
curl -X POST http://alertmanager:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"TestCritical","severity":"critical","service":"test"},"annotations":{"summary":"Test critical alert","description":"This is a test critical alert"}}]'

# Test warning alert
curl -X POST http://alertmanager:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"TestWarning","severity":"warning","service":"test"},"annotations":{"summary":"Test warning alert","description":"This is a test warning alert"}}]'
```

### Automated Testing
```bash
# Run alert validation script
./scripts/test-alerts.sh
```

## Maintenance

### Regular Tasks
1. **Weekly**: Review alert history and adjust thresholds
2. **Monthly**: Test alert delivery to all channels
3. **Quarterly**: Review and update alert rules based on application changes

### Alert Tuning
- Adjust alert thresholds based on normal application behavior
- Add new alerts for newly monitored components
- Remove obsolete alerts for deprecated features

## Troubleshooting

### Common Issues

1. **Slack notifications not working**
   - Verify webhook URLs are correct
   - Check Slack app permissions
   - Ensure webhook is active

2. **Email notifications not working**
   - Verify SMTP credentials
   - Check email server connectivity
   - Validate sender email address

3. **Alerts not firing**
   - Check Prometheus rule syntax
   - Verify metric names and labels
   - Ensure Alertmanager is running

### Debug Commands
```bash
# Check alertmanager configuration
kubectl exec -it alertmanager-pod -- amtool check-config /etc/alertmanager/alertmanager.yml

# View active alerts
kubectl exec -it alertmanager-pod -- amtool alert

# Test email configuration
kubectl exec -it alertmanager-pod -- amtool template email --template-file /etc/alertmanager/templates/email.tmpl

# Check prometheus rules
kubectl exec -it prometheus-pod -- promtool check rules /etc/prometheus/alerting_rules.yml
```

## Integration with CI/CD

### Jenkins Integration
Add to Jenkins pipeline:
```groovy
stage('Validate Alerting') {
    steps {
        sh '''
            # Test alert configuration
            kubectl apply -f monitoring/alertmanager.yml
            kubectl apply -f monitoring/alerting_rules.yml

            # Validate configuration
            kubectl exec alertmanager-pod -- amtool check-config /etc/alertmanager/alertmanager.yml
        '''
    }
}
```

## Security Considerations

1. **Webhook Security**: Store Slack webhooks as Kubernetes secrets
2. **Email Credentials**: Use Kubernetes secrets for SMTP credentials
3. **Alert Encryption**: Ensure alert data is encrypted in transit
4. **Access Control**: Limit access to alert configuration

## Monitoring Alerting System

Monitor the alerting system itself:
- Alertmanager uptime
- Alert delivery success rate
- Alertmanager queue length
- Prometheus rule evaluation time
