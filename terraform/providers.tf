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
  # Use the default kubeconfig location (~/.kube/config or KUBECONFIG env var)
  # config_path is automatically detected if not specified
}

# Helm Provider Configuration
# Uses the same Kubernetes configuration as the kubernetes provider
provider "helm" {
  # Use the default kubeconfig location (~/.kube/config or KUBECONFIG env var)
  # config_path is automatically detected if not specified
}

# Random Provider (no configuration needed)
provider "random" {
  # No configuration required
}
