resource "kubernetes_config_map" "integration_test" {
  metadata {
    name      = "integration-test"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
  }

  data = {
    "test-integration.js" = file("${path.module}/../test-integration.js")
  }
}

# Integration Test Job
resource "kubernetes_job" "integration_test" {
  wait_for_completion = false  # Don't wait for completion to avoid pipeline blocking
  
  metadata {
    name      = "integration-test"
    namespace = kubernetes_namespace.healthcare.metadata[0].name
    labels    = local.common_labels
  }

  spec {
    template {
      metadata {
        labels = local.common_labels
      }

      spec {
        container {
          name              = "integration-test"
          image             = var.backend_image
          image_pull_policy = "IfNotPresent"
          working_dir       = "/app"

          env {
            name  = "NODE_PATH"
            value = "/app/node_modules"
          }

          command = ["sh", "-c", "cp /test/test-integration.js /tmp/test-integration.js && node /tmp/test-integration.js"]

          volume_mount {
            name       = "test-script"
            mount_path = "/test"
          }
        }

        volume {
          name = "test-script"
          config_map {
            name = kubernetes_config_map.integration_test.metadata[0].name
          }
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 1
  }
}
