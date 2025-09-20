# Nginx Proxy Manager and External Services Configuration
# This file configures Nginx Proxy Manager and external NodePort services
# for the healthcare application

# Module Variables
variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "app_version" {
  description = "Application version"
  type        = string
}

variable "common_labels" {
  description = "Common labels for resources"
  type        = map(string)
}

variable "monitoring_labels" {
  description = "Monitoring labels for resources"
  type        = map(string)
}

variable "frontend_labels" {
  description = "Frontend labels for resources"
  type        = map(string)
}

variable "backend_labels" {
  description = "Backend labels for resources"
  type        = map(string)
}

variable "enable_nginx_proxy_manager" {
  description = "Enable Nginx Proxy Manager deployment"
  type        = bool
  default     = true
}

# Local values for this module
locals {
  mongodb_labels = merge(var.common_labels, { component = "mongodb" })
}

# Nginx Proxy Manager Deployment
resource "kubernetes_deployment" "nginx_proxy_manager" {
  count = var.enable_nginx_proxy_manager ? 1 : 0

  metadata {
    name      = "nginx-proxy-manager"
    namespace = var.namespace
    labels = merge(var.common_labels, {
      app = "nginx-proxy-manager"
      component = "proxy"
    })
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx-proxy-manager"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx-proxy-manager"
        }
      }

      spec {
        container {
          name  = "nginx-proxy-manager"
          image = "jc21/nginx-proxy-manager:latest"
          image_pull_policy = "IfNotPresent"

          port {
            container_port = 80
            name           = "http"
            host_port      = 80
          }

          port {
            container_port = 443
            name           = "https"
            host_port      = 443
          }

          port {
            container_port = 81
            name           = "admin"
            host_port      = 81
          }

          env {
            name  = "DB_SQLITE_FILE"
            value = "/opt/nginx-proxy-manager/database.sqlite"
          }

          volume_mount {
            name       = "data"
            mount_path = "/opt/nginx-proxy-manager"
          }

          volume_mount {
            name       = "letsencrypt"
            mount_path = "/etc/letsencrypt"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          # Startup probe
          startup_probe {
            http_get {
              path = "/login"
              port = "admin"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 30
          }

          # Liveness probe
          liveness_probe {
            http_get {
              path = "/login"
              port = "admin"
            }
            initial_delay_seconds = 60
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          # Readiness probe
          readiness_probe {
            http_get {
              path = "/login"
              port = "admin"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }

        volume {
          name = "data"
          host_path {
            path = "/opt/nginx-proxy-manager"
            type = "DirectoryOrCreate"
          }
        }

        volume {
          name = "letsencrypt"
          host_path {
            path = "/opt/nginx-proxy-manager/letsencrypt"
            type = "DirectoryOrCreate"
          }
        }

        # Security context
        security_context {
          run_as_user  = 0
          run_as_group = 0
          fs_group     = 0
        }
      }
    }
  }
}

# Nginx Proxy Manager Service (HostPort based)
resource "kubernetes_service" "nginx_proxy_manager" {
  count = var.enable_nginx_proxy_manager ? 1 : 0

  metadata {
    name      = "nginx-proxy-manager"
    namespace = var.namespace
    labels = merge(var.common_labels, {
      app = "nginx-proxy-manager"
      component = "proxy"
    })
  }

  spec {
    selector = {
      app = "nginx-proxy-manager"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "http"
    }

    port {
      port        = 443
      target_port = 443
      protocol    = "TCP"
      name        = "https"
    }

    port {
      port        = 81
      target_port = 81
      protocol    = "TCP"
      name        = "admin"
    }

    type = "ClusterIP"  # Using ClusterIP since we're using hostPort
  }
}

# External NodePort Services for all components
resource "kubernetes_service" "frontend_external" {
  metadata {
    name      = "frontend-external"
    namespace = var.namespace
    labels    = var.frontend_labels
  }

  spec {
    selector = var.frontend_labels

    port {
      port        = 80
      target_port = 30285
      protocol    = "TCP"
      node_port   = 32710
    }

    type = "NodePort"
  }
}

resource "kubernetes_service" "backend_external" {
  metadata {
    name      = "backend-external"
    namespace = var.namespace
    labels    = var.backend_labels
  }

  spec {
    selector = var.backend_labels  # Backend runs in MongoDB pod

    port {
      port        = 5001
      target_port = 5001
      protocol    = "TCP"
      node_port   = 32711
    }

    type = "NodePort"
  }
}

resource "kubernetes_service" "grafana_external" {
  metadata {
    name      = "grafana-external"
    namespace = var.namespace
    labels = {
      app = "grafana"
    }
  }

  spec {
    selector = {
      app = "grafana"
    }

    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
      node_port   = 32712
    }

    type = "NodePort"
  }
}

resource "kubernetes_service" "prometheus_external" {
  metadata {
    name      = "prometheus-external"
    namespace = var.namespace
    labels = {
      app = "prometheus"
    }
  }

  spec {
    selector = {
      app = "prometheus"
    }

    port {
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
      node_port   = 32713
    }

    type = "NodePort"
  }
}

resource "kubernetes_service" "alertmanager_external" {
  metadata {
    name      = "alertmanager-external"
    namespace = var.namespace
    labels = {
      app = "alertmanager"
    }
  }

  spec {
    selector = {
      app = "alertmanager"
    }

    port {
      port        = 9093
      target_port = 9093
      protocol    = "TCP"
      node_port   = 32714
    }

    type = "NodePort"
  }
}

resource "kubernetes_service" "jaeger_external" {
  metadata {
    name      = "jaeger-external"
    namespace = var.namespace
    labels = {
      app = "jaeger"
    }
  }

  spec {
    selector = {
      app = "jaeger"
    }

    port {
      port        = 16686
      target_port = 16686
      protocol    = "TCP"
      node_port   = 32715
    }

    type = "NodePort"
  }
}

# ConfigMap for Nginx Proxy Manager default configuration
resource "kubernetes_config_map" "nginx_proxy_manager_config" {
  count = var.enable_nginx_proxy_manager ? 1 : 0

  metadata {
    name      = "nginx-proxy-manager-config"
    namespace = var.namespace
    labels = merge(var.common_labels, {
      app = "nginx-proxy-manager"
      component = "proxy"
    })
  }

  data = {
    "default-site.conf" = <<-EOT
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    location / {
        return 200 '{"status":"Nginx Proxy Manager","message":"Configure proxy hosts to route traffic"}';
        add_header Content-Type application/json;
    }

    location /health {
        access_log off;
        return 200 '{"status":"ok","service":"nginx-proxy-manager"}';
        add_header Content-Type application/json;
    }
}
EOT
  }
}
