# Healthcare DevOps Infrastructure as Code
# Supports multiple environments with integrated monitoring

# Variables for environment configuration
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

variable "mongodb_root_password" {
  description = "MongoDB root password (leave empty for auto-generation)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "monitoring_retention_days" {
  description = "Prometheus data retention in days"
  type        = number
  default     = 15
}

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
      cpu_request    = "50m"
      memory_request = "64Mi"
      cpu_limit      = "200m"
      memory_limit   = "128Mi"
    }
    backend = {
      cpu_request    = "200m"
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

variable "enable_encryption" {
  description = "Enable data encryption at rest (local encryption only)"
  type        = bool
  default     = false
}

# Removed AWS KMS key ID variable - using local encryption instead
# variable "kms_key_id" {
#   description = "KMS key ID for encryption (leave empty for auto-generation)"
#   type        = string
#   default     = ""
#   sensitive   = true
# }

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
}

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

# Alerting Configuration Variables

variable "alert_email_from" {
  description = "Email address for sending alerts"
  type        = string
  default     = "healthcare-alerts@company.com"
}

# Slack Webhook Variables
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

variable "slack_webhook_general" {
  description = "Slack webhook URL for general alerts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_webhook_database" {
  description = "Slack webhook URL for database alerts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_webhook_frontend" {
  description = "Slack webhook URL for frontend alerts"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_webhook_backend" {
  description = "Slack webhook URL for backend alerts"
  type        = string
  default     = ""
  sensitive   = true
}

# Slack Channel Variables
variable "slack_channel_critical" {
  description = "Slack channel for critical alerts"
  type        = string
  default     = "#healthcare-critical"
}

variable "slack_channel_warning" {
  description = "Slack channel for warning alerts"
  type        = string
  default     = "#healthcare-alerts"
}

variable "slack_channel_general" {
  description = "Slack channel for general alerts"
  type        = string
  default     = "#healthcare-notifications"
}

variable "slack_channel_database" {
  description = "Slack channel for database alerts"
  type        = string
  default     = "#database-alerts"
}

variable "slack_channel_frontend" {
  description = "Slack channel for frontend alerts"
  type        = string
  default     = "#frontend-alerts"
}

variable "slack_channel_backend" {
  description = "Slack channel for backend alerts"
  type        = string
  default     = "#backend-alerts"
}

# Email Alert Recipients
variable "critical_alert_email" {
  description = "Email address for critical alerts"
  type        = string
  default     = "healthcare-critical@company.com"
}

variable "warning_alert_email" {
  description = "Email address for warning alerts"
  type        = string
  default     = "healthcare-alerts@company.com"
}

variable "general_alert_email" {
  description = "Email address for general alerts"
  type        = string
  default     = "healthcare-team@company.com"
}

variable "database_alert_email" {
  description = "Email address for database alerts"
  type        = string
  default     = "database-team@company.com"
}

variable "frontend_alert_email" {
  description = "Email address for frontend alerts"
  type        = string
  default     = "frontend-team@company.com"
}

variable "backend_alert_email" {
  description = "Email address for backend alerts"
  type        = string
  default     = "backend-team@company.com"
}

# Local values for computed configurations
locals {
  common_labels = {
    app         = "healthcare-app"
    environment = var.environment
    managed-by  = "terraform"
  }

  frontend_labels   = merge(local.common_labels, { component = "frontend" })
  backend_labels    = merge(local.common_labels, { component = "backend" })
  mongodb_labels    = merge(local.common_labels, { component = "mongodb" })
  monitoring_labels = merge(local.common_labels, { component = "monitoring" })

  # Use provided password or generate random one
  mongodb_password = var.mongodb_root_password != "" ? var.mongodb_root_password : random_password.mongodb_password[0].result

  # Encryption configuration (simplified without AWS KMS)
  encryption_enabled = var.enable_encryption
  kms_key_arn        = var.enable_encryption ? "local-encryption-key" : ""
}

# Random password for MongoDB (only if not provided via variable)
resource "random_password" "mongodb_password" {
  count = var.mongodb_root_password == "" ? 1 : 0

  length  = 32
  special = false # Changed to false to avoid special characters like % that can cause issues
  upper   = true
  lower   = true
  numeric = true
}

# KMS Key for data encryption at rest (removed - using local encryption instead)
# resource "aws_kms_key" "healthcare_encryption" {
#   count = var.enable_encryption && var.kms_key_id == "" ? 1 : 0
#   
#   description             = "KMS key for healthcare application data encryption"
#   deletion_window_in_days = 30
#   enable_key_rotation     = true
#   
#   tags = {
#     Name        = "healthcare-encryption-key"
#     Environment = var.environment
#     Purpose     = "data-encryption"
#   }
# }

# resource "aws_kms_alias" "healthcare_encryption" {
#   count = var.enable_encryption && var.kms_key_id == "" ? 1 : 0
#   
#   name          = "alias/healthcare-encryption-${var.environment}"
#   target_key_id = aws_kms_key.healthcare_encryption[0].key_id
# }

# Kubernetes Namespace for application
resource "kubernetes_namespace" "healthcare" {
  metadata {
    name   = "${var.namespace}-${var.environment}"
    labels = local.common_labels
  }

  lifecycle {
    ignore_changes = [metadata[0].labels]
  }
}

# ConfigMap for application configuration
resource "kubernetes_config_map" "app_config" {
  metadata {
    name      = "healthcare-app-config"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    NODE_ENV                = var.environment
    MONGODB_DATABASE        = "healthcare-app"
    PROMETHEUS_METRICS_PORT = "9090"
    LOG_LEVEL               = var.environment == "production" ? "info" : "debug"
    CORS_ORIGIN             = var.environment == "production" ? "https://healthcare.company.com" : "*"
    API_RATE_LIMIT          = "100"
    API_TIMEOUT             = "30000"
    HEALTH_CHECK_INTERVAL   = "30"
    MAX_CONNECTIONS         = "10"
  }
}

# Secret for sensitive configuration
resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "healthcare-app-secrets"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
    # Removed AWS KMS encryption annotation
  }

  type = "Opaque"

  data = {
    mongodb-root-password = local.mongodb_password
    jwt-secret            = "super-secret-jwt-key-${var.environment}"
    encryption-key        = var.enable_encryption ? random_password.encryption_key[0].result : ""
  }
}

# Random encryption key for additional data protection
resource "random_password" "encryption_key" {
  count = var.enable_encryption ? 1 : 0

  length  = 32
  special = false # Changed to false to avoid special characters
  upper   = true
  lower   = true
  numeric = true
}

# MongoDB StatefulSet with advanced configuration
resource "kubernetes_stateful_set" "mongodb" {
  metadata {
    name      = var.environment == "production" ? "mongodb" : "mongodb-staging"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.mongodb_labels
  }

  spec {
    service_name = var.environment == "production" ? "mongodb" : "mongodb-staging"
    replicas     = 1

    selector {
      match_labels = merge(local.mongodb_labels, local.backend_labels)
    }

    template {
      metadata {
        labels = merge(local.mongodb_labels, local.backend_labels) # Include both mongodb and backend labels
      }

      spec {
        container {
          name              = "mongodb"
          image             = "mongo:7.0.1"
          image_pull_policy = "IfNotPresent"

          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "mongodb-root-password"
              }
            }
          }

          env {
            name  = "MONGO_INITDB_ROOT_USERNAME"
            value = "admin"
          }

          port {
            container_port = 27017
            name           = "mongodb"
          }

          volume_mount {
            name       = "mongodb-data"
            mount_path = "/data/db"
          }

          volume_mount {
            name       = "mongodb-logs"
            mount_path = "/var/log/mongodb"
          }

          resources {
            requests = {
              cpu    = "10m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
          }

          # Security context for MongoDB
          security_context {
            run_as_user                = 999
            run_as_group               = 999
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
          }

          startup_probe {
            tcp_socket {
              port = "mongodb"
            }
            initial_delay_seconds = 30
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 12
          }

          liveness_probe {
            tcp_socket {
              port = "mongodb"
            }
            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            tcp_socket {
              port = "mongodb"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        container {
          name              = "backend"
          image             = var.backend_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 5001
            name           = "http"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env {
            name  = "MONGODB_HOST"
            value = "localhost"
          }

          env {
            name  = "MONGODB_PORT"
            value = "27017"
          }

          env {
            name  = "MONGODB_USERNAME"
            value = "admin"
          }

          env {
            name = "MONGODB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "mongodb-root-password"
              }
            }
          }

          env {
            name  = "MONGODB_DATABASE"
            value = "healthcare-app"
          }

          # Datadog APM environment variables (Core APM available for free tier)
          env {
            name  = "DD_TRACE_ENABLED"
            value = var.enable_datadog ? "true" : "false"
          }

          env {
            name  = "DD_ENV"
            value = var.environment
          }

          env {
            name  = "DD_SERVICE"
            value = "healthcare-backend"
          }

          # Note: Datadog RUM is not available for student accounts
          # Using basic APM monitoring instead

          resources {
            requests = {
              cpu    = var.resource_limits.backend.cpu_request
              memory = var.resource_limits.backend.memory_request
            }
            limits = {
              cpu    = var.resource_limits.backend.cpu_limit
              memory = var.resource_limits.backend.memory_limit
            }
          }

          # Security context
          security_context {
            run_as_non_root            = true
            run_as_user                = 1000
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }

          startup_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 45
            period_seconds        = 15
            timeout_seconds       = 10
            failure_threshold     = 6
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 20 # Reduced from 30
            period_seconds        = 10
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 15 # Reduced from 30
            period_seconds        = 5  # Reduced from 10
            timeout_seconds       = 3  # Reduced from 5
            failure_threshold     = 3  # Reduced from 6
          }

          # Volume mount for temporary files (read-only root filesystem)
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }

        # Pod-level volumes
        volume {
          name = "tmp"
          empty_dir {}
        }
      }
    }

    volume_claim_template {
      metadata {
        name   = "mongodb-data"
        labels = local.mongodb_labels
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = var.environment == "production" ? "100Gi" : "10Gi"
          }
        }
        storage_class_name = "local-path"
      }
    }

    volume_claim_template {
      metadata {
        name   = "mongodb-logs"
        labels = local.mongodb_labels
      }
      spec {
        access_modes = ["ReadWriteOnce"]
        resources {
          requests = {
            storage = "1Gi"
          }
        }
        storage_class_name = "local-path"
      }
    }
  }

  # Add reasonable timeouts to prevent deployment timeout
  timeouts {
    create = "20m"
    update = "20m"
    delete = "10m"
  }
}

#     template {
#       metadata {
#         labels = local.mongodb_labels
#       }

#       spec {
#         # Simplified spec without init containers for now

#         container {
#           name  = "mongodb"
#           image = "mongo:7.0.1"
#           image_pull_policy = "IfNotPresent"

#           # Simplified MongoDB startup
#           command = ["/bin/bash", "-c"]
#           args = ["mongod --bind_ip 127.0.0.1 --auth --dbpath /data/db --logpath /var/log/mongodb/mongod.log"]

#           env {
#             name = "MONGO_INITDB_ROOT_PASSWORD"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.app_secrets.metadata[0].name
#                 key  = "mongodb-root-password"
#               }
#             }
#           }

#           env {
#             name  = "MONGO_INITDB_ROOT_USERNAME"
#             value = "admin"
#           }

#           port {
#             container_port = 27017
#             name           = "mongodb"
#           }

#           volume_mount {
#             name       = "mongodb-data"
#             mount_path = "/data/db"
#           }

#           volume_mount {
#             name       = "mongodb-logs"
#             mount_path = "/var/log/mongodb"
#           }

#           resources {
#             requests = {
#               cpu    = "200m"
#               memory = "512Mi"
#             }
#             limits = {
#               cpu    = "1000m"
#               memory = "2Gi"
#             }
#           }

#           # Security context for MongoDB
#           security_context {
#             run_as_user                = 999
#             run_as_group               = 999
#             allow_privilege_escalation = false
#             read_only_root_filesystem  = false
#           }

#           startup_probe {
#             exec {
#               command = ["mongosh", "--username", "admin", "--password", "$MONGO_INITDB_ROOT_PASSWORD", "--authenticationDatabase", "admin", "--eval", "db.adminCommand('ping')"]
#             }
#             initial_delay_seconds = 20
#             period_seconds        = 10
#             timeout_seconds       = 5
#             failure_threshold     = 30
#           }

#           liveness_probe {
#             exec {
#               command = ["mongosh", "--username", "admin", "--password", "$MONGO_INITDB_ROOT_PASSWORD", "--authenticationDatabase", "admin", "--eval", "db.adminCommand('ping')"]
#             }
#             initial_delay_seconds = 120
#             period_seconds        = 30
#             timeout_seconds       = 10
#             failure_threshold     = 3
#           }

#           readiness_probe {
#             exec {
#             command = ["mongosh", "--username", "admin", "--password", "$MONGO_INITDB_ROOT_PASSWORD", "--authenticationDatabase", "admin", "--eval", "db.adminCommand('ping')"]
#             }
#             initial_delay_seconds = 60
#             period_seconds        = 15
#             timeout_seconds       = 5
#             failure_threshold     = 3
#           }
#         }

#         container {
#           name  = "backend"
#           image = var.backend_image
#           image_pull_policy = "IfNotPresent"

#           port {
#             container_port = 5000
#             name           = "http"
#           }

#           env_from {
#             config_map_ref {
#               name = kubernetes_config_map.app_config.metadata[0].name
#             }
#           }

#           env {
#             name  = "MONGODB_HOST"
#             value = "127.0.0.1"
#           }

#           env {
#             name  = "MONGODB_PORT"
#             value = "27017"
#           }

#           env {
#             name  = "MONGODB_USERNAME"
#             value = "admin"
#           }

#           env {
#             name = "MONGODB_PASSWORD"
#             value_from {
#               secret_key_ref {
#                 name = kubernetes_secret.app_secrets.metadata[0].name
#                 key  = "mongodb-root-password"
#               }
#             }
#           }

#           env {
#             name  = "MONGODB_DATABASE"
#             value = "healthcare-app"
#           }

#           # Datadog APM environment variables
#           env {
#             name  = "DD_TRACE_ENABLED"
#             value = var.enable_datadog ? "true" : "false"
#           }

#           env {
#             name  = "DD_ENV"
#             value = var.environment
#           }

#           env {
#             name  = "DD_SERVICE"
#             value = "healthcare-backend"
#           }

#           resources {
#             requests = {
#               cpu    = var.resource_limits.backend.cpu_request
#               memory = var.resource_limits.backend.memory_request
#             }
#             limits = {
#               cpu    = var.resource_limits.backend.cpu_limit
#               memory = var.resource_limits.backend.memory_limit
#             }
#           }

#           # Security context
#           security_context {
#             run_as_non_root            = true
#             run_as_user                = 1000
#             allow_privilege_escalation = false
#             read_only_root_filesystem  = true
#           }

#           # Startup probe to wait for MongoDB
#           startup_probe {
#             http_get {
#               path = "/health"
#               port = "http"
#             }
#             initial_delay_seconds = 30
#             period_seconds        = 10
#             timeout_seconds       = 5
#             failure_threshold     = 12  # Allow up to 2 minutes for startup
#           }

#           liveness_probe {
#             http_get {
#               path = "/health"
#               port = "http"
#             }
#             initial_delay_seconds = 60
#             period_seconds        = 15
#             timeout_seconds       = 5
#             failure_threshold     = 3
#           }

#           readiness_probe {
#             http_get {
#               path = "/health"
#               port = "http"
#             }
#             initial_delay_seconds = 30
#             period_seconds        = 10
#             timeout_seconds       = 5
#             failure_threshold     = 6
#           }

#           # Volume mount for temporary files (read-only root filesystem)
#           volume_mount {
#             name       = "tmp"
#             mount_path = "/tmp"
#           }
#         }

#         # Pod-level volumes
#         volume {
#           name = "tmp"
#           empty_dir {}
#         }

#     }

#     volume_claim_template {
#       metadata {
#         name = "mongodb-data"
#         labels = local.mongodb_labels
#       }
#       spec {
#         access_modes = ["ReadWriteOnce"]
#         resources {
#           requests = {
#             storage = var.environment == "production" ? "100Gi" : "10Gi"
#           }
#         }
#         storage_class_name = "local-path"
#       }
#     }

#     volume_claim_template {
#       metadata {
#         name = "mongodb-logs"
#         labels = local.mongodb_labels
#       }
#       spec {
#         access_modes = ["ReadWriteOnce"]
#         resources {
#           requests = {
#             storage = "1Gi"
#           }
#         }
#         storage_class_name = "local-path"
#       }
#     }
#   }

#   # Add reasonable timeouts to prevent deployment timeout
#   timeouts {
#     create = "10m"
#     update = "10m"
#     delete = "5m"
#   }
# }
# REMOVED: Backend now runs as sidecar in MongoDB pod

# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
  wait_for_rollout = false

  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.frontend_labels
  }

  spec {
    replicas = var.replica_count.frontend

    selector {
      match_labels = local.frontend_labels
    }

    template {
      metadata {
        labels = local.frontend_labels
      }

      spec {
        container {
          name              = "frontend"
          image             = var.frontend_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 3001
            name           = "http"
          }

          # Note: Datadog RUM is not available for student accounts
          # Frontend monitoring will use basic logging instead

          resources {
            requests = {
              cpu    = var.resource_limits.frontend.cpu_request
              memory = var.resource_limits.frontend.memory_request
            }
            limits = {
              cpu    = var.resource_limits.frontend.cpu_limit
              memory = var.resource_limits.frontend.memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
          }

          security_context {
            run_as_non_root            = true
            run_as_user                = 101
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }

          # Writable mounts for nginx with read-only root filesystem
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          volume_mount {
            name       = "nginx-cache"
            mount_path = "/var/cache/nginx"
          }

          volume_mount {
            name       = "nginx-run"
            mount_path = "/var/run"
          }

          volume_mount {
            name       = "nginx-log"
            mount_path = "/var/log/nginx"
          }
        }

        # Pod-level volumes
        volume {
          name = "tmp"
          empty_dir {}
        }

        volume {
          name = "nginx-cache"
          empty_dir {}
        }

        volume {
          name = "nginx-run"
          empty_dir {}
        }

        volume {
          name = "nginx-log"
          empty_dir {}
        }
      }
    }
  }
}

# Services
resource "kubernetes_service" "mongodb" {
  metadata {
    name      = var.environment == "production" ? "mongodb" : "mongodb-staging"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.mongodb_labels
  }

  spec {
    selector = local.mongodb_labels

    port {
      port        = 27017
      target_port = "mongodb"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Enhanced Datadog Agent via Helm (when enabled)
resource "helm_release" "datadog" {
  count      = var.enable_datadog ? 1 : 0
  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  namespace  = kubernetes_namespace.healthcare.metadata[0].name

  values = [
    yamlencode({
      datadog = {
        apiKey   = var.datadog_api_key
        appKey   = var.datadog_app_key != "" ? var.datadog_app_key : null
        hostname = "healthcare-cluster-${var.environment}"
        site     = "datadoghq.com"
        env      = var.environment
        service  = "healthcare-app"
        version  = var.app_version

        # Enhanced APM configuration
        apm = {
          enabled = true
          port    = 8126
          env     = var.environment
          service = "healthcare-backend"
          additionalEndpoints = [
            {
              host = "datadog-agent.datadog.svc.cluster.local"
              port = 8126
            }
          ]
        }

        # Enhanced logging configuration
        logs = {
          enabled                    = true
          containerCollectAll        = true
          containerCollectUsingFiles = true
          autoMultiLineDetection     = true
        }

        # System probe for network monitoring
        systemProbe = {
          enabled              = true
          enableTCPQueueLength = true
          enableOOMKill        = true
          collectDNSStats      = true
        }

        # Security monitoring
        securityAgent = {
          compliance = {
            enabled = true
          }
          runtime = {
            enabled = true
          }
        }

        # Process monitoring
        processAgent = {
          enabled           = true
          processCollection = true
        }

        # Enhanced metrics collection
        dogstatsd = {
          useHostPort     = true
          useSocketVolume = true
        }

        # Tags for better organization
        tags = [
          "env:${var.environment}",
          "service:healthcare-app",
          "version:${var.app_version}",
          "team:platform",
          "component:monitoring"
        ]
      }

      # Cluster Agent configuration
      clusterAgent = {
        enabled = true
        metricsProvider = {
          enabled = true
        }
        admissionController = {
          enabled = true
        }
        clusterChecks = {
          enabled = true
        }
      }

      # Node Agent configuration
      agents = {
        useHostNetwork = true
        useHostPID     = true
        useHostPort    = false

        containers = {
          agent = {
            env = [
              {
                name  = "DD_PROCESS_AGENT_ENABLED"
                value = "true"
              },
              {
                name  = "DD_SYSTEM_PROBE_ENABLED"
                value = "true"
              },
              {
                name  = "DD_RUNTIME_SECURITY_CONFIG_ENABLED"
                value = "true"
              }
            ]
          }
        }

        # Volume mounts for enhanced monitoring
        volumeMounts = [
          {
            name      = "hostroot"
            mountPath = "/host/root"
            readOnly  = true
          },
          {
            name      = "proc"
            mountPath = "/host/proc"
            readOnly  = true
          },
          {
            name      = "sys"
            mountPath = "/host/sys"
            readOnly  = true
          }
        ]

        volumes = [
          {
            name = "hostroot"
            hostPath = {
              path = "/"
            }
          },
          {
            name = "proc"
            hostPath = {
              path = "/proc"
            }
          },
          {
            name = "sys"
            hostPath = {
              path = "/sys"
            }
          }
        ]
      }

      # Disable cluster checks runner to reduce complexity
      clusterChecksRunner = {
        enabled = false
      }

      # Disable kube-state-metrics as we have our own
      kubeStateMetricsCore = {
        enabled = false
      }
    })
  ]

  # Increased timeout for Helm operations to handle slow deployments
  timeout = 2400 # 40 minutes

  # Additional options for robustness
  atomic            = false
  wait              = false
  cleanup_on_fail   = true
  dependency_update = true
}

resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.backend_labels
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "5001"
    }
  }

  spec {
    selector = local.mongodb_labels # Backend runs as sidecar in MongoDB pod

    port {
      port        = 5001
      target_port = "http"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.frontend_labels
  }

  spec {
    selector = local.frontend_labels

    port {
      port        = 3001
      target_port = "http"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Horizontal Pod Autoscalers
resource "kubernetes_horizontal_pod_autoscaler_v2" "mongodb_hpa" {
  metadata {
    name      = "mongodb-hpa"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "StatefulSet"
      name        = kubernetes_stateful_set.mongodb.metadata[0].name
    }

    min_replicas = 1
    max_replicas = 3

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}

# Network Policies for security
resource "kubernetes_network_policy" "default_deny" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

# Allow internal communication within namespace
resource "kubernetes_network_policy" "allow_internal" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "allow-internal-communication"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]

    ingress {
      from {
        pod_selector {}
      }
    }

    egress {
      to {
        pod_selector {}
      }
    }

    # Allow DNS
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }
}

# Security group for database access
resource "kubernetes_network_policy" "mongodb_security" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "mongodb-security-policy"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = local.mongodb_labels
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = local.backend_labels
        }
      }
      ports {
        port     = "27017"
        protocol = "TCP"
      }
    }

    # Allow health checks from Kubernetes
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
      ports {
        port     = "27017"
        protocol = "TCP"
      }
    }
  }
}

# Web application firewall simulation via network policy
resource "kubernetes_network_policy" "waf_frontend" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "frontend-waf-policy"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = local.frontend_labels
    }
    policy_types = ["Ingress"]

    ingress {
      ports {
        port     = "3001"
        protocol = "TCP"
      }
      from {
        ip_block {
          cidr = "0.0.0.0/0"
          except = [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16"
          ]
        }
      }
    }
  }
}

# Backend API security
resource "kubernetes_network_policy" "backend_security" {
  count = var.enable_network_policies ? 1 : 0

  metadata {
    name      = "backend-security-policy"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = local.mongodb_labels # Backend runs as sidecar in MongoDB pod
    }
    policy_types = ["Ingress"]

    ingress {
      from {
        pod_selector {
          match_labels = local.frontend_labels
        }
      }
      ports {
        port     = "5001"
        protocol = "TCP"
      }
    }

    # Allow health checks from Kubernetes
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
      ports {
        port     = "5001"
        protocol = "TCP"
      }
    }

    # Allow traffic from ingress-nginx namespace
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "ingress-nginx"
          }
        }
      }
      ports {
        port     = "5001"
        protocol = "TCP"
      }
    }
  }
}

# resource "kubernetes_network_policy" "allow_backend_to_mongodb" {
#   metadata {
#     name      = "allow-backend-to-mongodb"
#     namespace = kubernetes_namespace.healthcare.metadata[0].name
#   }

#   spec {
#     pod_selector {
#       match_labels = local.mongodb_labels  # Backend now runs in MongoDB pod
#     }

#     policy_types = ["Egress"]

#     # Allow DNS resolution
#     egress {
#       to {
#         namespace_selector {
#           match_labels = {
#             "kubernetes.io/metadata.name" = "kube-system"
#           }
#         }
#       }
#       ports {
#         port     = "53"
#         protocol = "UDP"
#       }
#       ports {
#         port     = "53"
#         protocol = "TCP"
#       }
#     }

#     # Allow all egress within the same namespace (simplified for reliability)
#     egress {
#       to {
#         namespace_selector {
#           match_labels = {
#             "kubernetes.io/metadata.name" = kubernetes_namespace.healthcare.metadata[0].labels.name
#           }
#         }
#       }
#     }

#     # Allow external access for image pulls and other necessary traffic
#     egress {
#       to {}
#       ports {
#         port     = "80"
#         protocol = "TCP"
#       }
#         port     = "443"
#         protocol = "TCP"
#       }
#     }
#   }
# }

# Allow external access to frontend
resource "kubernetes_network_policy" "allow_frontend_ingress" {
  metadata {
    name      = "allow-frontend-ingress"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = local.frontend_labels
    }

    policy_types = ["Ingress"]

    ingress {
      ports {
        port     = "3001"
        protocol = "TCP"
      }
      from {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
    }
  }
}

# Allow external access to backend
# resource "kubernetes_network_policy" "allow_backend_ingress" {
#   metadata {
#     name      = "allow-backend-ingress"
#     namespace = kubernetes_namespace.healthcare.metadata[0].name
#   }

#   spec {
#     pod_selector {
#       match_labels = local.mongodb_labels  # Backend runs in MongoDB pod
#     }

#     policy_types = ["Ingress"]

#     ingress {
#       ports {
#         port     = "5000"
#         protocol = "TCP"
#       }
#       from {
#         ip_block {
#           cidr = "0.0.0.0/0"
#         }
#       }
#     }
#   }
# }

# Allow frontend to backend communication
resource "kubernetes_network_policy" "allow_frontend_to_backend" {
  metadata {
    name      = "allow-frontend-to-backend"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = local.frontend_labels
    }

    policy_types = ["Egress"]

    # Allow DNS resolution
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "kube-system"
          }
        }
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }

    # Allow all egress within the same namespace (simplified for reliability)
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = kubernetes_namespace.healthcare.metadata[0].name
          }
        }
      }
    }

    # Allow egress to monitoring namespace for service access
    egress {
      to {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = "monitoring-production-green"
          }
        }
      }
      ports {
        port     = "3000"
        protocol = "TCP"
      }
      ports {
        port     = "9090"
        protocol = "TCP"
      }
      ports {
        port     = "9093"
        protocol = "TCP"
      }
      ports {
        port     = "16686"
        protocol = "TCP"
      }
    }

    # Allow external access for image pulls and other necessary traffic
    egress {
      to {
        ip_block {
          cidr = "0.0.0.0/0"
        }
      }
      ports {
        port     = "80"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}

# Prometheus Alerting Rules via Terraform
resource "kubernetes_config_map" "prometheus_alerting_rules" {
  metadata {
    name      = "prometheus-alerting-rules"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = merge(local.monitoring_labels, { component = "prometheus" })
  }

  data = {
    "alerting_rules.yml" = <<-EOT
groups:
- name: healthcare.alerts
  rules:

  # Critical Alerts
  - alert: DatabaseDown
    expr: up{job="mongodb"} == 0
    for: 1m
    labels:
      severity: critical
      service: database
    annotations:
      summary: "Database is down"
      description: "MongoDB has been down for more than 1 minute."

  - alert: BackendServiceDown
    expr: up{job="backend"} == 0
    for: 1m
    labels:
      severity: critical
      service: backend
    annotations:
      summary: "Backend service is down"
      description: "Backend service has been down for more than 1 minute."

  - alert: FrontendServiceDown
    expr: up{job="frontend"} == 0
    for: 1m
    labels:
      severity: critical
      service: frontend
    annotations:
      summary: "Frontend service is down"
      description: "Frontend service has been down for more than 1 minute."

  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.1
    for: 2m
    labels:
      severity: critical
      service: backend
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ \$value | printf \"%.2f\" }}% over the last 5 minutes."

  # Warning Alerts
  - alert: HighCPUUsage
    expr: rate(container_cpu_usage_seconds_total{pod=~".*"}[5m]) > 0.8
    for: 5m
    labels:
      severity: warning
      service: infrastructure
    annotations:
      summary: "High CPU usage detected"
      description: "CPU usage is above 80% for pod {{ \$labels.pod }}."

  - alert: HighMemoryUsage
    expr: container_memory_usage_bytes{pod=~".*"} / container_spec_memory_limit_bytes > 0.9
    for: 5m
    labels:
      severity: warning
      service: infrastructure
    annotations:
      summary: "High memory usage detected"
      description: "Memory usage is above 90% for pod {{ \$labels.pod }}."

  - alert: SlowResponseTime
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
    for: 3m
    labels:
      severity: warning
      service: backend
    annotations:
      summary: "Slow response time detected"
      description: "95th percentile response time is above 2 seconds."

  - alert: DatabaseConnectionPoolExhausted
    expr: mongodb_connections{state="active"} / mongodb_connections{state="available"} > 0.9
    for: 2m
    labels:
      severity: warning
      service: database
    annotations:
      summary: "Database connection pool nearly exhausted"
      description: "Active database connections are above 90% of available connections."

  # Info Alerts
  - alert: DeploymentCompleted
    expr: kube_deployment_status_replicas_available{deployment=~".*"} == kube_deployment_status_replicas_desired{deployment=~".*"}
    for: 1m
    labels:
      severity: info
      service: infrastructure
    annotations:
      summary: "Deployment completed successfully"
      description: "Deployment {{ \$labels.deployment }} has completed successfully."

  - alert: PodRestarted
    expr: increase(kube_pod_container_status_restarts_total[10m]) > 0
    for: 0m
    labels:
      severity: info
      service: infrastructure
    annotations:
      summary: "Pod restarted"
      description: "Pod {{ \$labels.pod }} in namespace {{ \$labels.namespace }} has restarted."

  # Database-specific alerts
  - alert: DatabaseSlowQueries
    expr: rate(mongodb_op_counters_total{type="query"}[5m]) > 1000
    for: 5m
    labels:
      severity: warning
      service: database
    annotations:
      summary: "High number of database queries"
      description: "Database is experiencing high query load: {{ \$value }} queries per second."

  - alert: DatabaseDiskSpaceLow
    expr: (1 - (mongodb_db_stats_storageSize / mongodb_db_stats_totalSize)) < 0.1
    for: 5m
    labels:
      severity: critical
      service: database
    annotations:
      summary: "Database disk space low"
      description: "Database disk usage is above 90%."

  # Application-specific alerts
  - alert: HealthCheckFailed
    expr: probe_success == 0
    for: 1m
    labels:
      severity: critical
      service: healthcheck
    annotations:
      summary: "Health check failed"
      description: "Health check for {{ \$labels.instance }} has failed."

  - alert: CertificateExpiryWarning
    expr: probe_ssl_earliest_cert_expiry - time() < 604800
    for: 0m
    labels:
      severity: warning
      service: security
    annotations:
      summary: "SSL certificate expiring soon"
      description: "SSL certificate for {{ \$labels.instance }} expires in less than 7 days."

  # Performance alerts
  - alert: HighRequestRate
    expr: rate(http_requests_total[5m]) > 1000
    for: 2m
    labels:
      severity: info
      service: performance
    annotations:
      summary: "High request rate detected"
      description: "Request rate is above 1000 requests per second."

  - alert: QueueBacklogHigh
    expr: http_requests_in_flight > 50
    for: 2m
    labels:
      severity: warning
      service: performance
    annotations:
      summary: "High request queue backlog"
      description: "Number of requests in flight is above 50."
EOT
  }
}

# Grafana Dashboard Configuration via Terraform
resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = merge(local.monitoring_labels, { component = "grafana" })
  }

  data = {
    "performance-dashboard.json" = <<-EOT
{
  "dashboard": {
    "id": null,
    "title": "Healthcare Application Performance Dashboard",
    "tags": ["healthcare", "performance", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Application Response Time",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "95th percentile"
          },
          {
            "expr": "histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))",
            "legendFormat": "50th percentile"
          }
        ],
        "yAxes": [
          {
            "unit": "seconds",
            "min": 0
          }
        ]
      },
      {
        "id": 2,
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])",
            "legendFormat": "Requests per second"
          }
        ]
      },
      {
        "id": 3,
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\\"5..\\"}[5m]) / rate(http_requests_total[5m]) * 100",
            "legendFormat": "Error rate %"
          }
        ],
        "yAxes": [
          {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        ]
      },
      {
        "id": 4,
        "title": "CPU Usage by Pod",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{pod=~\\".*\\"}[5m]) * 100",
            "legendFormat": "{{pod}} CPU %"
          }
        ],
        "yAxes": [
          {
            "unit": "percent",
            "min": 0
          }
        ]
      },
      {
        "id": 5,
        "title": "Memory Usage by Pod",
        "type": "graph",
        "targets": [
          {
            "expr": "container_memory_usage_bytes{pod=~\\".*\\"} / container_spec_memory_limit_bytes * 100",
            "legendFormat": "{{pod}} Memory %"
          }
        ],
        "yAxes": [
          {
            "unit": "percent",
            "min": 0,
            "max": 100
          }
        ]
      },
      {
        "id": 6,
        "title": "Database Connections",
        "type": "graph",
        "targets": [
          {
            "expr": "mongodb_connections{state=\\"active\\"}",
            "legendFormat": "Active connections"
          },
          {
            "expr": "mongodb_connections{state=\\"available\\"}",
            "legendFormat": "Available connections"
          }
        ]
      },
      {
        "id": 7,
        "title": "Database Query Performance",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(mongodb_op_counters_total{type=\\"query\\"}[5m])",
            "legendFormat": "Queries per second"
          }
        ]
      },
      {
        "id": 8,
        "title": "Pod Restarts",
        "type": "graph",
        "targets": [
          {
            "expr": "increase(kube_pod_container_status_restarts_total[5m])",
            "legendFormat": "{{pod}} restarts"
          }
        ]
      },
      {
        "id": 9,
        "title": "Network I/O",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_network_receive_bytes_total[5m])",
            "legendFormat": "{{pod}} receive"
          },
          {
            "expr": "rate(container_network_transmit_bytes_total[5m])",
            "legendFormat": "{{pod}} transmit"
          }
        ],
        "yAxes": [
          {
            "unit": "bytes",
            "min": 0
          }
        ]
      },
      {
        "id": 10,
        "title": "Disk I/O",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(container_fs_reads_bytes_total[5m])",
            "legendFormat": "{{pod}} reads"
          },
          {
            "expr": "rate(container_fs_writes_bytes_total[5m])",
            "legendFormat": "{{pod}} writes"
          }
        ],
        "yAxes": [
          {
            "unit": "bytes",
            "min": 0
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOT
  }
}
# MongoDB Backup CronJob
resource "kubernetes_cron_job_v1" "mongodb_backup" {
  metadata {
    name      = "mongodb-backup"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.mongodb_labels
  }

  spec {
    schedule = "0 2 * * *" # Daily at 2 AM
    job_template {
      metadata {
        labels = local.mongodb_labels
      }
      spec {
        template {
          metadata {
            labels = local.mongodb_labels
          }
          spec {
            container {
              name    = "mongodb-backup"
              image   = "mongo:7.0.1"
              command = ["sh", "-c"]
              args = [
                <<-EOT
                # Create backup directory with timestamp
                BACKUP_DIR="/backup/backup_$(date +%Y%m%d_%H%M%S)"
                mkdir -p $BACKUP_DIR
                
                # Perform MongoDB backup
                mongodump \
                  --host mongodb \
                  --username admin \
                  --password $MONGO_PASSWORD \
                  --authenticationDatabase admin \
                  --db healthcare-app \
                  --out $BACKUP_DIR \
                  --gzip
                
                # Create backup metadata
                cat > $BACKUP_DIR/backup-info.json << EOF
                {
                  "timestamp": "$(date -Iseconds)",
                  "database": "healthcare-app",
                  "size": "$(du -sh $BACKUP_DIR | cut -f1)",
                  "files": $(find $BACKUP_DIR -name "*.bson.gz" | wc -l),
                  "environment": "${var.environment}",
                  "version": "${var.app_version}"
                }
                EOF
                
                # Verify backup integrity
                if [ -f "$BACKUP_DIR/healthcare-app/users.bson.gz" ]; then
                  echo "Backup completed successfully"
                  echo "Backup location: $BACKUP_DIR"
                  echo "Backup size: $(du -sh $BACKUP_DIR | cut -f1)"
                else
                  echo "Backup failed - missing expected files"
                  exit 1
                fi
                
                # List backup contents
                echo "Backup contents:"
                find $BACKUP_DIR -type f -name "*.bson.gz" | head -10
                EOT
              ]

              env {
                name  = "MONGO_USERNAME"
                value = "admin"
              }

              env {
                name = "MONGO_PASSWORD"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret.app_secrets.metadata[0].name
                    key  = "mongodb-root-password"
                  }
                }
              }

              volume_mount {
                name       = "backup-storage"
                mount_path = "/backup"
              }

              resources {
                requests = {
                  cpu    = "100m"
                  memory = "256Mi"
                }
                limits = {
                  cpu    = "500m"
                  memory = "1Gi"
                }
              }
            }

            volume {
              name = "backup-storage"
              empty_dir {}
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}


# Backup cleanup CronJob (retain last 7 days)
resource "kubernetes_cron_job_v1" "backup_cleanup" {
  metadata {
    name      = "mongodb-backup-cleanup"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.mongodb_labels
  }

  spec {
    schedule = "0 3 * * *" # Daily at 3 AM (1 hour after backup)
    job_template {
      metadata {
        labels = local.mongodb_labels
      }
      spec {
        template {
          metadata {
            labels = local.mongodb_labels
          }
          spec {
            container {
              name    = "backup-cleanup"
              image   = "busybox:latest"
              command = ["sh", "-c"]
              args = [
                <<-EOT
                echo "Starting backup cleanup..."
                
                # List all backups
                echo "Current backups:"
                ls -la /backup/ | grep backup_ | head -20
                
                # Keep only last 7 days of backups
                find /backup/ -name "backup_*" -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
                
                # Keep only last 10 backups regardless of age
                cd /backup/
                ls -dt backup_*/ | tail -n +11 | xargs rm -rf 2>/dev/null || true
                
                echo "Cleanup completed. Remaining backups:"
                ls -la /backup/ | grep backup_ | wc -l
                du -sh /backup/*
                EOT
              ]

              volume_mount {
                name       = "backup-storage"
                mount_path = "/backup"
              }

              resources {
                requests = {
                  cpu    = "50m"
                  memory = "64Mi"
                }
                limits = {
                  cpu    = "100m"
                  memory = "128Mi"
                }
              }
            }

            volume {
              name = "backup-storage"
              empty_dir {}
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}

# Database restore Job template (can be triggered manually)
resource "kubernetes_job" "mongodb_restore_template" {
  metadata {
    name      = "mongodb-restore-template"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.mongodb_labels
  }

  spec {
    template {
      metadata {
        labels = local.mongodb_labels
      }
      spec {
        container {
          name    = "mongodb-restore"
          image   = "mongo:7.0.1"
          command = ["sh", "-c"]
          args = [
            <<-EOT
            echo "MongoDB Restore Job Template"
            echo "To restore from a backup, run:"
            echo "kubectl create job restore-job --from=cronjob/mongodb-backup -n ${kubernetes_namespace.healthcare.metadata[0].name}"
            echo ""
            echo "Then modify the job to use mongorestore instead of mongodump"
            echo "To restore from a backup, modify the job spec to use mongorestore instead of mongodump"
            echo "Use the appropriate backup directory path from the backup logs"
            EOT
          ]

          env {
            name = "MONGO_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.app_secrets.metadata[0].name
                key  = "mongodb-root-password"
              }
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }

        restart_policy = "Never"
      }
    }
  }

  # Set to 0 replicas so this is just a template
  lifecycle {
    ignore_changes = [spec[0].template[0].spec[0].restart_policy]
  }
}

# Datadog Cluster Agent RBAC (when Datadog is enabled)
resource "kubernetes_cluster_role" "datadog_cluster_agent" {
  count = var.enable_datadog ? 1 : 0

  metadata {
    name = "datadog-cluster-agent"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "namespaces", "pods", "services", "endpoints", "persistentvolumes", "persistentvolumeclaims", "configmaps", "secrets", "serviceaccounts", "events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies", "ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterroles", "clusterrolebindings", "roles", "rolebindings"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "datadog_cluster_agent" {
  count = var.enable_datadog ? 1 : 0

  metadata {
    name = "datadog-cluster-agent"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.datadog_cluster_agent[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "datadog-cluster-agent"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }
}

# Data Transfer Controls for GDPR Compliance
resource "kubernetes_config_map" "data_transfer_policy" {
  count = var.enable_data_transfer_controls ? 1 : 0

  metadata {
    name      = "data-transfer-policy"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "transfer-policy.json" = jsonencode({
      version      = "1.0"
      organization = "Healthcare App Corporation"
      data_transfer_rules = [
        {
          purpose     = "EU-US Data Transfers"
          legal_basis = "Standard Contractual Clauses"
          safeguards = [
            "SCCs implemented",
            "Data minimization",
            "Encryption in transit",
            "Regular audits"
          ]
          restricted_countries = []
          approval_required    = false
        },
        {
          purpose     = "Third-party processing"
          legal_basis = "Legitimate interest"
          safeguards = [
            "DPA executed",
            "Security assessments",
            "Incident notification",
            "Audit rights"
          ]
          restricted_countries = ["CN", "RU", "IR", "KP"]
          approval_required    = true
        }
      ]
      audit_trail = {
        enabled        = true
        retention_days = 2555 # 7 years
        log_transfers  = true
      }
    })
  }
}

# Data Subject Rights Implementation
resource "kubernetes_config_map" "gdpr_rights_config" {
  metadata {
    name      = "gdpr-rights-config"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "rights-implementation.json" = jsonencode({
      data_subject_rights = {
        access = {
          enabled              = true
          max_response_days    = 30
          automated_processing = true
        }
        rectification = {
          enabled              = true
          max_response_days    = 30
          automated_processing = true
        }
        erasure = {
          enabled              = true
          max_response_days    = 30
          automated_processing = true
          exceptions           = ["legal-obligation", "public-interest", "research"]
        }
        restriction = {
          enabled              = true
          max_response_days    = 30
          automated_processing = true
        }
        portability = {
          enabled              = true
          max_response_days    = 30
          formats              = ["json", "xml", "csv"]
          automated_processing = true
        }
        objection = {
          enabled              = true
          max_response_days    = 30
          automated_processing = true
        }
      }
      consent_management = {
        enabled               = true
        granular_consent      = true
        withdrawal_enabled    = true
        consent_log_retention = 2555 # 7 years
      }
      breach_notification = {
        enabled                              = true
        supervisory_authority_deadline_hours = 72
        affected_individuals_deadline_days   = 1
        automated_detection                  = true
      }
    })
  }
}
# Nginx Proxy Manager Module
module "nginx_proxy_manager" {
  source = "./modules/nginx-proxy-manager"

  namespace                  = kubernetes_namespace.healthcare.metadata[0].name
  environment                = var.environment
  app_version                = var.app_version
  common_labels              = local.common_labels
  monitoring_labels          = local.monitoring_labels
  frontend_labels            = local.frontend_labels
  backend_labels             = local.backend_labels
  enable_nginx_proxy_manager = var.enable_nginx_proxy_manager
}
output "mongodb_password" {
  description = "MongoDB root password (sensitive - only shown for convenience)"
  value       = local.mongodb_password
  sensitive   = true
}

output "namespace" {
  description = "Kubernetes namespace"
  value       = "${var.namespace}-${var.environment}"
}

output "mongodb_service" {
  description = "MongoDB service name"
  value       = kubernetes_service.mongodb.metadata[0].name
}

output "backend_service" {
  description = "Backend service name"
  value       = kubernetes_service.backend.metadata[0].name
}

output "frontend_service" {
  description = "Frontend service name"
  value       = kubernetes_service.frontend.metadata[0].name
}
