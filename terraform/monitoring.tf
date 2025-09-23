# Monitoring Infrastructure with Terraform
# This file manages Prometheus, Grafana, Alertmanager, MongoDB Exporter, and monitoring resources

# Monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  count = 1

  metadata {
    name = "monitoring-${var.environment}"
    labels = {
      app         = "healthcare-app"
      environment = var.environment
      managed-by  = "terraform"
      component   = "monitoring"
      purpose     = "observability"
    }
  }

  lifecycle {
    ignore_changes = [metadata[0].labels]
  }
}

# Test output
output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring[0].metadata[0].name
}

# Alertmanager ConfigMap
resource "kubernetes_config_map" "alertmanager_config" {
  depends_on = [kubernetes_namespace.monitoring]

  metadata {
    name      = "alertmanager-config"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    labels = {
      app         = "healthcare-app"
      environment = var.environment
      managed-by  = "terraform"
      component   = "alertmanager"
    }
  }

  data = {
    "alertmanager.yml" = yamlencode({
      global = {
        smtp_smarthost = "smtp.example.com:587"
      }
      route = {
        receiver = "default"
      }
      receivers = [
        {
          name = "default"
        }
      ]
    })
  }
}

# Prometheus ConfigMap
resource "kubernetes_config_map" "prometheus_config" {
  depends_on = [kubernetes_namespace.monitoring]

  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    labels = {
      app         = "healthcare-app"
      environment = var.environment
      managed-by  = "terraform"
      component   = "prometheus"
    }
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
