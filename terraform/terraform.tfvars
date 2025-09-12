# Staging environment configuration for Healthcare App
# This file configures the Terraform deployment for staging

# Environment configuration
environment = "staging"
app_version = "latest"

# Docker images (will be built by Jenkins pipeline)
frontend_image = "healthcare-app-frontend:latest"
backend_image = "healthcare-app-backend:latest"

# MongoDB Configuration
mongodb_root_password = "healthcare-staging-2024"

# Monitoring
enable_monitoring = true
enable_datadog = false  # Disable Datadog for staging to avoid costs

# Resource scaling for staging
replica_count = {
  frontend = 1
  backend  = 1
}

# SMTP Email Configuration (using mock values for staging)
smtp_server = "smtp.gmail.com"
smtp_port = 587
smtp_username = "staging-alerts@healthcare.local"
smtp_password = "mock-password"
smtp_from_email = "alerts@healthcare-staging.local"

# Alert Email Recipients
alert_email_critical = "admin@healthcare.local"
alert_email_warning = "team@healthcare.local"
alert_email_info = "info@healthcare.local"

# Slack Configuration (disabled for staging)
slack_webhook_critical = ""
slack_webhook_warning = ""
slack_webhook_info = ""
slack_channel_critical = "#alerts-critical"
slack_channel_warning = "#alerts-warning"
slack_channel_info = "#alerts-info"

# Persistent storage (disabled for staging to use emptyDir)
enable_persistent_storage = false

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

# Distributed tracing (enabled for staging)
enable_distributed_tracing = true