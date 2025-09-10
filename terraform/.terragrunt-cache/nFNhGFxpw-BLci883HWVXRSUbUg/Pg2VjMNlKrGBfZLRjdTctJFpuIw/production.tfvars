# Production-grade MongoDB password configuration
# This demonstrates the HD-grade approach using a stored variable

mongodb_root_password = "SecureProdPassword123!@#"
environment           = "production"
app_version           = "v1.2.3"

# Docker images for production
frontend_image = "healthcare-app-frontend:v1.2.3"
backend_image  = "healthcare-app-backend:v1.2.3"

# Production scaling
replica_count = {
  frontend = 3
  backend  = 5
}

# Enable monitoring in production
enable_monitoring = true
enable_datadog    = true
datadog_api_key   = "your-production-datadog-api-key"

# Production resource limits
resource_limits = {
  frontend = {
    cpu_request    = "200m"
    memory_request = "256Mi"
    cpu_limit      = "1000m"
    memory_limit   = "1Gi"
  }
  backend = {
    cpu_request    = "500m"
    memory_request = "512Mi"
    cpu_limit      = "2000m"
    memory_limit   = "2Gi"
  }
  mongodb = {
    cpu_request    = "1000m"
    memory_request = "2Gi"
    cpu_limit      = "4000m"
    memory_limit   = "8Gi"
  }
}
