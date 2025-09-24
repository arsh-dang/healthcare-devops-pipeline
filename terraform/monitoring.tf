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

# Test output
output "monitoring_namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}
