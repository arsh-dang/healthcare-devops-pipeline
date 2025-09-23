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

# Application Ingress for external access - Separate Frontend and Backend
resource "kubernetes_ingress_v1" "frontend" {
  metadata {
    name      = "frontend-ingress"
    namespace = "${var.namespace}-${var.environment}"
    labels    = merge(local.common_labels, { component = "frontend" })
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
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
      host = var.environment == "production" ? "healthcare.company.com" : "localhost"

      http {
        dynamic "path" {
          for_each = var.environment == "staging" ? [1] : []
          content {
            path      = "/staging/"
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

        dynamic "path" {
          for_each = var.environment == "production" ? [1] : []
          content {
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

        # Default path for blue-green deployments and other environments
        dynamic "path" {
          for_each = (var.environment != "staging" && var.environment != "production") ? [1] : []
          content {
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
}

resource "kubernetes_ingress_v1" "backend" {
  metadata {
    name      = "backend-ingress"
    namespace = "${var.namespace}-${var.environment}"
    labels    = merge(local.common_labels, { component = "backend" })
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/api/$2"
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
      host = var.environment == "production" ? "healthcare.company.com" : "localhost"

      http {
        dynamic "path" {
          for_each = var.environment == "staging" ? [1] : []
          content {
            path      = "/staging/api(/|$)(.*)"
            path_type = "ImplementationSpecific"

            backend {
              service {
                name = kubernetes_service.backend.metadata[0].name
                port {
                  number = 5001
                }
              }
            }
          }
        }

        dynamic "path" {
          for_each = var.environment == "production" ? [1] : []
          content {
            path      = "/api(/|$)(.*)"
            path_type = "ImplementationSpecific"

            backend {
              service {
                name = kubernetes_service.backend.metadata[0].name
                port {
                  number = 5001
                }
              }
            }
          }
        }

        # Default path for blue-green deployments and other environments
        dynamic "path" {
          for_each = (var.environment != "staging" && var.environment != "production") ? [1] : []
          content {
            path      = "/api(/|$)(.*)"
            path_type = "ImplementationSpecific"

            backend {
              service {
                name = kubernetes_service.backend.metadata[0].name
                port {
                  number = 5001
                }
              }
            }
          }
        }
      }
    }
  }
}

# Monitoring Ingress for Grafana and Prometheus access
# resource "kubernetes_ingress_v1" "monitoring" {
#   metadata {
#     name      = "monitoring-ingress"
#     namespace = kubernetes_namespace.monitoring[0].metadata[0].name
#     labels    = merge(local.common_labels, { component = "monitoring" })
#     annotations = {
#       "kubernetes.io/ingress.class"                = "nginx"
#       "nginx.ingress.kubernetes.io/rewrite-target" = "/"
#       "nginx.ingress.kubernetes.io/auth-type"      = var.environment == "production" ? "basic" : ""
#       "nginx.ingress.kubernetes.io/auth-secret"    = var.environment == "production" ? "monitoring-auth" : ""
#     }
#   }

#   spec {
#     dynamic "tls" {
#       for_each = var.environment == "production" ? [1] : []
#       content {
#         hosts       = ["monitoring.company.com"]
#         secret_name = "monitoring-tls"
#       }
#     }

#     rule {
#       host = var.environment == "production" ? "monitoring.company.com" : "localhost"

#       http {
#         dynamic "path" {
#           for_each = var.environment == "staging" ? [1] : []
#           content {
#             path      = "/staging/grafana"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "grafana"
#                 port {
#                   number = 3000
#                 }
#               }
#             }
#           }
#         }

#         dynamic "path" {
#           for_each = var.environment == "production" ? [1] : []
#           content {
#             path      = "/grafana"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "grafana"
#                 port {
#                   number = 3000
#                 }
#               }
#             }
#           }
#         }

#         # Default Grafana path for blue-green deployments
#         dynamic "path" {
#           for_each = (var.environment != "staging" && var.environment != "production") ? [1] : []
#           content {
#             path      = "/grafana"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "grafana"
#                 port {
#                   number = 3000
#                 }
#               }
#             }
#           }
#         }

#         dynamic "path" {
#           for_each = var.environment == "staging" ? [1] : []
#           content {
#             path      = "/staging/prometheus"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "prometheus"
#                 port {
#                   number = 9090
#                 }
#               }
#             }
#           }
#         }

#         dynamic "path" {
#           for_each = var.environment == "production" ? [1] : []
#           content {
#             path      = "/prometheus"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "prometheus"
#                 port {
#                   number = 9090
#                 }
#               }
#             }
#           }
#         }

#         # Default Prometheus path for blue-green deployments
#         dynamic "path" {
#           for_each = (var.environment != "staging" && var.environment != "production") ? [1] : []
#           content {
#             path      = "/prometheus"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "prometheus"
#                 port {
#                   number = 9090
#                 }
#               }
#             }
#           }
#         }

#         dynamic "path" {
#           for_each = var.environment == "staging" ? [1] : []
#           content {
#             path      = "/staging/alertmanager"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "alertmanager"
#                 port {
#                   number = 9093
#                 }
#               }
#             }
#           }
#         }

#         dynamic "path" {
#           for_each = var.environment == "production" ? [1] : []
#           content {
#             path      = "/alertmanager"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "alertmanager"
#                 port {
#                   number = 9093
#                 }
#               }
#             }
#           }
#         }

#         # Default Alertmanager path for blue-green deployments
#         dynamic "path" {
#           for_each = (var.environment != "staging" && var.environment != "production") ? [1] : []
#           content {
#             path      = "/alertmanager"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "alertmanager"
#                 port {
#                   number = 9093
#                 }
#               }
#             }
#           }
#         }

#         dynamic "path" {
#           for_each = var.environment == "staging" ? [1] : []
#           content {
#             path      = "/staging/mongodb-exporter"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "mongodb-exporter"
#                 port {
#                   number = 9216
#                 }
#               }
#             }
#           }
#         }

#         dynamic "path" {
#           for_each = var.environment == "production" ? [1] : []
#           content {
#             path      = "/mongodb-exporter"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "mongodb-exporter"
#                 port {
#                   number = 9216
#                 }
#               }
#             }
#           }
#         }

#         # Default MongoDB Exporter path for blue-green deployments
#         dynamic "path" {
#           for_each = (var.environment != "staging" && var.environment != "production") ? [1] : []
#           content {
#             path      = "/mongodb-exporter"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = "mongodb-exporter"
#                 port {
#                   number = 9216
#                 }
#               }
#             }
#           }
#         }

#         dynamic "path" {
#           for_each = var.enable_distributed_tracing ? [1] : []
#           content {
#             path      = "/jaeger"
#             path_type = "Prefix"

#             backend {
#               service {
#                 name = kubernetes_service.jaeger[0].metadata[0].name
#                 port {
#                   number = 16686
#                 }
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }

# Basic auth secret for production monitoring
# resource "kubernetes_secret" "monitoring_auth" {
#   count = var.environment == "production" ? 1 : 0

#   metadata {
#     name      = "monitoring-auth"
#     namespace = kubernetes_namespace.monitoring[0].metadata[0].name
#     labels    = merge(local.common_labels, { component = "monitoring" })
#   }

#   type = "Opaque"

#   data = {
#     # Generated with: htpasswd -nb admin monitoring123
#     auth = base64encode("admin:$2y$10$2Xw5Z1nPQmGVq5X1qEZKH.QwJUGVn8rJdKlh9z1z6c8X1h1QwqGVe")
#   }
# }

# Outputs for ingress
output "frontend_ingress_host" {
  description = "Frontend ingress hostname"
  value       = var.environment == "production" ? "healthcare.company.com" : "healthcare.local"
}

output "backend_ingress_host" {
  description = "Backend ingress hostname"
  value       = var.environment == "production" ? "healthcare.company.com" : "healthcare.local"
}

output "frontend_ingress_name" {
  description = "Frontend ingress resource name"
  value       = kubernetes_ingress_v1.frontend.metadata[0].name
}

output "backend_ingress_name" {
  description = "Backend ingress resource name"
  value       = kubernetes_ingress_v1.backend.metadata[0].name
}

output "app_ingress_host" {
  description = "Application ingress hostname (deprecated - use frontend_ingress_host)"
  value       = var.environment == "production" ? "healthcare.company.com" : "healthcare.local"
}

output "monitoring_ingress_host" {
  description = "Monitoring ingress hostname"
  value       = var.environment == "production" ? "monitoring.company.com" : "localhost"
}

output "grafana_external_url" {
  description = "External Grafana URL"
  value       = var.environment == "production" ? "https://monitoring.company.com/grafana" : "http://localhost/staging/grafana"
}
