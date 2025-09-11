# SMTP Email Configuration Variables (Build Parameters)
variable "smtp_server" {
  description = "SMTP server hostname (build parameter)"
  type        = string
  default     = "smtp.gmail.com"
  sensitive   = false
}

variable "smtp_port" {
  description = "SMTP server port (build parameter)"
  type        = string
  default     = "587"
  sensitive   = false
}

variable "smtp_username" {
  description = "SMTP authentication username (build parameter)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "smtp_password" {
  description = "SMTP authentication password (build parameter)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "smtp_from_email" {
  description = "Email address to send alerts from (build parameter)"
  type        = string
  default     = "alerts@healthcare.company.com"
  sensitive   = false
}

variable "alert_email_critical" {
  description = "Email address for critical alerts (build parameter)"
  type        = string
  default     = "critical-alerts@healthcare.company.com"
  sensitive   = false
}

variable "alert_email_warning" {
  description = "Email address for warning alerts (build parameter)"
  type        = string
  default     = "alerts@healthcare.company.com"
  sensitive   = false
}

variable "alert_email_info" {
  description = "Email address for info alerts (build parameter)"
  type        = string
  default     = "info@healthcare.company.com"
  sensitive   = false
}

variable "alert_email_team" {
  description = "Email address for team alerts (build parameter)"
  type        = string
  default     = "team@healthcare.company.com"
  sensitive   = false
}

# Slack Configuration Variables (Build Parameters)
variable "slack_webhook_critical" {
  description = "Slack webhook URL for critical alerts (build parameter)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_webhook_warning" {
  description = "Slack webhook URL for warning alerts (build parameter)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_channel_critical" {
  description = "Slack channel for critical alerts (build parameter)"
  type        = string
  default     = "#healthcare-critical"
  sensitive   = false
}

variable "slack_channel_warning" {
  description = "Slack channel for warning alerts (build parameter)"
  type        = string
  default     = "#healthcare-alerts"
  sensitive   = false
}

variable "slack_webhook_info" {
  description = "Slack webhook URL for info alerts (build parameter)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_channel_info" {
  description = "Slack channel for info alerts (build parameter)"
  type        = string
  default     = "#healthcare-info"
  sensitive   = false
}

# =============================================================================
# MONITORING ENHANCEMENT VARIABLES
# =============================================================================

variable "enable_ingress_monitoring" {
  description = "Enable Nginx Ingress Controller for ingress monitoring"
  type        = bool
  default     = true
}

variable "enable_log_aggregation" {
  description = "Enable Fluent Bit for log aggregation"
  type        = bool
  default     = true
}

variable "enable_synthetic_monitoring" {
  description = "Enable synthetic monitoring for proactive health checks"
  type        = bool
  default     = true
}

variable "enable_distributed_tracing" {
  description = "Enable Jaeger for distributed tracing"
  type        = bool
  default     = true
}
