# Terraform Providers Configuration
# Configures providers for Kubernetes, Helm, and other infrastructure components

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
  required_version = ">= 1.0"
}

# Kubernetes Provider Configuration
# Uses kubeconfig for cluster authentication
provider "kubernetes" {
  # Use the default kubeconfig location or KUBECONFIG environment variable
  config_path = var.kubeconfig_path != "" ? var.kubeconfig_path : null

  # Alternative: Use explicit cluster configuration (uncomment if needed)
  # host                   = var.kubernetes_host
  # cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca_certificate)
  # client_certificate     = base64decode(var.kubernetes_client_certificate)
  # client_key             = base64decode(var.kubernetes_client_key)

  # Load balancer configuration for production
  load_config_file = true

  # Timeout settings
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubectl"
    args        = ["config", "current-context"]
  }
}

# Helm Provider Configuration
# Uses the same Kubernetes configuration as the kubernetes provider
provider "helm" {
  kubernetes {
    # Use the default kubeconfig location or KUBECONFIG environment variable
    config_path = var.kubeconfig_path != "" ? var.kubeconfig_path : null

    # Alternative: Use explicit cluster configuration (uncomment if needed)
    # host                   = var.kubernetes_host
    # cluster_ca_certificate = base64decode(var.kubernetes_cluster_ca_certificate)
    # client_certificate     = base64decode(var.kubernetes_client_certificate)
    # client_key             = base64decode(var.kubernetes_client_key)

    load_config_file = true

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubectl"
      args        = ["config", "current-context"]
    }
  }
}

# Random Provider (no configuration needed)
provider "random" {
  # No configuration required
}
