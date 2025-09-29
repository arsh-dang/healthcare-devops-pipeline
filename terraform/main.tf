# Random password for MongoDB (only if not provided via variable)
resource "random_password" "mongodb_password" {
  count = var.mongodb_root_password == "" ? 1 : 0
  
  length  = 32
  special = false  # Changed to false to avoid special characters like % that can cause issues
  upper   = true
  lower   = true
  numeric = true
}

# Random encryption key for additional data protection
resource "random_password" "encryption_key" {
  count = var.enable_encryption ? 1 : 0
  
  length  = 32
  special = false  # Changed to false to avoid special characters
  upper   = true
  lower   = true
  numeric = true
}

# Healthcare DevOps Infrastructure as Code
# Supports multiple environments with integrated monitoring

# Healthcare namespace
resource "kubernetes_namespace" "healthcare" {
  metadata {
    name = "${var.namespace}-${var.environment}"
    labels = merge(local.common_labels, {
      component = "healthcare"
      purpose   = "application"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].labels]
  }
}

# Application secrets
resource "kubernetes_secret" "app_secrets" {
  depends_on = [kubernetes_namespace.healthcare]

  metadata {
    name      = "healthcare-app-secrets"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
  }

  type = "Opaque"

  data = {
    "mongodb-root-password" = local.mongodb_password
  }

  lifecycle {
    ignore_changes = [metadata[0].labels]
  }
}

# Application configuration
resource "kubernetes_config_map" "app_config" {
  depends_on = [kubernetes_namespace.healthcare]

  metadata {
    name      = "healthcare-app-config"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "API_RATE_LIMIT"          = "100"
    "API_TIMEOUT"             = "30000"
    "CORS_ORIGIN"             = "*"
    "HEALTH_CHECK_INTERVAL"   = "30"
    "LOG_LEVEL"               = "debug"
    "MAX_CONNECTIONS"         = "10"
    "MONGODB_DATABASE"        = "healthcare-app"
    "NODE_ENV"                = var.environment
    "PROMETHEUS_METRICS_PORT" = "9090"
  }
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
  
  # Encryption configuration (simplified without AWS KMS)
  encryption_enabled = var.enable_encryption
  kms_key_arn = var.enable_encryption ? "local-encryption-key" : ""
}

resource "kubernetes_stateful_set" "mongodb" {
  # MongoDB StatefulSet with backend sidecar
  wait_for_rollout = false
  
  metadata {
    name      = var.environment == "production" ? "mongodb" : "mongodb-staging"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.mongodb_labels
  }

  spec {
    service_name = var.environment == "production" ? "mongodb" : "mongodb-staging"
    replicas     = 1

    selector {
      match_labels = local.mongodb_labels
    }

    template {
      metadata {
        labels = local.mongodb_labels
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

          security_context {
            run_as_user                = 999
            run_as_group               = 999
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
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

          startup_probe {
            tcp_socket {
              port = "mongodb"
            }
            initial_delay_seconds = 30
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 12
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
            failure_threshold     = 3
          }

          security_context {
            run_as_non_root            = true
            run_as_user                = 1000
            allow_privilege_escalation = false
            read_only_root_filesystem  = false
          }
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

  timeouts {
    create = "120s" # 2 minute timeout for stateful set creation
    update = "120s" # 2 minute timeout for stateful set updates
  }
}

# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
  wait_for_rollout = false

  timeouts {
    create = "120s" # 2 minute timeout for frontend deployment
    update = "120s" # 2 minute timeout for frontend updates
  }

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
            container_port = 80
            name           = "http"
          }

          # Environment variables for frontend configuration
          env {
            name  = "NODE_ENV"
            value = "production"
          }

          env {
            name  = "REACT_APP_API_BASE_URL"
            value = ""  # Empty for relative URLs via nginx proxy
          }

          env {
            name  = "REACT_APP_ENVIRONMENT"
            value = var.environment
          }

          env {
            name  = "REACT_APP_VERSION"
            value = var.app_version
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

resource "kubernetes_service" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.backend_labels
  }

  spec {
    selector = local.mongodb_labels  # Backend runs as sidecar in MongoDB StatefulSet

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
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Horizontal Pod Autoscalers
# resource "kubernetes_horizontal_pod_autoscaler_v2" "mongodb_hpa" {
#   metadata {
#     name      = "mongodb-hpa"
#     namespace = kubernetes_namespace.healthcare.metadata[0].name
#   }

#   spec {
#     scale_target_ref {
#       api_version = "apps/v1"
#       kind        = "StatefulSet"
#       name        = kubernetes_stateful_set.mongodb.metadata[0].name
#     }

#     min_replicas = 1
#     max_replicas = 1  # Fixed: Reduced from 3 to 1 to prevent scaling issues

#     metric {
#       type = "Resource"
#       resource {
#         name = "cpu"
#         target {
#           type                = "Utilization"
#           average_utilization = 70
#         }
#       }
#     }

#     metric {
#       type = "Resource"
#       resource {
#         name = "memory"
#         target {
#           type                = "Utilization"
#           average_utilization = 80
#         }
#       }
#     }
#   }
# }

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
        port     = "80"
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
      match_labels = local.mongodb_labels  # Backend runs as sidecar in MongoDB pod
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

    # Allow integration tests and other internal pods
    ingress {
      from {
        pod_selector {
          match_labels = local.common_labels
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
        port     = "80"
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
              command = ["sh", "-c"]
              args = ["mongodump --host ${var.environment == "production" ? "mongodb" : "mongodb-staging"} --username admin --password $MONGO_PASSWORD --authenticationDatabase admin --db healthcare-app --out /backup/backup_$(date +%Y%m%d_%H%M%S)"]

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

resource "kubernetes_config_map" "data_transfer_policy" {
  count = var.enable_data_transfer_controls ? 1 : 0
  
  metadata {
    name      = "data-transfer-policy"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "transfer-policy.json" = jsonencode({
      version = "1.0"
      organization = "Healthcare App Corporation"
      data_transfer_rules = [
        {
          purpose = "EU-US Data Transfers"
          legal_basis = "Standard Contractual Clauses"
          safeguards = [
            "SCCs implemented",
            "Data minimization",
            "Encryption in transit",
            "Regular audits"
          ]
          restricted_countries = []
          approval_required = false
        },
        {
          purpose = "Third-party processing"
          legal_basis = "Legitimate interest"
          safeguards = [
            "DPA executed",
            "Security assessments",
            "Incident notification",
            "Audit rights"
          ]
          restricted_countries = ["CN", "RU", "IR", "KP"]
          approval_required = true
        }
      ]
      audit_trail = {
        enabled = true
        retention_days = 2555  # 7 years
        log_transfers = true
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
          enabled = true
          max_response_days = 30
          automated_processing = true
        }
        rectification = {
          enabled = true
          max_response_days = 30
          automated_processing = true
        }
        erasure = {
          enabled = true
          max_response_days = 30
          automated_processing = true
          exceptions = ["legal-obligation", "public-interest", "research"]
        }
        restriction = {
          enabled = true
          max_response_days = 30
          automated_processing = true
        }
        portability = {
          enabled = true
          max_response_days = 30
          formats = ["json", "xml", "csv"]
          automated_processing = true
        }
        objection = {
          enabled = true
          max_response_days = 30
          automated_processing = true
        }
      }
      consent_management = {
        enabled = true
        granular_consent = true
        withdrawal_enabled = true
        consent_log_retention = 2555  # 7 years
      }
      breach_notification = {
        enabled = true
        supervisory_authority_deadline_hours = 72
        affected_individuals_deadline_days = 1
        automated_detection = true
      }
    })
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
