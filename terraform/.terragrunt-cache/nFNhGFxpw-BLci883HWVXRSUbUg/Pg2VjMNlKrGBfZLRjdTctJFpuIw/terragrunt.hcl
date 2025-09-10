# Terragrunt configuration for Healthcare DevOps Infrastructure
# This file provides common configurations and remote state management

# Include all settings from the root terragrunt.hcl file (if present)
include "root" {
  path = find_in_parent_folders()
}

# Configure remote state
remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/terraform.tfstate"
  }
}

# Configure Terraform source
terraform {
  source = "."
}

# Generate backend configuration
generate "backend" {
  path = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "local" {}
}
EOF
}

# Generate provider configurations
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

# Configure the Kubernetes Provider
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "colima"
}

# Configure the Helm Provider
provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "colima"
  }
}
EOF
}

# Common inputs that will be passed to all modules
inputs = {
  # Environment configuration
  environment = "staging"

  # Application configuration
  app_version = "latest"
  namespace = "healthcare"

  # Docker images
  frontend_image = "healthcare-app-frontend:latest"
  backend_image = "healthcare-app-backend:latest"

  # Replica counts
  replica_count = {
    frontend = 2
    backend  = 3
  }

  # Monitoring configuration
  enable_monitoring = true
  enable_datadog = false
  datadog_api_key = ""

  # MongoDB configuration
  mongodb_root_password = ""

  # Resource limits
  resource_limits = {
    frontend = {
      cpu_request    = "100m"
      memory_request = "128Mi"
      cpu_limit      = "500m"
      memory_limit   = "512Mi"
    }
    backend = {
      cpu_request    = "200m"
      memory_request = "256Mi"
      cpu_limit      = "1000m"
      memory_limit   = "1Gi"
    }
    mongodb = {
      cpu_request    = "500m"
      memory_request = "1Gi"
      cpu_limit      = "2000m"
      memory_limit   = "4Gi"
    }
  }

  # Storage configuration
  enable_persistent_storage = true
  monitoring_retention_days = 15
}

# Retry configuration for transient errors
retryable_errors = [
  "(?s).*Error installing provider.*",
  "(?s).*Error initializing.*",
  "(?s).*timeout while waiting for state.*",
]

# Maximum number of retries
retry_max_attempts = 3

# Sleep between retries
retry_sleep_interval_sec = 5
