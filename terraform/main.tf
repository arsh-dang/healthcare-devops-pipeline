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
  monitoring_labels = merge(local.common_labels, { component = "monitoring" })
  
  # Use provided password or generate random one
  mongodb_password = var.mongodb_root_password != "" ? var.mongodb_root_password : random_password.mongodb_password[0].result
}

# Random password for MongoDB (only if not provided via variable)
resource "random_password" "mongodb_password" {
  count = var.mongodb_root_password == "" ? 1 : 0
  
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Kubernetes Namespace for application
resource "kubernetes_namespace" "healthcare" {
  metadata {
    name = "${var.namespace}-${var.environment}"
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
  }

  type = "Opaque"

  data = {
    mongodb-root-password = local.mongodb_password
    jwt-secret            = "super-secret-jwt-key-${var.environment}"
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
    service_name = "mongodb"
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
          image = "mongo:7.0.1"
          image_pull_policy = "IfNotPresent"

          # Command to initialize MongoDB with authentication
          command = ["/bin/bash"]
          args    = ["-c", <<-EOT
            #!/bin/bash
            set -e
            
            echo "Starting MongoDB initialization..."
            
            # Check if MongoDB has been initialized
            if [ ! -f /data/db/.mongodb_initialized ]; then
              echo "First run - initializing MongoDB without auth..."
              
              # Start MongoDB without auth for initialization
              mongod --bind_ip 127.0.0.1 --dbpath /data/db --logpath /var/log/mongodb/init.log --fork
              
              # Wait for MongoDB to start
              sleep 5
              
              echo "Creating admin user..."
              # Use environment variable directly in mongosh
              mongosh --eval "
                const password = process.env.MONGO_INITDB_ROOT_PASSWORD;
                db.getSiblingDB('admin').createUser({
                  user: 'admin',
                  pwd: password,
                  roles: [
                    { role: 'userAdminAnyDatabase', db: 'admin' },
                    { role: 'readWriteAnyDatabase', db: 'admin' },
                    { role: 'dbAdminAnyDatabase', db: 'admin' },
                    { role: 'clusterAdmin', db: 'admin' }
                  ]
                });
                
                db.getSiblingDB('healthcare-app').createUser({
                  user: 'admin',
                  pwd: password,
                  roles: [
                    { role: 'readWrite', db: 'healthcare-app' },
                    { role: 'dbAdmin', db: 'healthcare-app' }
                  ]
                });
              "
              
              # Stop the temporary MongoDB instance
              mongod --dbpath /data/db --shutdown
              
              # Mark as initialized
              touch /data/db/.mongodb_initialized
              echo "MongoDB initialization complete."
            else
              echo "MongoDB already initialized, starting with auth..."
            fi
            
            # Start MongoDB with authentication
            echo "Starting MongoDB with authentication..."
            exec mongod --bind_ip 127.0.0.1 --auth --dbpath /data/db --logpath /var/log/mongodb/mongod.log
            EOT
          ]

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
              command = ["/bin/bash", "-c", "mongosh --username admin --password \"$MONGO_INITDB_ROOT_PASSWORD\" --authenticationDatabase admin --eval 'db.adminCommand(\"ping\")'"]
            }
            initial_delay_seconds = 60
            period_seconds        = 10
          }

          readiness_probe {
            exec {
              command = ["/bin/bash", "-c", "mongosh --username admin --password \"$MONGO_INITDB_ROOT_PASSWORD\" --authenticationDatabase admin --eval 'db.adminCommand(\"ping\")'"]
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }

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
            name  = "MONGODB_HOST"
            value = "127.0.0.1"
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

          # Datadog APM environment variables
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
            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = "http"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 6
          }

          # Security context
          security_context {
            run_as_non_root            = true
            run_as_user                = 1000
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
          }
      }
    }

    }

    volume_claim_template {
      metadata {
        name = "mongodb-data"
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
        name = "mongodb-logs"
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
}
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

          # Writable /tmp for nginx temp dirs when root FS is read-only
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

    type = "ClusterIP"
  }
}

# Optional Datadog Agent via Helm (when enabled)
resource "helm_release" "datadog" {
  count      = var.enable_datadog ? 1 : 0
  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"
  namespace  = kubernetes_namespace.healthcare.metadata[0].name

  set {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }

  set {
    name  = "datadog.site"
    value = "datadoghq.com"
  }

  set {
    name  = "datadog.env"
    value = var.environment
  }

  set {
    name  = "agents.containerLogs.enabled"
    value = "true"
  }

  set {
    name  = "datadog.apm.enabled"
    value = "true"
  }

  set {
    name  = "clusterAgent.enabled"
    value = "true"
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
    selector = local.mongodb_labels  # Point to MongoDB pod which contains backend

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
      match_labels = local.mongodb_labels  # Backend now runs in MongoDB pod
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
    }

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
        protocol = "TCP"
      }
    }

    # Allow MongoDB connection (backend to MongoDB within same pod)
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
resource "kubernetes_network_policy" "allow_backend_ingress" {
  metadata {
    name      = "allow-backend-ingress"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
  }

  spec {
    pod_selector {
      match_labels = local.mongodb_labels  # Backend runs in MongoDB pod
    }

    policy_types = ["Ingress"]

    ingress {
      ports {
        port     = "5000"
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
    }

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
        protocol = "TCP"
      }
    }

    # Allow frontend to backend communication
    egress {
      to {
        pod_selector {
          match_labels = local.mongodb_labels  # Backend runs in MongoDB pod
        }
      }
      ports {
        port     = "5000"
        protocol = "TCP"
      }
    }
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
    schedule = "0 2 * * *"  # Daily at 2 AM
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
              name  = "mongodb-backup"
              image = "mongo:7.0.1"
              command = [
                "sh",
                "-c",
                "mongodump --host mongodb --username $MONGO_USERNAME --password $MONGO_PASSWORD --authenticationDatabase admin --db healthcare-app --out /backup/$(date +%Y%m%d_%H%M%S)"
              ]

              env {
                name = "MONGO_USERNAME"
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
