# Healthcare DevOps Infrastructure as Code
# Supports multiple environments with integrated monitoring

terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Configure the Kubernetes Provider
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "colima"
}

# Variables for environment configuration
variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
  default     = "staging"
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
    mongodb = {
      cpu_request    = "500m"
      memory_request = "1Gi"
      cpu_limit      = "2000m"
      memory_limit   = "4Gi"
    }
  }
}

variable "enable_persistent_storage" {
  description = "Enable persistent storage for monitoring components"
  type        = bool
  default     = true
}

# Local values for computed configurations
locals {
  common_labels = {
    app         = "healthcare-app"
    environment = var.environment
    managed-by  = "terraform"
  }

  frontend_labels = merge(local.common_labels, { component = "frontend" })
  backend_labels  = merge(local.common_labels, { component = "backend" })
  mongodb_labels  = merge(local.common_labels, { component = "mongodb" })
}

# Random password for MongoDB
resource "random_password" "mongodb_password" {
  length  = 32
  special = true
}

# Kubernetes Namespace for application
resource "kubernetes_namespace" "healthcare" {
  metadata {
    name = "${var.namespace}-${var.environment}"
    labels = local.common_labels
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
  }
}

# Secret for sensitive configuration
resource "kubernetes_secret" "app_secrets" {
  metadata {
    name      = "healthcare-app-secrets"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
  }

  type = "Opaque"

  data = {
    mongodb-root-password = base64encode(random_password.mongodb_password.result)
    jwt-secret            = base64encode("super-secret-jwt-key-${var.environment}")
  }
}

# MongoDB StatefulSet with advanced configuration
resource "kubernetes_stateful_set" "mongodb" {
  metadata {
    name      = "mongodb"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.mongodb_labels
  }

  spec {
    service_name = "mongodb-headless"
    replicas     = var.environment == "production" ? 3 : 1

    selector {
      match_labels = local.mongodb_labels
    }

    template {
      metadata {
        labels = local.mongodb_labels
      }

      spec {
        container {
          name  = "mongodb"
          image = "mongo:7.0"
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

          resources {
            requests = {
              cpu    = var.resource_limits.mongodb.cpu_request
              memory = var.resource_limits.mongodb.memory_request
            }
            limits = {
              cpu    = var.resource_limits.mongodb.cpu_limit
              memory = var.resource_limits.mongodb.memory_limit
            }
          }

          liveness_probe {
            exec {
              command = ["mongo", "--eval", "db.adminCommand('ping')"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            exec {
              command = ["mongo", "--eval", "db.adminCommand('ping')"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        # Security context
        security_context {
          fs_group = 999
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "mongodb-data"
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
  }
}

# Backend Deployment with advanced features
resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.backend_labels
  }

  spec {
    replicas = var.replica_count.backend

    selector {
      match_labels = local.backend_labels
    }

    template {
      metadata {
        labels = local.backend_labels
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "5000"
          "prometheus.io/path"   = "/metrics"
        }
      }

      spec {
        container {
          name  = "backend"
          image = var.backend_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 5000
            name           = "http"
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.app_config.metadata[0].name
            }
          }

          env {
            name  = "MONGODB_URI"
            value = "mongodb://admin:$(MONGODB_PASSWORD)@mongodb:27017/healthcare-app?authSource=admin"
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

          liveness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          # Security context
          security_context {
            run_as_non_root            = true
            run_as_user                = 1000
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }

        # Pod security context
        security_context {
          fs_group = 1000
        }

        # Pod anti-affinity for high availability
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "component"
                    operator = "In"
                    values   = ["backend"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "25%"
        max_surge       = "25%"
      }
    }
  }
}

# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
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
          name  = "frontend"
          image = var.frontend_image
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 3001
            name           = "http"
          }

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
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "http"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }

          security_context {
            run_as_non_root            = true
            run_as_user                = 101
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
        }
      }
    }
  }
}

# Services
resource "kubernetes_service" "mongodb" {
  metadata {
    name      = "mongodb"
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

    cluster_ip = "None"
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.backend_labels
    annotations = {
      "prometheus.io/scrape" = "true"
      "prometheus.io/port"   = "5000"
    }
  }

  spec {
    selector = local.backend_labels

    port {
      port        = 5000
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
resource "kubernetes_horizontal_pod_autoscaler_v2" "backend_hpa" {
  metadata {
    name      = "backend-hpa"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.backend.metadata[0].name
    }

    min_replicas = var.replica_count.backend
    max_replicas = var.replica_count.backend * 3

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
  metadata {
    name      = "default-deny-all"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "allow_backend_to_mongodb" {
  metadata {
    name      = "allow-backend-to-mongodb"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = local.backend_labels
    }

    policy_types = ["Egress"]

    egress {
      to {
        pod_selector {
          match_labels = local.mongodb_labels
        }
      }
      ports {
        port     = "27017"
        protocol = "TCP"
      }
    }
  }
}

# Outputs
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
