# Ingress Controller and Application Ingress with Terraform
# This file manages ingress resources and external access

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
      host = var.environment == "production" ? "monitoring.company.com" : "localhost"

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

        path {
          path      = "/alertmanager"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.alertmanager.metadata[0].name
              port {
                number = 9093
              }
            }
          }
        }

        path {
          path      = "/mongodb-exporter"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.mongodb_exporter.metadata[0].name
              port {
                number = 9216
              }
            }
          }
        }

        dynamic "path" {
          for_each = var.enable_distributed_tracing ? [1] : []
          content {
            path      = "/jaeger"
            path_type = "Prefix"
            backend {
              service {
                name = kubernetes_service.jaeger[0].metadata[0].name
                port {
                  number = 16686
                }
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

# Healthcare Application Ingress with MIME Type Configuration
resource "kubernetes_ingress_v1" "healthcare_app" {
  metadata {
    name      = "healthcare-ingress"
    namespace = "${var.namespace}-${var.environment}"
    labels    = merge(local.common_labels, { component = "application" })
    annotations = {
      "kubernetes.io/ingress.class"                    = "nginx"
      "nginx.ingress.kubernetes.io/rewrite-target"     = "/$2"
      "nginx.ingress.kubernetes.io/use-regex"          = "true"
      "nginx.ingress.kubernetes.io/configuration-snippet" = <<EOF
      # MIME type configuration for static assets
      if ($uri ~* \.js$) {
          more_set_headers 'Content-Type: application/javascript';
      }
      if ($uri ~* \.json$) {
          more_set_headers 'Content-Type: application/json';
      }
      if ($uri ~* \.css$) {
          more_set_headers 'Content-Type: text/css';
      }
      EOF
    }
  }

  spec {
    rule {
      host = var.environment == "production" ? "healthcare.company.com" : "localhost"

      http {
        # Grafana monitoring
        path {
          path      = "/grafana(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "grafana"
              port {
                number = 3000
              }
            }
          }
        }

        # Prometheus monitoring
        path {
          path      = "/prometheus(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "prometheus"
              port {
                number = 9090
              }
            }
          }
        }

        # Alertmanager monitoring
        path {
          path      = "/alertmanager(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "alertmanager"
              port {
                number = 9093
              }
            }
          }
        }

        # API backend
        path {
          path      = "/api(/|$)(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "backend"
              port {
                number = 5001
              }
            }
          }
        }

        # Frontend application (catch-all)
        path {
          path      = "/(.*)"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "frontend"
              port {
                number = 30285
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.healthcare
  ]
}

# Healthcare Application Namespace
resource "kubernetes_namespace" "healthcare_app" {
  count = var.environment == "production" ? 1 : 0  # Only create for production

  metadata {
    name = "${var.namespace}-${var.environment}"
    labels = {
      "app.kubernetes.io/name"       = "healthcare-app"
      "app.kubernetes.io/component"  = "application"
      "app.kubernetes.io/part-of"    = "healthcare-system"
      environment                    = var.environment
    }
  }
}

# Outputs for ingress
output "app_ingress_host" {
  description = "Application ingress hostname"
  value       = var.environment == "production" ? "healthcare.company.com" : "localhost"
}

output "monitoring_ingress_host" {
  description = "Monitoring ingress hostname"
  value       = var.environment == "production" ? "monitoring.company.com" : "localhost"
}

output "grafana_external_url" {
  description = "External Grafana URL"
  value       = var.environment == "production" ? "https://monitoring.company.com/grafana" : "http://localhost/grafana"
}

output "healthcare_app_url" {
  description = "Healthcare application URL"
  value       = var.environment == "production" ? "https://healthcare.company.com" : "http://localhost:30285"
}
