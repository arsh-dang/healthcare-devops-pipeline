resource "kubernetes_namespace" "monitoring" {
  count = var.enable_monitoring ? 1 : 0

  metadata {
    name = "monitoring-${var.environment}"
    labels = merge(local.common_labels, {
      component = "monitoring"
      purpose   = "observability"
    })
  }
}

resource "kubernetes_config_map" "test_heredoc" {
  count = var.enable_monitoring ? 1 : 0

  depends_on = [kubernetes_namespace.monitoring]

  metadata {
    name      = "test-heredoc"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "test.yml" = <<-EOT
      test: value
      nested:
        key: value
      EOT
  }
}
