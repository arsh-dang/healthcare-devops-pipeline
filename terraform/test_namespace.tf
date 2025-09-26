# Test file for namespace parsing
locals {
  common_labels = {
    app         = "healthcare-app"
    environment = "staging"
    managed-by  = "terraform"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring-staging"
    labels = merge(local.common_labels, {
      component = "monitoring"
      purpose   = "observability"
    })
  }
}

resource "kubernetes_config_map" "test" {
  depends_on = [kubernetes_namespace.monitoring]

  metadata {
    name      = "test-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "test" = "value"
  }
}