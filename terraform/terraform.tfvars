# Terraform variables for staging environment
environment = "staging"
app_version = "latest"

# Docker images
frontend_image = "healthcare-frontend:latest"
backend_image = "healthcare-backend:latest"

# MongoDB Configuration
mongodb_root_password = ""

# Monitoring
enable_datadog = false
datadog_api_key = ""

# Resource scaling for staging
replica_count = {
  frontend = 2
}

# Staging resource limits
resource_limits = {
  frontend = {
    cpu_request = "100m"
    memory_request = "128Mi"
    cpu_limit = "500m"
    memory_limit = "512Mi"
  }
  backend = {
    cpu_request = "200m"
    memory_request = "256Mi"
    cpu_limit = "1000m"
    memory_limit = "1Gi"
  }
}

# SMTP Email Configuration (BUILD PARAMETERS - Set via environment variables)
# smtp_server = "smtp.gmail.com"
# smtp_port = "587"
# smtp_username = "your-email@gmail.com"
# smtp_password = "your-gmail-app-password"
# smtp_from_email = "alerts@healthcare.company.com"

# Alert Email Recipients (BUILD PARAMETERS - Set via environment variables)
# alert_email_critical = "critical-alerts@healthcare.company.com"
# alert_email_warning = "alerts@healthcare.company.com"
# alert_email_team = "team@healthcare.company.com"

# Slack Configuration (BUILD PARAMETERS - Set via environment variables)
# slack_webhook_critical = "https://hooks.slack.com/services/YOUR/WEBHOOK"
# slack_webhook_warning = "https://hooks.slack.com/services/YOUR/WEBHOOK"
# slack_channel_critical = "#healthcare-critical"
# slack_channel_warning = "#healthcare-alerts"
