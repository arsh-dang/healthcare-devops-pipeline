# Core Application Variables
variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  default     = "staging"
}

variable "app_version" {
  description = "Application version/build number for deployment"
  type        = string
  default     = "latest"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "healthcare"
}

variable "frontend_image" {
  description = "Frontend Docker image with tag"
  type        = string
  default     = "healthcare-app-frontend:latest"
}

variable "backend_image" {
  description = "Backend Docker image with tag"
  type        = string
  default     = "healthcare-app-backend:latest"
}

variable "replica_count" {
  description = "Number of replicas for each service"
  type        = map(number)
  default = {
    frontend = 2
    backend  = 3
  }
}

# Monitoring Variables
variable "enable_monitoring" {
  description = "Enable monitoring stack deployment"
  type        = bool
  default     = true
}

variable "enable_datadog" {
  description = "Enable Datadog agent deployment"
  type        = bool
  default     = false
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog Application key (optional, for enhanced features)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "datadog_rum_app_id" {
  description = "Datadog RUM Application ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "datadog_rum_client_token" {
  description = "Datadog RUM Client Token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "monitoring_retention_days" {
  description = "Prometheus data retention in days"
  type        = number
  default     = 15
}

# Database Variables
variable "mongodb_root_password" {
  description = "MongoDB root password (leave empty for auto-generation)"
  type        = string
  default     = ""
  sensitive   = true
}

# Resource Management Variables
variable "resource_limits" {
  description = "Resource limits for containers"
  type = map(object({
    cpu_request    = string
    memory_request = string
    cpu_limit      = string
    memory_limit   = string
  }))
  default = {
    frontend = {
      cpu_request    = "100m"
      memory_request = "128Mi"
      cpu_limit      = "500m"
      memory_limit   = "512Mi"
    }
    backend = {
      cpu_request    = "20m"  # Fixed: Reduced from 200m to 20m to prevent pod scheduling issues
      memory_request = "256Mi"
      cpu_limit      = "1000m"
      memory_limit   = "1Gi"
    }
    mongodb = {
      cpu_request    = "500m"
      memory_request = "1Gi"
      cpu_limit      = "2000m"
      memory_limit   = "4Gi"
    }
  }
}

# Security Variables
variable "enable_encryption" {
  description = "Enable data encryption at rest (local encryption only)"
  type        = bool
  default     = false
}

variable "enable_network_policies" {
  description = "Enable comprehensive network policies"
  type        = bool
  default     = true
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for ingress"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "enable_data_transfer_controls" {
  description = "Enable data transfer controls for GDPR compliance"
  type        = bool
  default     = true
}

# Kubernetes Configuration Variables
variable "kubeconfig_path" {
  description = "Path to kubeconfig file (leave empty to use default)"
  type        = string
  default     = ""
}

variable "kubernetes_host" {
  description = "Kubernetes cluster host URL"
  type        = string
  default     = ""
}

variable "kubernetes_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  type        = string
  default     = ""
}

variable "kubernetes_client_certificate" {
  description = "Kubernetes client certificate"
  type        = string
  default     = ""
}

variable "kubernetes_client_key" {
  description = "Kubernetes client key"
  type        = string
  default     = ""
}

# Monitoring Variables (continued)
variable "enable_persistent_storage" {
  description = "Enable persistent storage for monitoring components"
  type        = bool
  default     = false
}

variable "enable_ingress_monitoring" {
  description = "Enable ingress monitoring with Nginx Ingress Controller"
  type        = bool
  default     = true
}

variable "enable_log_aggregation" {
  description = "Enable log aggregation with Fluent Bit"
  type        = bool
  default     = false
}

variable "enable_synthetic_monitoring" {
  description = "Enable synthetic monitoring for health checks"
  type        = bool
  default     = false
}

variable "enable_distributed_tracing" {
  description = "Enable distributed tracing with Jaeger"
  type        = bool
  default     = false
}

# SMTP Configuration for Alertmanager
variable "smtp_server" {
  description = "SMTP server hostname"
  type        = string
  default     = ""
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = number
  default     = 587
}

variable "smtp_username" {
  description = "SMTP authentication username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "smtp_password" {
  description = "SMTP authentication password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "smtp_from_email" {
  description = "Email address to send alerts from"
  type        = string
  default     = "alerts@healthcare-app.local"
}

# Email Alert Recipients
variable "alert_email_critical" {
  description = "Email address for critical alerts"
  type        = string
  default     = ""
}

variable "alert_email_warning" {
  description = "Email address for warning alerts"
  type        = string
  default     = ""
}

variable "alert_email_info" {
  description = "Email address for info alerts"
  type        = string
  default     = ""
}

variable "alert_email_team" {
  description = "Email address for team notifications"
  type        = string
  default     = ""
}

# Slack Integration
variable "slack_webhook_critical" {
  description = "Slack webhook URL for critical alerts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_webhook_warning" {
  description = "Slack webhook URL for warning alerts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_webhook_info" {
  description = "Slack webhook URL for info alerts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_channel_critical" {
  description = "Slack channel for critical alerts"
  type        = string
  default     = "#alerts-critical"
}

variable "slack_channel_warning" {
  description = "Slack channel for warning alerts"
  type        = string
  default     = "#alerts-warning"
}

variable "slack_channel_info" {
  description = "Slack channel for info alerts"
  type        = string
  default     = "#alerts-info"
}

variable "smtp_tls" {
  description = "Enable TLS for SMTP"
  type        = bool
  default     = true
}

variable "enable_nginx_proxy_manager" {
  description = "Enable Nginx Proxy Manager for advanced routing"
  type        = bool
  default     = false
}

# Service Access Variables
variable "enable_service_access" {
  description = "Enable automated service access setup with port forwarding"
  type        = bool
  default     = true
}
