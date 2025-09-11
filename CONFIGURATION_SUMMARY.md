# Configuration Setup Complete!

## What We've Set Up

I've created a comprehensive configuration system for your healthcare application with all the tools you need to set up every variable properly.

## Configuration Tools Created

### **1. Interactive Setup Script** - `setup-config.sh`
**Purpose**: Guided setup for all configuration variables
```bash
# Run interactive setup
./setup-config.sh
```

**Features**:
- Step-by-step configuration wizard
- Input validation and error checking
- Gmail/Slack/Datadog setup instructions
- Automatic backup of existing configurations
- Menu-driven interface

### **2. Configuration Validation** - `validate-config.sh`
**Purpose**: Verify all configurations are correct
```bash
# Validate current configuration
./validate-config.sh
```

**Features**:
- Checks all required variables
- Validates email formats
- Verifies URL formats
- Runs Terraform validation
- Shows configuration summary

### **3. Complete Configuration Guide** - `CONFIGURATION_GUIDE.md`
**Purpose**: Comprehensive documentation for all variables
```bash
# Read the guide
cat CONFIGURATION_GUIDE.md
```

**Covers**:
- SMTP email setup (Gmail, Outlook, Yahoo)
- Slack webhook configuration
- Datadog APM and RUM setup
- MongoDB security configuration
- Resource limits and scaling
- Troubleshooting guide

## Configuration Variables Summary

### **REQUIRED Variables:**
```hcl
# SMTP Email (REQUIRED for alerts)
smtp_username = "your-email@gmail.com"
smtp_password = "your-gmail-app-password"
alert_email_critical = "critical-alerts@healthcare.company.com"

# Basic Environment
environment = "staging"
namespace = "healthcare"
```

### **OPTIONAL Variables:**
```hcl
# Slack Integration
slack_webhook_critical = "https://hooks.slack.com/services/YOUR/WEBHOOK"
slack_webhook_warning = "https://hooks.slack.com/services/YOUR/WEBHOOK"

# Datadog Monitoring
enable_datadog = true
datadog_api_key = "your-api-key"
datadog_app_key = "your-app-key"

# MongoDB (leave empty for auto-generation)
mongodb_root_password = "YourSecurePassword123!"
```

## Quick Setup Process

### **Step 1: Run Interactive Setup**
```bash
./setup-config.sh
```
Select option 1 to configure all variables interactively.

### **Step 2: Validate Configuration**
```bash
./validate-config.sh
```
Select option 1 to validate your configuration.

### **Step 3: Deploy**
```bash
./deploy-monitoring.sh staging
```

## 📧 Gmail Setup (Most Important)

### **Quick Gmail Setup:**
1. **Enable 2FA**: https://myaccount.google.com/security
2. **Generate App Password**: https://myaccount.google.com/apppasswords
3. **Use 16-character password** (not your regular password)

### **Configuration:**
```hcl
smtp_username = "your-email@gmail.com"
smtp_password = "abcd-efgh-ijkl-mnop"  # 16-char app password
```

## 💬 Slack Setup (Optional)

### **Quick Slack Setup:**
1. **Create App**: https://api.slack.com/apps
2. **Enable Webhooks**: Features → Incoming Webhooks
3. **Create webhooks** for critical and warning channels

### **Configuration:**
```hcl
slack_webhook_critical = "https://hooks.slack.com/services/YOUR/WEBHOOK"
slack_webhook_warning = "https://hooks.slack.com/services/YOUR/WEBHOOK"
```

## 🐶 Datadog Setup (Optional)

### **Quick Datadog Setup:**
1. **Sign Up**: https://www.datadoghq.com/
2. **Get API Keys**: Account Settings → API
3. **Create RUM App**: RUM → New Application

### **Configuration:**
```hcl
enable_datadog = true
datadog_api_key = "your-api-key"
datadog_app_key = "your-app-key"
datadog_rum_app_id = "your-rum-app-id"
datadog_rum_client_token = "your-rum-client-token"
```

## Access URLs (After Deployment)

### **Staging Environment:**
- **Grafana**: http://127.0.0.1:3000
- **Prometheus**: http://127.0.0.1:9090
- **Alertmanager**: http://127.0.0.1:9093
- **MongoDB Exporter**: http://127.0.0.1:9216

### **Default Credentials:**
- **Grafana**: admin / admin123

## Validation Checklist

Run `./validate-config.sh` to check:

- **SMTP credentials** configured
- **Email addresses** valid format
- **URLs** properly formatted
- **Terraform** configuration valid
- **Required variables** set
- **Optional variables** configured (if enabled)

## 🚨 Common Issues & Solutions

### **SMTP Authentication Failed**
```bash
# Check Gmail app password
./setup-config.sh  # Option 2 for Gmail instructions
```

### **Slack Webhooks Not Working**
```bash
# Verify webhook URLs
./setup-config.sh  # Option 3 for Slack instructions
```

### **Terraform Validation Errors**
```bash
# Validate configuration
./validate-config.sh
```

### **Deployment Issues**
```bash
# Check logs
kubectl logs -n monitoring-staging deployment/alertmanager
kubectl logs -n monitoring-staging deployment/prometheus
```

## 🎉 Ready to Deploy!

### **Complete Setup Process:**
```bash
# 1. Configure all variables
./setup-config.sh

# 2. Validate configuration
./validate-config.sh

# 3. Deploy monitoring stack
./deploy-monitoring.sh staging

# 4. Access monitoring
# Grafana: http://127.0.0.1:3000
```

## Support

### **Configuration Help:**
- Run `./setup-config.sh` for guided setup
- Read `CONFIGURATION_GUIDE.md` for detailed instructions
- Use `./validate-config.sh` to check your configuration

### **Deployment Help:**
- Check `MONITORING_GUIDE.md` for deployment instructions
- Review `DEPLOYMENT_SUMMARY.md` for access information
- Use `terraform validate` and `terraform plan` for debugging

---

## Next Steps

1. **Configure variables**: `./setup-config.sh`
2. **Validate setup**: `./validate-config.sh`
3. **Deploy stack**: `./deploy-monitoring.sh staging`
4. **Access monitoring**: http://127.0.0.1:3000
5. **Configure alerts**: Set up notification preferences

**Your healthcare application monitoring stack is now fully configured and ready for deployment! **

---

*Configuration Setup - Last Updated: 12 September 2025*
*Version: 1.0.0*
