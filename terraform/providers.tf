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
  config_path = "~/.kube/config"
}

# Helm Provider Configuration
# Uses the same Kubernetes configuration as the kubernetes provider
provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

# Random Provider (no configuration needed)
provider "random" {
  # No configuration required
}
