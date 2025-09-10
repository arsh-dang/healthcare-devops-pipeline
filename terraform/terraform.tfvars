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

# Namespace
namespace = "healthcare"
