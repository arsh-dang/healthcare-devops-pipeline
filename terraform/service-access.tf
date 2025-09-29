# Service Access Management
# This file provides automated service access through Terraform

# Local values for service access
# Port mapping:
# - Frontend: Local 8082 → Container 80 (nginx) → React dev runs on 3001
# - Backend: Local 8083 → Container 5001 (Node.js)
# - Grafana: Local 3000 → Container 3000
# - Prometheus: Local 9090 → Container 9090  
# - Jaeger: Local 16686 → Container 16686
locals {
  service_access_config = {
    frontend_port = 8082    # Local port for frontend (container runs on 80, dev on 3001)
    backend_port = 8083     # Local port for backend (container runs on 5001)
    grafana_port = 3000     # Local port for Grafana (container runs on 3000)
    prometheus_port = 9090  # Local port for Prometheus (container runs on 9090)
    jaeger_port = 16686     # Local port for Jaeger (container runs on 16686)
    namespace = var.environment == "production" ? "healthcare-production" : "healthcare-staging"
    monitoring_namespace = "monitoring-${var.environment}"
  }
}

# Null resource to manage service access script
resource "null_resource" "service_access_setup" {
  count = var.enable_service_access ? 1 : 0
  
  triggers = {
    # Trigger when any service changes
    frontend_image = var.frontend_image
    backend_image = var.backend_image
    environment = var.environment
    namespace = local.service_access_config.namespace
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Make the access script executable
      chmod +x ${path.module}/access-services.sh
      
      # Set up service access
      ${path.module}/access-services.sh setup
    EOT
    
    working_dir = path.module
  }

  # Cleanup on destroy
  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      ${path.module}/access-services.sh stop
    EOT
    
    working_dir = path.module
  }

  depends_on = [
    kubernetes_deployment.frontend,
    kubernetes_stateful_set.mongodb
  ]
}

# Output service access information
output "service_access_info" {
  description = "Information for accessing the Healthcare App services"
  value = {
    frontend_url = "http://localhost:${local.service_access_config.frontend_port}"
    backend_url = "http://localhost:${local.service_access_config.backend_port}/api/"
    health_check_url = "http://localhost:${local.service_access_config.backend_port}/api/health"
    
    monitoring = {
      grafana_url = "http://localhost:${local.service_access_config.grafana_port}"
      prometheus_url = "http://localhost:${local.service_access_config.prometheus_port}"
      jaeger_url = "http://localhost:${local.service_access_config.jaeger_port}"
    }
    
    management_commands = {
      setup_access = "${path.module}/access-services.sh setup"
      stop_access = "${path.module}/access-services.sh stop"
      check_status = "${path.module}/access-services.sh status"
      restart_access = "${path.module}/access-services.sh restart"
    }
    
    namespace = local.service_access_config.namespace
    monitoring_namespace = local.service_access_config.monitoring_namespace
  }
}

# Output for easy access in terminal
output "quick_access" {
  description = "Quick access commands for the Healthcare App"
  value = <<-EOT
    
    🚀 Healthcare App Service Access
    ================================
    
    📱 Main Application:
       Frontend: http://localhost:${local.service_access_config.frontend_port}
         (Container: nginx on port 80, Dev: React on port 3001)
       Backend API: http://localhost:${local.service_access_config.backend_port}/api/
         (Container: Node.js on port 5001)
       Health Check: http://localhost:${local.service_access_config.backend_port}/api/health
    
    📊 Monitoring Dashboards:
       Grafana: http://localhost:${local.service_access_config.grafana_port}
       Prometheus: http://localhost:${local.service_access_config.prometheus_port}
       Jaeger: http://localhost:${local.service_access_config.jaeger_port}
    
    🔧 Management Commands:
       Setup: ${path.module}/access-services.sh setup
       Stop: ${path.module}/access-services.sh stop
       Status: ${path.module}/access-services.sh status
       Restart: ${path.module}/access-services.sh restart
    
    📋 Kubernetes Commands:
       View pods: kubectl get pods -n ${local.service_access_config.namespace}
       View logs: kubectl logs -n ${local.service_access_config.namespace} -l app=healthcare-app
       Restart: kubectl rollout restart -n ${local.service_access_config.namespace} deployment/frontend
    
  EOT
}
