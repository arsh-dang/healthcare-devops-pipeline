# Monitoring Infrastructure with Terraform
# This file manages Prometheus, Grafana, Alertmanager, MongoDB Exporter, and monitoring resources

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

# Alertmanager ConfigMap
resource "kubernetes_config_map" "alertmanager_config" {
  metadata {
    name      = "alertmanager-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "alertmanager" })
  }

  data = {
    "alertmanager.yml" = yamlencode({
      global = {
        smtp_smarthost = "${var.smtp_server}:${var.smtp_port}"
        smtp_from      = var.smtp_from_email
        smtp_auth_username = var.smtp_username != "" ? var.smtp_username : null
        smtp_auth_password = var.smtp_password != "" ? var.smtp_password : null
      }

      route = {
        group_by        = ["alertname", "job", "severity"]
        group_wait      = "10s"
        group_interval  = "10s"
        repeat_interval = "1h"
        receiver        = "healthcare-info"

        routes = [
          {
            match = {
              severity = "critical"
            }
            receiver = "healthcare-critical"
          },
          {
            match = {
              severity = "warning"
            }
            receiver = "healthcare-warning"
          },
          {
            match = {
              severity = "info"
            }
            receiver = "healthcare-info"
          }
        ]
      }

      receivers = [
        {
          name = "healthcare-critical"
          email_configs = var.smtp_username != "" ? [
            {
              to           = var.alert_email_critical
              send_resolved = true
              headers = {
                subject = "{{ .GroupLabels.alertname }} - CRITICAL"
              }
              html = <<-EOT
                <h2>CRITICAL ALERT</h2>
                <p><strong>Alert:</strong> {{ .GroupLabels.alertname }}</p>
                <p><strong>Severity:</strong> {{ .GroupLabels.severity }}</p>
                <p><strong>Description:</strong> {{ .CommonAnnotations.description }}</p>
                <p><strong>Environment:</strong> ${var.environment}</p>
                <p><strong>Time:</strong> {{ .StartsAt.Format "2006-01-02 15:04:05" }}</p>
                <p><a href="http://monitoring-${var.environment == "production" ? "company.com" : "staging.local"}/grafana">View in Grafana</a></p>
              EOT
            }
          ] : []
          slack_configs = var.slack_webhook_critical != "" ? [
            {
              api_url = var.slack_webhook_critical
              channel = var.slack_channel_critical
              send_resolved = true
              title = "CRITICAL: {{ .GroupLabels.alertname }}"
              text = <<-EOT
                *Alert:* {{ .GroupLabels.alertname }}
                *Severity:* {{ .GroupLabels.severity }}
                *Description:* {{ .CommonAnnotations.description }}
                *Environment:* ${var.environment}
                *Time:* {{ .StartsAt.Format "2006-01-02 15:04:05" }}
                <http://monitoring-${var.environment == "production" ? "company.com" : "staging.local"}/grafana|View in Grafana>
              EOT
            }
          ] : []
        },
        {
          name = "healthcare-warning"
          email_configs = var.smtp_username != "" ? [
            {
              to           = var.alert_email_warning
              send_resolved = true
              headers = {
                subject = "{{ .GroupLabels.alertname }} - WARNING"
              }
              html = <<-EOT
                <h2>WARNING ALERT</h2>
                <p><strong>Alert:</strong> {{ .GroupLabels.alertname }}</p>
                <p><strong>Severity:</strong> {{ .GroupLabels.severity }}</p>
                <p><strong>Description:</strong> {{ .CommonAnnotations.description }}</p>
                <p><strong>Environment:</strong> ${var.environment}</p>
                <p><strong>Time:</strong> {{ .StartsAt.Format "2006-01-02 15:04:05" }}</p>
                <p><a href="http://monitoring-${var.environment == "production" ? "company.com" : "staging.local"}/grafana">View in Grafana</a></p>
              EOT
            }
          ] : []
          slack_configs = var.slack_webhook_warning != "" ? [
            {
              api_url = var.slack_webhook_warning
              channel = var.slack_channel_warning
              send_resolved = true
              title = "WARNING: {{ .GroupLabels.alertname }}"
              text = <<-EOT
                *Alert:* {{ .GroupLabels.alertname }}
                *Severity:* {{ .GroupLabels.severity }}
                *Description:* {{ .CommonAnnotations.description }}
                *Environment:* ${var.environment}
                *Time:* {{ .StartsAt.Format "2006-01-02 15:04:05" }}
                <http://monitoring-${var.environment == "production" ? "company.com" : "staging.local"}/grafana|View in Grafana>
              EOT
            }
          ] : []
        },
        {
          name = "healthcare-info"
          email_configs = var.smtp_username != "" ? [
            {
              to           = var.alert_email_info
              send_resolved = true
              headers = {
                subject = "{{ .GroupLabels.alertname }} - INFO"
              }
              html = <<-EOT
                <h2>ℹ️ INFO ALERT</h2>
                <p><strong>Alert:</strong> {{ .GroupLabels.alertname }}</p>
                <p><strong>Severity:</strong> {{ .GroupLabels.severity }}</p>
                <p><strong>Description:</strong> {{ .CommonAnnotations.description }}</p>
                <p><strong>Environment:</strong> ${var.environment}</p>
                <p><strong>Time:</strong> {{ .StartsAt.Format "2006-01-02 15:04:05" }}</p>
                <p><a href="http://monitoring-${var.environment == "production" ? "company.com" : "staging.local"}/grafana">View in Grafana</a></p>
              EOT
            }
          ] : []
          slack_configs = var.slack_webhook_info != "" ? [
            {
              api_url = var.slack_webhook_info
              channel = var.slack_channel_info
              send_resolved = true
              title = "ℹ️ INFO: {{ .GroupLabels.alertname }}"
              text = <<-EOT
                *Alert:* {{ .GroupLabels.alertname }}
                *Severity:* {{ .GroupLabels.severity }}
                *Description:* {{ .CommonAnnotations.description }}
                *Environment:* ${var.environment}
                *Time:* {{ .StartsAt.Format "2006-01-02 15:04:05" }}
                <http://monitoring-${var.environment == "production" ? "company.com" : "staging.local"}/grafana|View in Grafana>
              EOT
            }
          ] : []
        }
      ]

      inhibit_rules = [
        {
          source_match = {
            severity = "critical"
          }
          target_match = {
            severity = "warning"
          }
          equal = ["alertname", "namespace"]
        }
      ]
    })
  }
}

# Alertmanager Deployment
resource "kubernetes_deployment" "alertmanager" {
  metadata {
    name      = "alertmanager"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "alertmanager" })
  }

  spec {
    replicas = 1
    progress_deadline_seconds = 900  # 15 minutes timeout

    selector {
      match_labels = merge(local.common_labels, { component = "alertmanager" })
    }

    template {
      metadata {
        labels = merge(local.common_labels, { component = "alertmanager" })
      }

      spec {
        container {
          name  = "alertmanager"
          image = "prom/alertmanager:v0.26.0"

          args = [
            "--config.file=/etc/alertmanager/alertmanager.yml",
            "--storage.path=/alertmanager",
            "--web.listen-address=0.0.0.0:9093"
          ]

          port {
            container_port = 9093
            name           = "alertmanager"
          }

          volume_mount {
            name       = "alertmanager-config"
            mount_path = "/etc/alertmanager"
          }

          # Storage volume mount (always present - either PVC or emptyDir)
          volume_mount {
            name       = "alertmanager-storage"
            mount_path = "/alertmanager"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/-/healthy"
              port = "alertmanager"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/-/ready"
              port = "alertmanager"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "alertmanager-config"
          config_map {
            name = kubernetes_config_map.alertmanager_config.metadata[0].name
          }
        }

        # Conditional volume for persistent storage
        dynamic "volume" {
          for_each = var.enable_persistent_storage ? [1] : []
          content {
            name = "alertmanager-storage"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.alertmanager_storage[0].metadata[0].name
            }
          }
        }

        # Fallback volume for non-persistent storage
        dynamic "volume" {
          for_each = var.enable_persistent_storage ? [] : [1]
          content {
            name = "alertmanager-storage"
            empty_dir {}
          }
        }
      }
    }
  }
}

# Alertmanager PVC (conditional)
resource "kubernetes_persistent_volume_claim" "alertmanager_storage" {
  count = var.enable_persistent_storage ? 1 : 0

  # Don't wait for binding since local-path uses WaitForFirstConsumer mode
  wait_until_bound = false

  metadata {
    name      = "alertmanager-storage"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "alertmanager" })
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "2Gi"
      }
    }
    # Use local-path storage class which is available in the cluster
    storage_class_name = "local-path"
  }

  timeouts {
    create = "120s"
  }
}

# Alertmanager Service
resource "kubernetes_service" "alertmanager" {
  metadata {
    name      = "alertmanager"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "alertmanager" })
  }

  spec {
    selector = merge(local.common_labels, { component = "alertmanager" })

    port {
      port        = 9093
      target_port = "alertmanager"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# MongoDB Exporter Secret (copy from healthcare namespace)
resource "kubernetes_secret" "mongodb_exporter_secret" {
  metadata {
    name      = "healthcare-app-secrets"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "mongodb-exporter" })
  }

  type = "Opaque"

  data = {
    "mongodb-root-password" = data.kubernetes_secret.healthcare_app_secrets.data["mongodb-root-password"]
  }
}

# Data source to read the secret from healthcare namespace
data "kubernetes_secret" "healthcare_app_secrets" {
  metadata {
    name      = "healthcare-app-secrets"
    namespace = "${var.namespace}-${var.environment}"
  }
}
resource "kubernetes_config_map" "mongodb_exporter_config" {
  metadata {
    name      = "mongodb-exporter-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "mongodb-exporter" })
  }

  data = {
    "mongodb-exporter.env" = <<-EOT
      MONGODB_URI=mongodb://admin:$(cat /secrets/mongodb-password)@mongodb.healthcare-${var.environment}.svc.cluster.local:27017/healthcare-app?authSource=admin
      MONGODB_COLLECTOR=diagnosticdata,top,collections,indexusage,dbstats
    EOT
  }
}

# MongoDB Exporter Deployment
resource "kubernetes_deployment" "mongodb_exporter" {
  metadata {
    name      = "mongodb-exporter"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "mongodb-exporter" })
  }

  spec {
    replicas = 1
    progress_deadline_seconds = 900  # 15 minutes timeout

    selector {
      match_labels = merge(local.common_labels, { component = "mongodb-exporter" })
    }

    template {
      metadata {
        labels = merge(local.common_labels, { component = "mongodb-exporter" })
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "9216"
        }
      }

      spec {
        container {
          name  = "mongodb-exporter"
          image = "percona/mongodb_exporter:0.39"

          env_from {
            config_map_ref {
              name = kubernetes_config_map.mongodb_exporter_config.metadata[0].name
            }
          }

          env {
            name = "MONGODB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mongodb_exporter_secret.metadata[0].name
                key  = "mongodb-root-password"
              }
            }
          }

          port {
            container_port = 9216
            name           = "metrics"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/metrics"
              port = "metrics"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/metrics"
              port = "metrics"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# MongoDB Exporter Service
resource "kubernetes_service" "mongodb_exporter" {
  metadata {
    name      = "mongodb-exporter"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "mongodb-exporter" })
  }

  spec {
    selector = merge(local.common_labels, { component = "mongodb-exporter" })

    port {
      port        = 9216
      target_port = "metrics"
      protocol    = "TCP"
    }

    type = "ClusterIP"
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
              regex         = "([^:]+)(?::\\d+)?(\\d+)"
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
          job_name = "mongodb-exporter"
          kubernetes_sd_configs = [
            {
              role = "endpoints"
              namespaces = {
                names = ["monitoring-${var.environment}"]
              }
            }
          ]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_service_name"]
              action        = "keep"
              regex         = "mongodb-exporter"
            },
            {
              source_labels = ["__meta_kubernetes_endpoint_port_name"]
              action        = "keep"
              regex         = "metrics"
            }
          ]
        },
        # Enhanced monitoring scrape configs
        {
          job_name = "nginx-ingress-controller"
          kubernetes_sd_configs = [
            {
              role = "endpoints"
              namespaces = {
                names = ["monitoring-${var.environment}"]
              }
            }
          ]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_service_name"]
              action        = "keep"
              regex         = "ingress-nginx-controller"
            },
            {
              source_labels = ["__meta_kubernetes_endpoint_port_name"]
              action        = "keep"
              regex         = "metrics"
            }
          ]
        },
        {
          job_name = "fluent-bit"
          kubernetes_sd_configs = [
            {
              role = "endpoints"
              namespaces = {
                names = ["monitoring-${var.environment}"]
              }
            }
          ]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_service_name"]
              action        = "keep"
              regex         = "fluent-bit"
            },
            {
              source_labels = ["__meta_kubernetes_endpoint_port_name"]
              action        = "keep"
              regex         = "metrics"
            }
          ]
        },
        {
          job_name = "synthetic-monitoring"
          kubernetes_sd_configs = [
            {
              role = "endpoints"
              namespaces = {
                names = ["monitoring-${var.environment}"]
              }
            }
          ]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_service_name"]
              action        = "keep"
              regex         = "synthetic-monitoring"
            },
            {
              source_labels = ["__meta_kubernetes_endpoint_port_name"]
              action        = "keep"
              regex         = "metrics"
            }
          ]
        },
        {
          job_name = "jaeger"
          kubernetes_sd_configs = [
            {
              role = "endpoints"
              namespaces = {
                names = ["monitoring-${var.environment}"]
              }
            }
          ]
          relabel_configs = [
            {
              source_labels = ["__meta_kubernetes_service_name"]
              action        = "keep"
              regex         = "jaeger"
            },
            {
              source_labels = ["__meta_kubernetes_endpoint_port_name"]
              action        = "keep"
              regex         = "query"
            }
          ]
          metrics_path = "/metrics"
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
        },
        # Enhanced monitoring rules
        {
          name = "ingress-monitoring.rules"
          rules = [
            {
              alert = "IngressDown"
              expr  = "nginx_ingress_controller_requests_total{status!~\"2..\"} / nginx_ingress_controller_requests_total * 100 > 5"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "platform"
              }
              annotations = {
                summary     = "High ingress error rate detected"
                description = "Ingress error rate is above 5% for more than 5 minutes"
                runbook     = "https://docs.company.com/runbooks/ingress-errors"
              }
            },
            {
              alert = "IngressHighLatency"
              expr  = "histogram_quantile(0.95, rate(nginx_ingress_controller_request_duration_seconds_bucket[5m])) > 2"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "platform"
              }
              annotations = {
                summary     = "High ingress latency detected"
                description = "95th percentile ingress response time is above 2 seconds"
                runbook     = "https://docs.company.com/runbooks/ingress-latency"
              }
            }
          ]
        },
        {
          name = "log-aggregation.rules"
          rules = [
            {
              alert = "LogAggregationFailure"
              expr  = "up{job=\"fluent-bit\"} == 0"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "platform"
              }
              annotations = {
                summary     = "Log aggregation failure"
                description = "Fluent Bit log aggregation is down"
                runbook     = "https://docs.company.com/runbooks/log-aggregation"
              }
            },
            {
              alert = "HighLogVolume"
              expr  = "rate(fluentbit_output_proc_records_total[10m]) > 10000"
              for   = "5m"
              labels = {
                severity = "info"
                team     = "platform"
              }
              annotations = {
                summary     = "High log volume detected"
                description = "Log processing rate is unusually high (>10,000 logs/minute)"
                runbook     = "https://docs.company.com/runbooks/high-log-volume"
              }
            }
          ]
        },
        {
          name = "synthetic-monitoring.rules"
          rules = [
            {
              alert = "SyntheticTestFailure"
              expr  = "synthetic_health_check_success == 0"
              for   = "2m"
              labels = {
                severity = "critical"
                team     = "backend"
              }
              annotations = {
                summary     = "Synthetic health check failed"
                description = "Synthetic monitoring detected service unavailability"
                runbook     = "https://docs.company.com/runbooks/synthetic-failure"
              }
            },
            {
              alert = "HighSyntheticResponseTime"
              expr  = "synthetic_health_check_response_time > 2000"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "backend"
              }
              annotations = {
                summary     = "High synthetic response time"
                description = "Synthetic monitoring detected slow response times (>2s)"
                runbook     = "https://docs.company.com/runbooks/high-response-time"
              }
            }
          ]
        },
        {
          name = "distributed-tracing.rules"
          rules = [
            {
              alert = "TracingServiceDown"
              expr  = "up{job=\"jaeger\"} == 0"
              for   = "5m"
              labels = {
                severity = "info"
                team     = "platform"
              }
              annotations = {
                summary     = "Distributed tracing service down"
                description = "Jaeger tracing service is unavailable"
                runbook     = "https://docs.company.com/runbooks/tracing-down"
              }
            },
            {
              alert = "HighTracingErrorRate"
              expr  = "rate(jaeger_tracer_reporter_spans_total{state=\"error\"}[5m]) / rate(jaeger_tracer_reporter_spans_total[5m]) * 100 > 10"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "platform"
              }
              annotations = {
                summary     = "High tracing error rate"
                description = "Tracing spans error rate is above 10%"
                runbook     = "https://docs.company.com/runbooks/tracing-errors"
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
      root_url = http://monitoring-${var.environment == "production" ? "company.com" : "staging.local"}/grafana/

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

# Monitoring Backup CronJob
resource "kubernetes_cron_job_v1" "monitoring_backup" {
  metadata {
    name      = "monitoring-backup"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "monitoring", purpose = "backup" })
  }

  spec {
    schedule = "0 2 * * *"  # Daily at 2 AM
    job_template {
      metadata {
        labels = merge(local.common_labels, { component = "monitoring", purpose = "backup" })
      }
      spec {
        template {
          metadata {
            labels = merge(local.common_labels, { component = "monitoring", purpose = "backup" })
          }
          spec {
            container {
              name  = "monitoring-backup"
              image = "alpine:3.18"

              command = ["/bin/sh", "-c"]
              args = [
                <<-EOT
                # Create backup directory
                mkdir -p /backup/monitoring-$(date +%Y%m%d_%H%M%S)
                cd /backup/monitoring-$(date +%Y%m%d_%H%M%S)
                
                # Backup Prometheus data
                echo "Backing up Prometheus data..."
                curl -s http://prometheus:9090/api/v1/query?query=up > prometheus_metrics.json
                
                # Backup Grafana dashboards
                echo "Backing up Grafana dashboards..."
                curl -s -H "Authorization: Bearer YOUR_GRAFANA_API_TOKEN" \
                  http://grafana:3000/api/search?query=% > grafana_dashboards.json
                
                # Backup Alertmanager configuration
                echo "Backing up Alertmanager configuration..."
                cp /etc/alertmanager/alertmanager.yml alertmanager_config.yml
                
                # Create backup archive
                tar -czf ../monitoring-backup-$(date +%Y%m%d_%H%M%S).tar.gz .
                
                echo "Monitoring backup completed successfully"
                EOT
              ]

              volume_mount {
                name       = "backup-storage"
                mount_path = "/backup"
              }

              volume_mount {
                name       = "alertmanager-config"
                mount_path = "/etc/alertmanager"
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
              name = "backup-storage"
              empty_dir {}
            }

            volume {
              name = "alertmanager-config"
              config_map {
                name = kubernetes_config_map.alertmanager_config.metadata[0].name
              }
            }

            restart_policy = "OnFailure"
          }
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

output "alertmanager_service" {
  description = "Alertmanager service name"
  value       = kubernetes_service.alertmanager.metadata[0].name
}

output "mongodb_exporter_service" {
  description = "MongoDB Exporter service name"
  value       = kubernetes_service.mongodb_exporter.metadata[0].name
}

output "prometheus_url" {
  description = "Prometheus URL for internal access"
  value       = "http://${kubernetes_service.prometheus.metadata[0].name}.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:9090"
}

output "grafana_url" {
  description = "Grafana URL for internal access"
  value       = "http://${kubernetes_service.grafana.metadata[0].name}.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:3000"
}

output "alertmanager_url" {
  description = "Alertmanager URL for internal access"
  value       = "http://${kubernetes_service.alertmanager.metadata[0].name}.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:9093"
}

output "mongodb_exporter_url" {
  description = "MongoDB Exporter URL for internal access"
  value       = "http://${kubernetes_service.mongodb_exporter.metadata[0].name}.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:9216"
}

output "monitoring_backup_cronjob" {
  description = "Monitoring backup cronjob name"
  value       = kubernetes_cron_job_v1.monitoring_backup.metadata[0].name
}

# =============================================================================
# MONITORING ENHANCEMENTS
# =============================================================================

# Nginx Ingress Controller (for ingress monitoring)
resource "kubernetes_deployment" "nginx_ingress_controller" {
  count = var.enable_ingress_monitoring ? 1 : 0

  metadata {
    name      = "nginx-ingress-controller"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "ingress-controller" })
  }

  spec {
    replicas = 1

    selector {
      match_labels = merge(local.common_labels, { component = "ingress-controller" })
    }

    template {
      metadata {
        labels = merge(local.common_labels, { component = "ingress-controller" })
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "10254"
        }
      }

      spec {
        container {
          name  = "nginx-ingress-controller"
          image = "k8s.gcr.io/ingress-nginx/controller:v1.8.1"

          args = [
            "/nginx-ingress-controller",
            "--configmap=$(POD_NAMESPACE)/nginx-configuration",
            "--tcp-services-configmap=$(POD_NAMESPACE)/tcp-services",
            "--udp-services-configmap=$(POD_NAMESPACE)/udp-services",
            "--publish-service=$(POD_NAMESPACE)/ingress-nginx-controller",
            "--annotations-prefix=nginx.ingress.kubernetes.io",
            "--enable-metrics=true",
            "--metrics-port=10254"
          ]

          port {
            container_port = 80
            name           = "http"
          }

          port {
            container_port = 443
            name           = "https"
          }

          port {
            container_port = 10254
            name           = "metrics"
          }

          env {
            name  = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name  = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
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

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "10254"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = "10254"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        service_account_name = kubernetes_service_account.ingress_controller[0].metadata[0].name
      }
    }
  }
}

# Nginx Ingress Controller Service Account
resource "kubernetes_service_account" "ingress_controller" {
  count = var.enable_ingress_monitoring ? 1 : 0

  metadata {
    name      = "nginx-ingress-serviceaccount"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "ingress-controller" })
  }
}

# Nginx Ingress Controller Cluster Role
resource "kubernetes_cluster_role" "ingress_controller" {
  count = var.enable_ingress_monitoring ? 1 : 0

  metadata {
    name   = "nginx-ingress-clusterrole-${var.environment}"
    labels = merge(local.common_labels, { component = "ingress-controller" })
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "endpoints", "nodes", "pods", "secrets"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get"]
  }

  rule {
    api_groups = [""]
    resources  = ["services"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingressclasses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses/status"]
    verbs      = ["update"]
  }
}

# Nginx Ingress Controller Cluster Role Binding
resource "kubernetes_cluster_role_binding" "ingress_controller" {
  count = var.enable_ingress_monitoring ? 1 : 0

  metadata {
    name   = "nginx-ingress-clusterrole-binding-${var.environment}"
    labels = merge(local.common_labels, { component = "ingress-controller" })
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.ingress_controller[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ingress_controller[0].metadata[0].name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}

# Nginx Ingress Controller Service
resource "kubernetes_service" "nginx_ingress_controller" {
  count = var.enable_ingress_monitoring ? 1 : 0

  metadata {
    name      = "ingress-nginx-controller"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "ingress-controller" })
  }

  spec {
    selector = merge(local.common_labels, { component = "ingress-controller" })

    port {
      port        = 80
      target_port = "http"
      protocol    = "TCP"
      name        = "http"
    }

    port {
      port        = 443
      target_port = "https"
      protocol    = "TCP"
      name        = "https"
    }

    type = "LoadBalancer"
  }
}

# Nginx Configuration ConfigMap
resource "kubernetes_config_map" "nginx_configuration" {
  count = var.enable_ingress_monitoring ? 1 : 0

  metadata {
    name      = "nginx-configuration"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "ingress-controller" })
  }

  data = {
    "use-forwarded-headers" = "true"
    "proxy-real-ip-cidr"    = "0.0.0.0/0"
    "use-proxy-protocol"    = "false"
  }
}

# =============================================================================
# LOG AGGREGATION ENHANCEMENT
# =============================================================================

# Fluent Bit ConfigMap for log aggregation
resource "kubernetes_config_map" "fluent_bit_config" {
  count = var.enable_log_aggregation ? 1 : 0

  metadata {
    name      = "fluent-bit-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "fluent-bit" })
  }

  data = {
    "fluent-bit.conf" = <<-EOT
      [SERVICE]
          Flush         5
          Log_Level     info
          Daemon        off
          Parsers_File  parsers.conf

      [INPUT]
          Name              tail
          Path              /var/log/containers/*healthcare*.log
          Parser            docker
          Tag               healthcare.*
          Refresh_Interval  5
          Mem_Buf_Limit     5MB
          Skip_Long_Lines   On

      [INPUT]
          Name              tail
          Path              /var/log/containers/*mongodb*.log
          Parser            docker
          Tag               mongodb.*
          Refresh_Interval  5
          Mem_Buf_Limit     5MB
          Skip_Long_Lines   On

      [FILTER]
          Name                kubernetes
          Match               healthcare.*
          Kube_URL           https://kubernetes.default.svc:443
          Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
          Kube_Tag_Prefix     healthcare.var.log.containers.
          Merge_Log           On
          Merge_Log_Key       log_processed
          K8S-Logging.Parser  On
          K8S-Logging.Exclude On

      [FILTER]
          Name                kubernetes
          Match               mongodb.*
          Kube_URL           https://kubernetes.default.svc:443
          Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
          Kube_Tag_Prefix     mongodb.var.log.containers.
          Merge_Log           On
          Merge_Log_Key       log_processed
          K8S-Logging.Parser  On
          K8S-Logging.Exclude On

      [FILTER]
          Name  grep
          Match healthcare.*
          Regex log ^(?!.*DEBUG).*

      [FILTER]
          Name  grep
          Match mongodb.*
          Regex log ^(?!.*DEBUG).*

      [OUTPUT]
          Name  stdout
          Match healthcare.*
          Format json_lines

      [OUTPUT]
          Name  stdout
          Match mongodb.*
          Format json_lines
    EOT

    "parsers.conf" = <<-EOT
      [PARSER]
          Name        docker
          Format      json
          Time_Key    time
          Time_Format %Y-%m-%dT%H:%M:%S.%L%z
          Time_Keep   On

      [PARSER]
          Name        json
          Format      json
          Time_Key    time
          Time_Format %d/%b/%Y:%H:%M:%S %z

      [PARSER]
          Name        logfmt
          Format      logfmt
    EOT
  }
}

# Fluent Bit DaemonSet for log aggregation
resource "kubernetes_daemonset" "fluent_bit" {
  count = var.enable_log_aggregation ? 1 : 0

  metadata {
    name      = "fluent-bit"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "fluent-bit" })
  }

  spec {
    selector {
      match_labels = merge(local.common_labels, { component = "fluent-bit" })
    }

    template {
      metadata {
        labels = merge(local.common_labels, { component = "fluent-bit" })
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "2020"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.fluent_bit[0].metadata[0].name

        container {
          name  = "fluent-bit"
          image = "fluent/fluent-bit:2.1.0"

          args = [
            "/fluent-bit/bin/fluent-bit",
            "-c",
            "/fluent-bit/etc/fluent-bit.conf"
          ]

          port {
            container_port = 2020
            name           = "metrics"
          }

          volume_mount {
            name       = "varlogcontainers"
            mount_path = "/var/log/containers"
            read_only  = true
          }

          volume_mount {
            name       = "varlogpods"
            mount_path = "/var/log/pods"
            read_only  = true
          }

          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }

          volume_mount {
            name       = "fluent-bit-config"
            mount_path = "/fluent-bit/etc"
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

          liveness_probe {
            http_get {
              path = "/api/v1/health"
              port = "metrics"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/api/v1/health"
              port = "metrics"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "varlogcontainers"
          host_path {
            path = "/var/log/containers"
          }
        }

        volume {
          name = "varlogpods"
          host_path {
            path = "/var/log/pods"
          }
        }

        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }

        volume {
          name = "fluent-bit-config"
          config_map {
            name = kubernetes_config_map.fluent_bit_config[0].metadata[0].name
          }
        }

        toleration {
          operator = "Exists"
        }
      }
    }
  }
}

# Fluent Bit Service Account
resource "kubernetes_service_account" "fluent_bit" {
  count = var.enable_log_aggregation ? 1 : 0

  metadata {
    name      = "fluent-bit"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "fluent-bit" })
  }
}

# Fluent Bit Cluster Role
resource "kubernetes_cluster_role" "fluent_bit" {
  count = var.enable_log_aggregation ? 1 : 0

  metadata {
    name   = "fluent-bit-${var.environment}"
    labels = merge(local.common_labels, { component = "fluent-bit" })
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }
}

# Fluent Bit Cluster Role Binding
resource "kubernetes_cluster_role_binding" "fluent_bit" {
  count = var.enable_log_aggregation ? 1 : 0

  metadata {
    name   = "fluent-bit-${var.environment}"
    labels = merge(local.common_labels, { component = "fluent-bit" })
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.fluent_bit[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.fluent_bit[0].metadata[0].name
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}

# =============================================================================
# SYNTHETIC MONITORING ENHANCEMENT
# =============================================================================

# Synthetic Monitoring ConfigMap
resource "kubernetes_config_map" "synthetic_monitoring_config" {
  count = var.enable_synthetic_monitoring ? 1 : 0

  metadata {
    name      = "synthetic-monitoring-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "synthetic-monitoring" })
  }

  data = {
    "synthetic-tests.json" = jsonencode([
      {
        name     = "healthcare-api-health-check"
        url      = "http://healthcare-backend.${var.namespace}-${var.environment}.svc.cluster.local:5001/health"
        method   = "GET"
        interval = "30s"
        timeout  = "10s"
        headers = {
          "User-Agent" = "Synthetic-Monitor/1.0"
        }
        assertions = [
          {
            type     = "status_code"
            operator = "equals"
            value    = "200"
          },
          {
            type     = "response_time"
            operator = "less_than"
            value    = "1000"
          }
        ]
      },
      {
        name     = "healthcare-frontend-availability"
        url      = "http://healthcare-frontend.${var.namespace}-${var.environment}.svc.cluster.local:3001"
        method   = "GET"
        interval = "30s"
        timeout  = "10s"
        headers = {
          "User-Agent" = "Synthetic-Monitor/1.0"
        }
        assertions = [
          {
            type     = "status_code"
            operator = "equals"
            value    = "200"
          }
        ]
      },
      {
        name     = "mongodb-connectivity-check"
        url      = "http://mongodb.${var.namespace}-${var.environment}.svc.cluster.local:27017"
        method   = "GET"
        interval = "60s"
        timeout  = "5s"
        assertions = [
          {
            type     = "response_time"
            operator = "less_than"
            value    = "100"
          }
        ]
      }
    ])
  }
}

# Synthetic Monitoring Deployment
resource "kubernetes_deployment" "synthetic_monitoring" {
  count = var.enable_synthetic_monitoring ? 1 : 0

  metadata {
    name      = "synthetic-monitoring"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "synthetic-monitoring" })
  }

  spec {
    replicas = 1

    selector {
      match_labels = merge(local.common_labels, { component = "synthetic-monitoring" })
    }

    template {
      metadata {
        labels = merge(local.common_labels, { component = "synthetic-monitoring" })
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "8080"
        }
      }

      spec {
        container {
          name  = "synthetic-monitor"
          image = "curlimages/curl:8.1.2"

          command = ["/bin/sh", "-c"]
          args = [
            <<-EOT
            #!/bin/sh
            set -e

            echo "Starting synthetic monitoring..."

            while true; do
              # Read synthetic tests configuration
              if [ -f /etc/synthetic-monitoring/synthetic-tests.json ]; then
                # Run health check synthetic test
                START_TIME=$(date +%s%N)
                if curl -s --max-time 10 -o /dev/null -w "%%{http_code}" \
                  http://healthcare-backend.${var.namespace}-${var.environment}.svc.cluster.local:5001/health > /tmp/health_status; then

                  HTTP_CODE=$(cat /tmp/health_status)
                  END_TIME=$(date +%s%N)
                  RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))  # Convert to milliseconds

                  if [ "$HTTP_CODE" = "200" ]; then
                    echo "synthetic_health_check_success 1" > /tmp/metrics
                    echo "synthetic_health_check_response_time $RESPONSE_TIME" >> /tmp/metrics
                  else
                    echo "synthetic_health_check_success 0" > /tmp/metrics
                    echo "synthetic_health_check_response_time $RESPONSE_TIME" >> /tmp/metrics
                  fi
                else
                  echo "synthetic_health_check_success 0" > /tmp/metrics
                  echo "synthetic_health_check_response_time 0" >> /tmp/metrics
                fi

                # Run frontend availability test
                START_TIME=$(date +%s%N)
                if curl -s --max-time 10 -o /dev/null -w "%%{http_code}" \
                  http://healthcare-frontend.${var.namespace}-${var.environment}.svc.cluster.local:3001 > /tmp/frontend_status; then

                  HTTP_CODE=$(cat /tmp/frontend_status)
                  END_TIME=$(date +%s%N)
                  RESPONSE_TIME=$(( (END_TIME - START_TIME) / 1000000 ))

                  if [ "$HTTP_CODE" = "200" ]; then
                    echo "synthetic_frontend_check_success 1" >> /tmp/metrics
                    echo "synthetic_frontend_check_response_time $RESPONSE_TIME" >> /tmp/metrics
                  else
                    echo "synthetic_frontend_check_success 0" >> /tmp/metrics
                    echo "synthetic_frontend_check_response_time $RESPONSE_TIME" >> /tmp/metrics
                  fi
                else
                  echo "synthetic_frontend_check_success 0" >> /tmp/metrics
                  echo "synthetic_frontend_check_response_time 0" >> /tmp/metrics
                fi
              fi

              # Serve metrics on port 8080
              (
                echo "HTTP/1.1 200 OK"
                echo "Content-Type: text/plain"
                echo ""
                if [ -f /tmp/metrics ]; then
                  cat /tmp/metrics
                else
                  echo "# No metrics available"
                fi
              ) | nc -l -p 8080 -q 1 &

              sleep 30
            done
            EOT
          ]

          port {
            container_port = 8080
            name           = "metrics"
          }

          volume_mount {
            name       = "synthetic-config"
            mount_path = "/etc/synthetic-monitoring"
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
          name = "synthetic-config"
          config_map {
            name = kubernetes_config_map.synthetic_monitoring_config[0].metadata[0].name
          }
        }
      }
    }
  }
}

# Synthetic Monitoring Service
resource "kubernetes_service" "synthetic_monitoring" {
  count = var.enable_synthetic_monitoring ? 1 : 0

  metadata {
    name      = "synthetic-monitoring"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "synthetic-monitoring" })
  }

  spec {
    selector = merge(local.common_labels, { component = "synthetic-monitoring" })

    port {
      port        = 8080
      target_port = "metrics"
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

# =============================================================================
# DISTRIBUTED TRACING ENHANCEMENT
# =============================================================================

# Jaeger ConfigMap
resource "kubernetes_config_map" "jaeger_config" {
  count = var.enable_distributed_tracing ? 1 : 0

  metadata {
    name      = "jaeger-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "jaeger" })
  }

  data = {
    "jaeger.yml" = yamlencode({
      service_name = "healthcare-app"
      disabled     = false
      sampler = {
        type  = "const"
        param = 1
      }
      reporter = {
        log_spans           = true
        local_agent_host_port = "jaeger-agent:6831"
      }
      headers = {
        jaeger_debug_header = "debug-id"
        jaeger_baggage_header = "baggage"
        trace_context_header_name = "traceparent"
      }
      baggage_restrictions = {
        deny_baggage_on_initialization_failure = false
        host_port                              = "jaeger-agent:5778"
        refresh_interval                       = 60000
      }
    })
  }
}

# Jaeger Operator (simplified deployment)
resource "kubernetes_deployment" "jaeger_operator" {
  count = var.enable_distributed_tracing ? 1 : 0

  metadata {
    name      = "jaeger-operator"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "jaeger" })
  }

  spec {
    replicas = 1

    selector {
      match_labels = merge(local.common_labels, { component = "jaeger" })
    }

    template {
      metadata {
        labels = merge(local.common_labels, { component = "jaeger" })
      }

      spec {
        container {
          name  = "jaeger-operator"
          image = "jaegertracing/jaeger-operator:1.42.0"

          args = [
            "start",
            "--config=/etc/jaeger/jaeger.yml"
          ]

          port {
            container_port = 16686
            name           = "query"
          }

          port {
            container_port = 14268
            name           = "collect"
          }

          port {
            container_port = 14250
            name           = "grpc"
          }

          volume_mount {
            name       = "jaeger-config"
            mount_path = "/etc/jaeger"
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

          liveness_probe {
            http_get {
              path = "/"
              port = "query"
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = "query"
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "jaeger-config"
          config_map {
            name = kubernetes_config_map.jaeger_config[0].metadata[0].name
          }
        }
      }
    }
  }
}

# Jaeger Service
resource "kubernetes_service" "jaeger" {
  count = var.enable_distributed_tracing ? 1 : 0

  metadata {
    name      = "jaeger"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "jaeger" })
  }

  spec {
    selector = merge(local.common_labels, { component = "jaeger" })

    port {
      port        = 16686
      target_port = "query"
      protocol    = "TCP"
      name        = "query"
    }

    port {
      port        = 14268
      target_port = "collect"
      protocol    = "TCP"
      name        = "collect"
    }

    port {
      port        = 14250
      target_port = "grpc"
      protocol    = "TCP"
      name        = "grpc"
    }

    type = "ClusterIP"
  }
}

# =============================================================================
# ENHANCED PROMETHEUS RULES FOR NEW MONITORING COMPONENTS
# =============================================================================

# Enhanced Prometheus Rules ConfigMap
resource "kubernetes_config_map" "enhanced_prometheus_rules" {
  metadata {
    name      = "enhanced-prometheus-rules"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "prometheus" })
  }

  data = {
    "enhanced-monitoring.yml" = yamlencode({
      groups = [
        # Existing rules...
        {
          name = "enhanced-monitoring.rules"
          rules = [
            # Ingress monitoring rules
            {
              alert = "IngressDown"
              expr  = "nginx_ingress_controller_requests{status!~\"2..\"} / nginx_ingress_controller_requests * 100 > 5"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "platform"
              }
              annotations = {
                summary     = "High ingress error rate detected"
                description = "Ingress error rate is above 5% for more than 5 minutes"
                runbook     = "https://docs.company.com/runbooks/ingress-errors"
              }
            },
            # Log aggregation rules
            {
              alert = "LogAggregationFailure"
              expr  = "up{job=\"fluent-bit\"} == 0"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "platform"
              }
              annotations = {
                summary     = "Log aggregation failure"
                description = "Fluent Bit log aggregation is down"
                runbook     = "https://docs.company.com/runbooks/log-aggregation"
              }
            },
            # Synthetic monitoring rules
            {
              alert = "SyntheticTestFailure"
              expr  = "synthetic_health_check_success == 0"
              for   = "2m"
              labels = {
                severity = "critical"
                team     = "backend"
              }
              annotations = {
                summary     = "Synthetic health check failed"
                description = "Synthetic monitoring detected service unavailability"
                runbook     = "https://docs.company.com/runbooks/synthetic-failure"
              }
            },
            {
              alert = "HighSyntheticResponseTime"
              expr  = "synthetic_health_check_response_time > 2000"
              for   = "5m"
              labels = {
                severity = "warning"
                team     = "backend"
              }
              annotations = {
                summary     = "High synthetic response time"
                description = "Synthetic monitoring detected slow response times (>2s)"
                runbook     = "https://docs.company.com/runbooks/high-response-time"
              }
            },
            # Distributed tracing rules
            {
              alert = "TracingServiceDown"
              expr  = "up{job=\"jaeger\"} == 0"
              for   = "5m"
              labels = {
                severity = "info"
                team     = "platform"
              }
              annotations = {
                summary     = "Distributed tracing service down"
                description = "Jaeger tracing service is unavailable"
                runbook     = "https://docs.company.com/runbooks/tracing-down"
              }
            }
          ]
        }
      ]
    })
  }
}

# =============================================================================
# ENHANCED GRAFANA DASHBOARDS
# =============================================================================

# Enhanced Grafana Dashboard ConfigMap
resource "kubernetes_config_map" "enhanced_grafana_dashboards" {
  metadata {
    name      = "enhanced-grafana-dashboards"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = merge(local.common_labels, { component = "grafana" })
  }

  data = {
    "enhanced-dashboard.json" = jsonencode({
      dashboard = {
        id       = null
        title    = "Enhanced Healthcare Monitoring Dashboard"
        tags     = ["healthcare", "monitoring", "enhanced"]
        timezone = "browser"
        panels = [
          # Existing panels...
          {
            id    = 1
            title = "CPU Usage"
            type  = "graph"
            targets = [
              {
                expr = "rate(container_cpu_usage_seconds_total{namespace=\"${var.namespace}-${var.environment}\"}[5m]) * 100"
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
          },
          # New enhanced panels
          {
            id    = 3
            title = "Ingress Request Rate"
            type  = "graph"
            targets = [
              {
                expr = "rate(nginx_ingress_controller_requests_total[5m])"
              }
            ]
          },
          {
            id    = 4
            title = "Ingress Error Rate"
            type  = "graph"
            targets = [
              {
                expr = "rate(nginx_ingress_controller_requests_total{status!~\"2..\"}[5m]) / rate(nginx_ingress_controller_requests_total[5m]) * 100"
              }
            ]
          },
          {
            id    = 5
            title = "Synthetic Health Check Status"
            type  = "stat"
            targets = [
              {
                expr = "synthetic_health_check_success"
              }
            ]
          },
          {
            id    = 6
            title = "Synthetic Response Time"
            type  = "graph"
            targets = [
              {
                expr = "synthetic_health_check_response_time"
              }
            ]
          },
          {
            id    = 7
            title = "Log Volume by Service"
            type  = "graph"
            targets = [
              {
                expr = "rate(fluentbit_output_proc_records_total[5m])"
              }
            ]
          },
          {
            id    = 8
            title = "Tracing Spans per Second"
            type  = "graph"
            targets = [
              {
                expr = "rate(jaeger_tracer_reporter_spans_total[5m])"
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

# =============================================================================
# MONITORING INGRESS RESOURCES - Consolidated in ingress.tf
# =============================================================================

output "alertmanager_external_url" {
  description = "External Alertmanager URL"
  value       = var.environment == "production" ? "https://monitoring.company.com/alertmanager" : "http://monitoring-staging.local/alertmanager"
}

output "prometheus_external_url" {
  description = "External Prometheus URL"
  value       = var.environment == "production" ? "https://monitoring.company.com/prometheus" : "http://monitoring-staging.local/prometheus"
}

output "mongodb_exporter_external_url" {
  description = "External MongoDB Exporter URL"
  value       = var.environment == "production" ? "https://monitoring.company.com/mongodb-exporter" : "http://monitoring-staging.local/mongodb-exporter"
}

# =============================================================================
# ENHANCEMENT OUTPUTS
# =============================================================================

output "nginx_ingress_controller_service" {
  description = "Nginx Ingress Controller service name"
  value       = var.enable_ingress_monitoring ? kubernetes_service.nginx_ingress_controller[0].metadata[0].name : null
}

output "fluent_bit_daemonset" {
  description = "Fluent Bit DaemonSet name"
  value       = var.enable_log_aggregation ? kubernetes_daemonset.fluent_bit[0].metadata[0].name : null
}

output "synthetic_monitoring_service" {
  description = "Synthetic monitoring service name"
  value       = var.enable_synthetic_monitoring ? kubernetes_service.synthetic_monitoring[0].metadata[0].name : null
}

output "jaeger_service" {
  description = "Jaeger tracing service name"
  value       = var.enable_distributed_tracing ? kubernetes_service.jaeger[0].metadata[0].name : null
}

output "enhanced_monitoring_features" {
  description = "Status of enhanced monitoring features"
  value = {
    ingress_monitoring     = var.enable_ingress_monitoring
    log_aggregation        = var.enable_log_aggregation
    synthetic_monitoring   = var.enable_synthetic_monitoring
    distributed_tracing    = var.enable_distributed_tracing
  }
}
