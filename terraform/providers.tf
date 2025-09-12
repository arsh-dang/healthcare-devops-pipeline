# Terraform Providers Configuration
# This file defines the providers used in the infrastructure

terraform {
  required_version = ">= 1.0"

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
}

# Kubernetes Provider
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Helm Provider
provider "helm" {
  # Kubernetes configuration will be inherited from environment
}

# Random Provider
provider "random" {
  # No configuration needed
}