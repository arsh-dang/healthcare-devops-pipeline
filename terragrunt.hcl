# Root Terragrunt configuration
# This file contains common configurations that can be shared across all environments

# Remote state configuration - currently using local backend for development
remote_state {
  backend = "local"
  config = {
    path = "${get_parent_terragrunt_dir()}/terraform.tfstate"
  }
}

# Global inputs that apply to all environments
inputs = {
  # Common tags
  common_tags = {
    Project     = "Healthcare App"
    Environment = "staging"
    ManagedBy   = "Terragrunt"
    Owner       = "DevOps Team"
  }
}
