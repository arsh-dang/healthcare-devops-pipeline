# Nginx Proxy Manager and External Services Configuration
# This file configures Nginx Proxy Manager and external NodePort services
# for the healthcare application

# All variables and locals are declared in main.tf and variables.tf

# Nginx Proxy Manager Deployment
resource "kubernetes_deployment" "nginx_proxy_manager" {
  count = var.enable_nginx_proxy_manager ? 1 : 0

  metadata {
    name      = "nginx-proxy-manager"
    namespace = "${var.namespace}-${var.environment}"
    labels = merge(local.common_labels, {
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
    namespace = "${var.namespace}-${var.environment}"
    labels = merge(local.common_labels, {
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

# ConfigMap for Nginx Proxy Manager default configuration
resource "kubernetes_config_map" "nginx_proxy_manager_config" {
  count = var.enable_nginx_proxy_manager ? 1 : 0

  metadata {
    name      = "nginx-proxy-manager-config"
    namespace = "${var.namespace}-${var.environment}"
    labels = merge(local.common_labels, {
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
        proxy_pass http://frontend.${var.namespace}-${var.environment}.svc.cluster.local:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API routing
    location /api/ {
        proxy_pass http://backend.${var.namespace}-${var.environment}.svc.cluster.local:5001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    }

    # Backend API routing
    location /api/ {
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
