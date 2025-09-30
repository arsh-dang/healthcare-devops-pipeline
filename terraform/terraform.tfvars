# Staging environment configuration for Healthcare App
# This file configures the Terraform deployment for staging

# Environment configuration
environment = "staging"
app_version = "latest"

# Docker images (will be built by Jenkins pipeline)
# Note: BUILD_NUMBER is passed as a Terraform variable via -var parameter
frontend_image = "healthcare-app-frontend:fixed4"
backend_image = "healthcare-app-backend:latest"

# MongoDB Configuration
mongodb_root_password = "healthcare-staging-2024"

# Monitoring
enable_monitoring = true
enable_datadog = true  # Enable Datadog for comprehensive monitoring

# Datadog Configuration (API key should be set via Jenkins credentials)
datadog_api_key = ""  # Will be set via Jenkins pipeline
datadog_app_key = ""  # Optional, for enhanced features

# Resource scaling for staging
replica_count = {
  frontend = 1
  backend  = 1
}

# SMTP Email Configuration (credentials via Jenkins/environment)
smtp_server = "smtp.gmail.com"
smtp_port = 587
smtp_username = ""  # Will be set via Jenkins credentials (SMTP_USER)
smtp_password = ""  # Will be set via Jenkins credentials (SMTP_PASS)
smtp_from_email = ""  # Will use smtp_username value

# Alert Email Recipients
alert_email_critical = "arshdang2@gmail.com"
alert_email_warning = "arshdang2@gmail.com"
alert_email_info = "arshdang2@gmail.com"

# Slack Configuration (disabled for staging)
slack_webhook_critical = ""
slack_webhook_warning = ""
slack_webhook_info = ""
slack_channel_critical = "#alerts-critical"
slack_channel_warning = "#alerts-warning"
slack_channel_info = "#alerts-info"

# Persistent storage (enabled with smart PVC handler)
enable_persistent_storage = true

# Network policies (enabled for security)
enable_network_policies = true

# Data transfer controls (enabled for compliance)
enable_data_transfer_controls = true

# Ingress monitoring (disabled for staging)
enable_ingress_monitoring = false

# Log aggregation (disabled for staging)
enable_log_aggregation = false

# Synthetic monitoring (disabled for staging)
enable_synthetic_monitoring = false

# Distributed tracing (enabled for request tracing)
enable_distributed_tracing = true