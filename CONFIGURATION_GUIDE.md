# Healthcare Application Configuration Guide
## Complete Setup for All Variables

This guide provides comprehensive instructions for configuring all the variables required for your healthcare application monitoring stack.

## Configuration Overview

Your application requires configuration for several components:

### **Required Configuration:**
- **SMTP Email** - For alert notifications
- **MongoDB** - Database credentials
- **Basic Environment** - Environment settings

### **Optional Configuration:**
- **Slack** - Additional alert notifications
- **Datadog** - Advanced monitoring and APM
- **Resource Limits** - Performance tuning

## Quick Start

### **Option 1: Interactive Setup (Recommended)**
```bash
# Run the interactive configuration script
./setup-config.sh
```

### **Option 2: Manual Configuration**
```bash
# Edit the terraform variables file
nano terraform/terraform.tfvars
```

## 📧 SMTP Email Configuration (REQUIRED)

### **Step 1: Set up Gmail App Password**

1. **Enable 2-Factor Authentication (2FA)**:
   - Go to: https://myaccount.google.com/security
   - Sign in to your Google Account
   - Under "Signing in to Google" → Select "2-Step Verification"
   - Follow the steps to enable 2FA

2. **Generate App Password**:
   - Go to: https://myaccount.google.com/apppasswords
   - Sign in to your Google Account
   - Select "Mail" from the app dropdown
   - Select your device (or create custom name like "Terraform")
   - Click "Generate"
   - **Copy the 16-character password** (ignore spaces)

### **Step 2: Configure SMTP Variables**

```hcl
# SMTP Email Configuration
smtp_server = "smtp.gmail.com"
smtp_port = "587"
smtp_username = "your-email@gmail.com"        # Your Gmail address
smtp_password = "abcd-efgh-ijkl-mnop"         # 16-char app password
smtp_from_email = "alerts@healthcare.company.com"

# Alert Email Recipients
alert_email_critical = "critical-alerts@healthcare.company.com"
alert_email_warning = "alerts@healthcare.company.com"
alert_email_team = "team@healthcare.company.com"
```

### **Alternative SMTP Providers**

#### **Outlook/Hotmail**:
```hcl
smtp_server = "smtp-mail.outlook.com"
smtp_port = "587"
smtp_username = "your-email@outlook.com"
smtp_password = "your-app-password"
```

#### **Yahoo Mail**:
```hcl
smtp_server = "smtp.mail.yahoo.com"
smtp_port = "587"
smtp_username = "your-email@yahoo.com"
smtp_password = "your-app-password"
```

#### **Custom SMTP Server**:
```hcl
smtp_server = "your-smtp-server.com"
smtp_port = "587"  # or 465 for SSL
smtp_username = "your-username"
smtp_password = "your-password"
```

## 💬 Slack Configuration (OPTIONAL)

### **Step 1: Create Slack App**

1. **Create App**:
   - Go to: https://api.slack.com/apps
   - Click "Create New App" → "From scratch"
   - Name: "Healthcare Alerts"
   - Select your workspace

2. **Enable Incoming Webhooks**:
   - In app settings → "Features" → "Incoming Webhooks"
   - Toggle "Activate Incoming Webhooks" to ON
   - Click "Add New Webhook to Workspace"

3. **Create Webhooks for Channels**:
   - **Critical Alerts**: Select/create `#healthcare-critical` channel
   - **Warning Alerts**: Select/create `#healthcare-alerts` channel
   - Click "Authorize" for each
   - **Copy the webhook URLs**

### **Step 2: Configure Slack Variables**

```hcl
# Slack Configuration
slack_webhook_critical = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"
slack_webhook_warning = "https://hooks.slack.com/services/T00000000/B00000000/YYYYYYYYYYYYYYYYYYYYYYYY"
slack_channel_critical = "#healthcare-critical"
slack_channel_warning = "#healthcare-alerts"
```

## 🐶 Datadog Configuration (OPTIONAL)

### **Step 1: Create Datadog Account**

1. **Sign Up**:
   - Go to: https://www.datadoghq.com/
   - Sign up for a free account
   - Select your region (US/EU/Asia)

2. **Get API Keys**:
   - Go to: https://app.datadoghq.com/account/settings#api
   - **API Key**: Copy your existing API key
   - **Application Key**: Click "Create Application Key"
     - Name: "Healthcare Terraform"
     - Copy the generated key

3. **Set up RUM (Real User Monitoring)**:
   - Go to: https://app.datadoghq.com/rum/applications
   - Click "New Application"
   - Name: "Healthcare Frontend"
   - Type: "Web"
   - **Copy the Application ID and Client Token**

### **Step 2: Configure Datadog Variables**

```hcl
# Datadog Configuration
enable_datadog = true
datadog_api_key = "abcd1234efgh5678ijkl9012mnop3456"
datadog_app_key = "qrst7890uvwx1234yzab5678cdef9012"
datadog_rum_app_id = "abcd-1234-efgh-5678-ijkl-9012"
datadog_rum_client_token = "mnop3456qrst7890uvwx1234yzab5678"
```

## 🗄️ MongoDB Configuration

### **Option 1: Auto-generated Password (Recommended for Development)**

```hcl
mongodb_root_password = ""  # Leave empty for auto-generation
```

### **Option 2: Custom Password (Recommended for Production)**

```hcl
mongodb_root_password = "YourSecurePassword123!"
```

**Password Requirements:**
- Minimum 8 characters
- Mix of uppercase/lowercase letters
- Numbers and special characters
- Avoid common words

## ⚙️ Environment Configuration

### **Basic Environment Variables**

```hcl
# Environment Configuration
environment = "staging"          # or "production"
app_version = "latest"           # or specific version like "v1.2.3"
namespace = "healthcare"         # Kubernetes namespace
```

### **Docker Images**

```hcl
# Docker Images
frontend_image = "healthcare-frontend:latest"
backend_image = "healthcare-backend:latest"
```

## Resource Configuration

### **Replica Count**

```hcl
replica_count = {
  frontend = 2    # Number of frontend pods
  backend  = 3    # Number of backend pods
}
```

### **Resource Limits**

```hcl
resource_limits = {
  frontend = {
    cpu_request    = "100m"    # Minimum CPU
    memory_request = "128Mi"  # Minimum memory
    cpu_limit      = "500m"   # Maximum CPU
    memory_limit   = "512Mi"  # Maximum memory
  }
  backend = {
    cpu_request    = "200m"
    memory_request = "256Mi"
    cpu_limit      = "1000m"
    memory_limit   = "1Gi"
  }
}
```

## Complete Configuration Example

Here's a complete example configuration:

```hcl
# Environment Configuration
environment = "staging"
app_version = "latest"
namespace = "healthcare"

# Docker Images
frontend_image = "healthcare-frontend:latest"
backend_image = "healthcare-backend:latest"

# MongoDB Configuration
mongodb_root_password = "SecurePassword123!"

# SMTP Email Configuration (REQUIRED)
smtp_server = "smtp.gmail.com"
smtp_port = "587"
smtp_username = "your-email@gmail.com"
smtp_password = "abcd-efgh-ijkl-mnop"
smtp_from_email = "alerts@healthcare.company.com"

# Alert Email Recipients
alert_email_critical = "critical-alerts@healthcare.company.com"
alert_email_warning = "alerts@healthcare.company.com"
alert_email_team = "team@healthcare.company.com"

# Slack Configuration (OPTIONAL)
slack_webhook_critical = "https://hooks.slack.com/services/YOUR/CRITICAL/WEBHOOK"
slack_webhook_warning = "https://hooks.slack.com/services/YOUR/WARNING/WEBHOOK"
slack_channel_critical = "#healthcare-critical"
slack_channel_warning = "#healthcare-alerts"

# Datadog Configuration (OPTIONAL)
enable_datadog = true
datadog_api_key = "your-datadog-api-key"
datadog_app_key = "your-datadog-app-key"
datadog_rum_app_id = "your-rum-app-id"
datadog_rum_client_token = "your-rum-client-token"

# Resource Configuration
replica_count = {
  frontend = 2
  backend  = 3
}

resource_limits = {
  frontend = {
    cpu_request    = "100m"
    memory_request = "128Mi"
    cpu_limit      = "500m"
    memory_limit   = "512Mi"
  }
  backend = {
    cpu_request    = "200m"
    memory_request = "256Mi"
    cpu_limit      = "1000m"
    memory_limit   = "1Gi"
  }
}
```

## Validation & Deployment

### **Step 1: Validate Configuration**

```bash
# Navigate to terraform directory
cd terraform

# Validate configuration
terraform validate

# Check for any errors
terraform plan
```

### **Step 2: Deploy**

```bash
# Deploy the configuration
terraform apply

# Or use the automated script
cd ..
./deploy-monitoring.sh staging
```

### **Step 3: Verify Deployment**

```bash
# Check pod status
kubectl get pods -n monitoring-staging
kubectl get pods -n healthcare-staging

# Check services
kubectl get services -n monitoring-staging
kubectl get services -n healthcare-staging
```

## Troubleshooting

### **Common Issues:**

#### **1. SMTP Authentication Failed**
- Verify Gmail App Password is correct (16 characters, no spaces)
- Ensure 2FA is enabled on Gmail account
- Check if less secure app access is disabled

#### **2. Slack Webhooks Not Working**
- Verify webhook URLs are correct
- Ensure Slack app has permission to post to channels
- Check if channels exist and bot is added

#### **3. Datadog Connection Issues**
- Verify API keys are correct
- Check if Datadog account is active
- Ensure correct region is selected

#### **4. Terraform Validation Errors**
- Check for syntax errors in terraform.tfvars
- Ensure all required variables are set
- Verify variable types match definitions

### **Debug Commands:**

```bash
# Check terraform configuration
terraform validate
terraform plan

# Check Kubernetes resources
kubectl get all -n monitoring-staging
kubectl get all -n healthcare-staging

# Check logs
kubectl logs -n monitoring-staging deployment/alertmanager
kubectl logs -n monitoring-staging deployment/prometheus
kubectl logs -n monitoring-staging deployment/grafana
```

## Support

If you encounter issues:

1. **Run the setup script**: `./setup-config.sh`
2. **Check the logs**: `terraform apply -auto-approve`
3. **Validate configuration**: `terraform validate`
4. **Review this guide** for your specific setup

## Next Steps

After configuration:

1. **Deploy the stack**: `./deploy-monitoring.sh staging`
2. **Access monitoring**: http://127.0.0.1:3000 (Grafana)
3. **Configure alerts**: Set up notification channels
4. **Customize dashboards**: Add healthcare-specific metrics
5. **Test notifications**: Trigger test alerts

---

**Configuration Guide - Last Updated: 12 September 2025**
**Version: 1.0.0**
