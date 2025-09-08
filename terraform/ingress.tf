# Ingress Controller and Application Ingress with Terraform
# This file manages ingress resources for external access

# NGINX Ingress Controller (if not already installed)
resource "kubernetes_namespace" "ingress_nginx" {
  count = var.environment == "production" ? 1 : 0
  
  metadata {
    name = "ingress-nginx"
    labels = {
      "app.kubernetes.io/name"     = "ingress-nginx"
      "app.kubernetes.io/instance" = "ingress-nginx"
    }
  }
}

# Application Ingress for external access
resource "kubernetes_ingress_v1" "healthcare_app" {
  metadata {
    name      = "healthcare-app-ingress"
    namespace = "${var.namespace}-${var.environment}"
    labels    = local.common_labels
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect"   = var.environment == "production" ? "true" : "false"
      "cert-manager.io/cluster-issuer"             = var.environment == "production" ? "letsencrypt-prod" : "letsencrypt-staging"
    }
  }

  spec {
    dynamic "tls" {
      for_each = var.environment == "production" ? [1] : []
      content {
        hosts       = ["healthcare.company.com"]
        secret_name = "healthcare-app-tls"
      }
    }

    rule {
      host = var.environment == "production" ? "healthcare.company.com" : "healthcare-staging.local"

      http {
        path {
          path      = "/api/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.backend.metadata[0].name
              port {
                number = 5000
              }
            }
          }
        }

        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.frontend.metadata[0].name
              port {
                number = 3001
              }
            }
          }
        }
      }
    }
  }
}

# Monitoring Ingress for Grafana and Prometheus access
resource "kubernetes_ingress_v1" "monitoring" {
  metadata {
    name      = "monitoring-ingress"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "monitoring" })
    annotations = {
      "kubernetes.io/ingress.class"                = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "nginx.ingress.kubernetes.io/auth-type"      = var.environment == "production" ? "basic" : ""
      "nginx.ingress.kubernetes.io/auth-secret"    = var.environment == "production" ? "monitoring-auth" : ""
    }
  }

  spec {
    dynamic "tls" {
      for_each = var.environment == "production" ? [1] : []
      content {
        hosts       = ["monitoring.company.com"]
        secret_name = "monitoring-tls"
      }
    }

    rule {
      host = var.environment == "production" ? "monitoring.company.com" : "monitoring-staging.local"

      http {
        path {
          path      = "/grafana"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.grafana.metadata[0].name
              port {
                number = 3000
              }
            }
          }
        }

        path {
          path      = "/prometheus"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.prometheus.metadata[0].name
              port {
                number = 9090
              }
            }
          }
        }
      }
    }
  }
}

# Basic auth secret for production monitoring
resource "kubernetes_secret" "monitoring_auth" {
  count = var.environment == "production" ? 1 : 0

  metadata {
    name      = "monitoring-auth"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "monitoring" })
  }

  type = "Opaque"

  data = {
    # Generated with: htpasswd -nb admin monitoring123
    auth = base64encode("admin:$2y$10$2Xw5Z1nPQmGVq5X1qEZKH.QwJUGVn8rJdKlh9z1z6c8X1h1QwqGVe")
  }
}

# Outputs for ingress
output "app_ingress_host" {
  description = "Application ingress hostname"
  value       = var.environment == "production" ? "healthcare.company.com" : "healthcare-staging.local"
}

output "monitoring_ingress_host" {
  description = "Monitoring ingress hostname"
  value       = var.environment == "production" ? "monitoring.company.com" : "monitoring-staging.local"
}

output "grafana_external_url" {
  description = "External Grafana URL"
  value       = var.environment == "production" ? "https://monitoring.company.com/grafana" : "http://monitoring-staging.local/grafana"
}

output "prometheus_external_url" {
  description = "External Prometheus URL"
  value       = var.environment == "production" ? "https://monitoring.company.com/prometheus" : "http://monitoring-staging.local/prometheus"
}
