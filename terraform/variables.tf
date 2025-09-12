# Monitoring Variables
variable "enable_persistent_storage" {
  description = "Enable persistent storage for monitoring components"
  type        = bool
  default     = false
}

variable "enable_ingress_monitoring" {
  description = "Enable ingress monitoring with Nginx Ingress Controller"
  type        = bool
  default     = false
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
