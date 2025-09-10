# Monitoring Infrastructure with Terraform
# This file manages Prometheus, Grafana, and monitoring resources

# Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring-${var.environment}"
    labels = merge(local.common_labels, {
      component = "monitoring"
      purpose   = "observability"
    })
  }

  lifecycle {
    ignore_changes = [metadata[0].labels]
  }
}

# Prometheus ConfigMap
resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "prometheus" })
  }

  data = {
    "prometheus.yml" = yamlencode({
      global = {
        scrape_interval     = "15s"
        evaluation_interval = "15s"
      }

      rule_files = [
        "/etc/prometheus/rules/*.yml"
      ]

      scrape_configs = [
        {
          job_name = "prometheus"
          static_configs = [
            {
              targets = ["localhost:9090"]
            }
          ]
        },
        {
          job_name = "healthcare-backend"
          kubernetes_sd_configs = [
            {
              role = "endpoints"
              namespaces = {
                names = ["${var.namespace}-${var.environment}"]
              }
            }
          ]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_service_annotation_prometheus_io_scrape"]
              action        = "keep"
              regex         = true
            },
            {
              source_labels = ["__meta_kubernetes_service_annotation_prometheus_io_path"]
              action        = "replace"
              target_label  = "__metrics_path__"
              regex         = "(.+)"
            },
            {
              source_labels = ["__address__", "__meta_kubernetes_service_annotation_prometheus_io_port"]
              action        = "replace"
              regex         = "([^:]+)(?::\\d+)?;(\\d+)"
              replacement   = "$1:$2"
              target_label  = "__address__"
            }
          ]
        },
        {
          job_name = "kubernetes-nodes"
          kubernetes_sd_configs = [
            {
              role = "node"
            }
          ]
          relabel_configs = [
            {
              action = "labelmap"
              regex  = "__meta_kubernetes_node_label_(.+)"
            }
          ]
        },
        {
          job_name = "kubernetes-pods"
          kubernetes_sd_configs = [
            {
              role = "pod"
              namespaces = {
                names = ["${var.namespace}-${var.environment}"]
              }
            }
          ]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_scrape"]
              action        = "keep"
              regex         = true
            },
            {
              source_labels = ["__meta_kubernetes_pod_annotation_prometheus_io_path"]
              action        = "replace"
              target_label  = "__metrics_path__"
              regex         = "(.+)"
            },
            {
              source_labels = ["__address__", "__meta_kubernetes_pod_annotation_prometheus_io_port"]
              action        = "replace"
              regex         = "([^:]+)(?::\\d+)?;(\\d+)"
              replacement   = "$1:$2"
              target_label  = "__address__"
            }
          ]
        }
      ]

      alerting = {
        alertmanagers = [
          {
            static_configs = [
              {
                targets = ["alertmanager:9093"]
              }
            ]
          }
        ]
      }
    })
  }
}

# Prometheus Rules ConfigMap
resource "kubernetes_config_map" "prometheus_rules" {
  metadata {
    name      = "prometheus-rules"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "prometheus" })
  }

  data = {
    "healthcare-app.yml" = yamlencode({
      groups = [
        {
          name = "healthcare-app.rules"
          rules = [
            {
              alert = "HighCPUUsage"
              expr  = "rate(container_cpu_usage_seconds_total{namespace=\"${var.namespace}-${var.environment}\"}[5m]) * 100 > 80"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "platform"
              }
              annotations = {
                summary     = "High CPU usage detected"
                description = "CPU usage is above 80% for more than 5 minutes in {{ $labels.namespace }}"
                runbook     = "https://docs.company.com/runbooks/high-cpu"
              }
            },
            {
              alert = "HighMemoryUsage"
              expr  = "container_memory_usage_bytes{namespace=\"${var.namespace}-${var.environment}\"} / container_spec_memory_limit_bytes * 100 > 90"
              for   = "5m"
              labels = {
                severity = "critical"
                team     = "platform"
              }
              annotations = {
                summary     = "High memory usage detected"
                description = "Memory usage is above 90% for more than 5 minutes in {{ $labels.namespace }}"
                runbook     = "https://docs.company.com/runbooks/high-memory"
              }
            },
            {
              alert = "ServiceDown"
              expr  = "up{job=\"healthcare-backend\"} == 0"
              for   = "1m"
              labels = {
                severity = "critical"
                team     = "backend"
              }
              annotations = {
                summary     = "Healthcare backend service is down"
                description = "The healthcare backend service has been down for more than 1 minute"
                runbook     = "https://docs.company.com/runbooks/service-down"
              }
            },
            {
              alert = "HighResponseTime"
              expr  = "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job=\"healthcare-backend\"}[5m])) > 1"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "backend"
              }
              annotations = {
                summary     = "High response time detected"
                description = "95th percentile response time is above 1 second for more than 5 minutes"
                runbook     = "https://docs.company.com/runbooks/high-response-time"
              }
            },
            {
              alert = "DatabaseConnectionFailure"
              expr  = "mongodb_connections_current{namespace=\"${var.namespace}-${var.environment}\"} < 1"
              for   = "2m"
              labels = {
                severity = "critical"
                team     = "database"
              }
              annotations = {
                summary     = "MongoDB connection failure"
                description = "MongoDB has no active connections for more than 2 minutes"
                runbook     = "https://docs.company.com/runbooks/mongodb-connection"
              }
            },
            {
              alert = "DiskSpaceLow"
              expr  = "(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 > 85"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "platform"
              }
              annotations = {
                summary     = "Low disk space"
                description = "Disk usage is above 85% for more than 5 minutes"
                runbook     = "https://docs.company.com/runbooks/low-disk-space"
              }
            },
            {
              alert = "PodRestartRateHigh"
              expr  = "rate(kube_pod_container_status_restarts_total{namespace=\"${var.namespace}-${var.environment}\"}[10m]) > 0.5"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "platform"
              }
              annotations = {
                summary     = "High pod restart rate"
                description = "Pods are restarting at a rate > 0.5 per minute for more than 5 minutes"
                runbook     = "https://docs.company.com/runbooks/pod-restarts"
              }
            },
            {
              alert = "SecurityVulnerabilityDetected"
              expr  = "healthcare_security_vulnerabilities_total{severity=\"critical\"} > 0"
              for   = "1m"
              labels = {
                severity = "critical"
                team     = "security"
              }
              annotations = {
                summary     = "Critical security vulnerability detected"
                description = "Critical security vulnerabilities found in the application"
                runbook     = "https://docs.company.com/runbooks/security-vulnerability"
              }
            },
            {
              alert = "APITimeoutRateHigh"
              expr  = "rate(http_request_duration_seconds_count{job=\"healthcare-backend\", status_code=\"408\"}[5m]) / rate(http_request_duration_seconds_count{job=\"healthcare-backend\"}[5m]) * 100 > 5"
              for   = "3m"
              labels = {
                severity = "warning"
                team     = "backend"
              }
              annotations = {
                summary     = "High API timeout rate"
                description = "API timeout rate is above 5% for more than 3 minutes"
                runbook     = "https://docs.company.com/runbooks/api-timeouts"
              }
            },
            {
              alert = "DatabaseSlowQuery"
              expr  = "rate(mongodb_op_counters_total{type=\"query\"}[5m]) > 1000"
              for   = "5m"
              labels = {
                severity = "info"
                team     = "database"
              }
              annotations = {
                summary     = "High database query rate"
                description = "Database query rate is unusually high (>1000 queries/minute)"
                runbook     = "https://docs.company.com/runbooks/database-performance"
              }
            }
          ]
        }
      ]
    })
  }
}

# Prometheus Deployment
resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "prometheus" })
  }

  spec {
    replicas = 1

    selector {
      match_labels = merge(local.common_labels, { component = "prometheus" })
    }

    template {
      metadata {
        labels = merge(local.common_labels, { component = "prometheus" })
      }

      spec {
        service_account_name = kubernetes_service_account.prometheus.metadata[0].name

        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.45.0"

          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/prometheus/",
            "--web.console.libraries=/etc/prometheus/console_libraries",
            "--web.console.templates=/etc/prometheus/consoles",
            "--storage.tsdb.retention.time=15d",
            "--web.enable-lifecycle"
          ]

          port {
            container_port = 9090
            name           = "prometheus"
          }

          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }

          volume_mount {
            name       = "prometheus-rules"
            mount_path = "/etc/prometheus/rules"
          }

          # Storage volume mount (always present - either PVC or emptyDir)
          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/prometheus"
          }

          resources {
            requests = {
              cpu    = "500m"
              memory = "1Gi"
            }
            limits = {
              cpu    = "1000m"
              memory = "2Gi"
            }
          }

          liveness_probe {
            http_get {
              path = "/-/healthy"
              port = "prometheus"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/-/ready"
              port = "prometheus"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "prometheus-config"
          config_map {
            name = kubernetes_config_map.prometheus_config.metadata[0].name
          }
        }

        volume {
          name = "prometheus-rules"
          config_map {
            name = kubernetes_config_map.prometheus_rules.metadata[0].name
          }
        }

        # Conditional volume for persistent storage
        dynamic "volume" {
          for_each = var.enable_persistent_storage ? [1] : []
          content {
            name = "prometheus-storage"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.prometheus_storage[0].metadata[0].name
            }
          }
        }

        # Fallback volume for non-persistent storage
        dynamic "volume" {
          for_each = var.enable_persistent_storage ? [] : [1]
          content {
            name = "prometheus-storage"
            empty_dir {}
          }
        }
      }
    }
  }
}

# Prometheus Service Account
resource "kubernetes_service_account" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "prometheus" })
  }
}

# Prometheus RBAC
resource "kubernetes_cluster_role" "prometheus" {
  metadata {
    name   = "prometheus-${var.environment}"
    labels = merge(local.common_labels, { component = "prometheus" })
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }

  lifecycle {
    ignore_changes = [metadata[0].labels]
  }
}

resource "kubernetes_cluster_role_binding" "prometheus" {
  metadata {
    name   = "prometheus-${var.environment}"
    labels = merge(local.common_labels, { component = "prometheus" })
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.prometheus.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.prometheus.metadata[0].name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}

# Prometheus PVC (conditional)
resource "kubernetes_persistent_volume_claim" "prometheus_storage" {
  count = var.enable_persistent_storage ? 1 : 0

  # Don't wait for binding since local-path uses WaitForFirstConsumer mode
  wait_until_bound = false

  metadata {
    name      = "prometheus-storage"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "prometheus" })
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.environment == "production" ? "50Gi" : "2Gi" # Smaller for staging
      }
    }
    # Use local-path storage class which is available in the cluster
    storage_class_name = "local-path"
  }

  timeouts {
    create = "120s" # Reduced timeout for staging PVC binding
  }
}

# Prometheus Service
resource "kubernetes_service" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "prometheus" })
  }

  spec {
    selector = merge(local.common_labels, { component = "prometheus" })

    port {
      port        = 9090
      target_port = "prometheus"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# Grafana ConfigMap
resource "kubernetes_config_map" "grafana_config" {
  metadata {
    name      = "grafana-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "grafana" })
  }

  data = {
    "grafana.ini" = <<-EOT
      [server]
      http_port = 3000
      root_url = http://localhost:3000/

      [database]
      type = sqlite3
      path = /var/lib/grafana/grafana.db

      [security]
      admin_user = admin
      admin_password = admin123

      [auth.anonymous]
      enabled = true
      org_role = Viewer

      [dashboards]
      default_home_dashboard_path = /etc/grafana/provisioning/dashboards/healthcare-dashboard.json
    EOT

    "datasources.yml" = yamlencode({
      apiVersion = 1
      datasources = [
        {
          name      = "Prometheus"
          type      = "prometheus"
          url       = "http://prometheus:9090"
          access    = "proxy"
          isDefault = true
        }
      ]
    })

    "dashboard-providers.yml" = yamlencode({
      apiVersion = 1
      providers = [
        {
          name   = "default"
          orgId  = 1
          folder = ""
          type   = "file"
          options = {
            path = "/etc/grafana/provisioning/dashboards"
          }
        }
      ]
    })

    "healthcare-dashboard.json" = jsonencode({
      dashboard = {
        id       = null
        title    = "Healthcare Application Dashboard"
        tags     = ["healthcare", "monitoring"]
        timezone = "browser"
        panels = [
          {
            id    = 1
            title = "CPU Usage"
            type  = "graph"
            targets = [
              {
                expr = "rate(container_cpu_usage_seconds_total{namespace=\"${var.namespace}-${var.environment}\"}[5m]) * 100"
              }
            ]
            yAxes = [
              {
                label = "Percentage"
                max   = 100
              }
            ]
          },
          {
            id    = 2
            title = "Memory Usage"
            type  = "graph"
            targets = [
              {
                expr = "container_memory_usage_bytes{namespace=\"${var.namespace}-${var.environment}\"} / 1024 / 1024"
              }
            ]
            yAxes = [
              {
                label = "MB"
              }
            ]
          },
          {
            id    = 3
            title = "HTTP Request Rate"
            type  = "graph"
            targets = [
              {
                expr = "rate(http_requests_total{job=\"healthcare-backend\"}[5m])"
              }
            ]
          },
          {
            id    = 4
            title = "Response Time (95th percentile)"
            type  = "graph"
            targets = [
              {
                expr = "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job=\"healthcare-backend\"}[5m]))"
              }
            ]
          }
        ]
        time = {
          from = "now-1h"
          to   = "now"
        }
        refresh = "30s"
      }
    })
  }
}

# Grafana Deployment
resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "grafana" })
  }

  spec {
    replicas = 1

    selector {
      match_labels = merge(local.common_labels, { component = "grafana" })
    }

    template {
      metadata {
        labels = merge(local.common_labels, { component = "grafana" })
      }

      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:10.0.0"

          port {
            container_port = 3000
            name           = "grafana"
          }

          env {
            name  = "GF_SECURITY_ADMIN_PASSWORD"
            value = "admin123"
          }

          volume_mount {
            name       = "grafana-config"
            mount_path = "/etc/grafana"
          }

          volume_mount {
            name       = "grafana-dashboards"
            mount_path = "/etc/grafana/provisioning/dashboards"
          }

          volume_mount {
            name       = "grafana-datasources"
            mount_path = "/etc/grafana/provisioning/datasources"
          }

          # Storage volume mount (always present - either PVC or emptyDir)
          volume_mount {
            name       = "grafana-storage"
            mount_path = "/var/lib/grafana"
          }

          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/api/health"
              port = "grafana"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/api/health"
              port = "grafana"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "grafana-config"
          config_map {
            name = kubernetes_config_map.grafana_config.metadata[0].name
            items {
              key  = "grafana.ini"
              path = "grafana.ini"
            }
          }
        }

        volume {
          name = "grafana-dashboards"
          config_map {
            name = kubernetes_config_map.grafana_config.metadata[0].name
            items {
              key  = "healthcare-dashboard.json"
              path = "healthcare-dashboard.json"
            }
            items {
              key  = "dashboard-providers.yml"
              path = "dashboard-providers.yml"
            }
          }
        }

        volume {
          name = "grafana-datasources"
          config_map {
            name = kubernetes_config_map.grafana_config.metadata[0].name
            items {
              key  = "datasources.yml"
              path = "datasources.yml"
            }
          }
        }

        # Conditional volume for persistent storage
        dynamic "volume" {
          for_each = var.enable_persistent_storage ? [1] : []
          content {
            name = "grafana-storage"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.grafana_storage[0].metadata[0].name
            }
          }
        }

        # EmptyDir fallback volume when persistent storage is disabled
        dynamic "volume" {
          for_each = var.enable_persistent_storage ? [] : [1]
          content {
            name = "grafana-storage"
            empty_dir {}
          }
        }
      }
    }
  }
}

# Grafana PVC (conditional)
resource "kubernetes_persistent_volume_claim" "grafana_storage" {
  count = var.enable_persistent_storage ? 1 : 0

  # Don't wait for binding since local-path uses WaitForFirstConsumer mode
  wait_until_bound = false

  metadata {
    name      = "grafana-storage"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "grafana" })
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    # Use local-path storage class which is available in the cluster
    storage_class_name = "local-path"
  }

  timeouts {
    create = "120s" # Reduced timeout for staging PVC binding
  }
}

# Grafana Service
resource "kubernetes_service" "grafana" {
  metadata {
    name      = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "grafana" })
  }

  spec {
    selector = merge(local.common_labels, { component = "grafana" })

    port {
      port        = 3000
      target_port = "grafana"
      protocol    = "TCP"
    }

    type = var.environment == "production" ? "LoadBalancer" : "NodePort"
  }
}

# Node Exporter DaemonSet for node metrics
resource "kubernetes_daemonset" "node_exporter" {
  metadata {
    name      = "node-exporter"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "node-exporter" })
  }

  spec {
    selector {
      match_labels = merge(local.common_labels, { component = "node-exporter" })
    }

    template {
      metadata {
        labels = merge(local.common_labels, { component = "node-exporter" })
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9100"
        }
      }

      spec {
        host_network = true
        host_pid     = true

        container {
          name  = "node-exporter"
          image = "prom/node-exporter:v1.6.0"

          args = [
            "--path.rootfs=/host",
            "--web.listen-address=0.0.0.0:9100"
          ]

          port {
            container_port = 9100
            host_port      = 9100
            name           = "metrics"
          }

          volume_mount {
            name       = "root"
            mount_path = "/host"
            read_only  = true
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

        volume {
          name = "root"
          host_path {
            path = "/"
          }
        }

        toleration {
          operator = "Exists"
        }
      }
    }
  }
}

# Monitoring outputs
output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_service" {
  description = "Prometheus service name"
  value       = kubernetes_service.prometheus.metadata[0].name
}

output "grafana_service" {
  description = "Grafana service name"
  value       = kubernetes_service.grafana.metadata[0].name
}

output "prometheus_url" {
  description = "Prometheus URL for internal access"
  value       = "http://${kubernetes_service.prometheus.metadata[0].name}.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:9090"
}

output "grafana_url" {
  description = "Grafana URL for internal access"
  value       = "http://${kubernetes_service.grafana.metadata[0].name}.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:3000"
}
