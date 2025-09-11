# Terragrunt Setup for Healthcare DevOps

This project now uses Terragrunt to simplify Terraform management and provide## Remote State

Currently configured to use **local backend** for development:
- State file stored at: `terraform.tfstate`
- Perfect for local development and testing
- No cloud costs or setup required

### When to Use S3 Backend

For production environments or team collaboration, consider S3 (or GCS/Azure) backend:
- **Team collaboration**: Multiple developers can work together
- **Backup**: State is safely stored in the cloud
- **Locking**: Prevents concurrent modifications
- **Versioning**: Track state file changes over time

Example S3 configuration (when needed):
```hcl
remote_state {
  backend = "s3"
  config = {
    bucket = "your-terraform-state-bucket"
    key    = "healthcare-app/${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}
```cture as code practices.

## What is Terragrunt?

Terragrunt is a thin wrapper for Terraform that provides extra tools for:
- Keeping configurations DRY (Don't Repeat Yourself)
- Managing remote state
- Working with multiple modules
- Automatic provider and backend configuration

## Directory Structure

```
healthcare-app/
├── terragrunt.hcl          # Root configuration
├── terragrunt-commands.sh  # Helper script for common commands
└── terraform/
    ├── terragrunt.hcl      # Environment-specific configuration
    └── main.tf             # Your Terraform infrastructure code
```

## Quick Start

### 1. Install Terragrunt

```bash
# macOS with Homebrew
brew install terragrunt

# Or download from: https://terragrunt.gruntwork.io/docs/getting-started/install/
```

### 2. Use the Helper Script

The easiest way to use Terragrunt is through the provided helper script:

```bash
# Plan changes
./terragrunt-commands.sh plan

# Apply changes
./terragrunt-commands.sh apply

# Destroy infrastructure
./terragrunt-commands.sh destroy

# Validate configuration
./terragrunt-commands.sh validate

# Format files
./terragrunt-commands.sh fmt
```

### 3. Manual Commands

You can also run Terragrunt commands directly:

```bash
cd terraform

# Initialize (only needed first time)
terragrunt init

# Plan changes
terragrunt plan

# Apply changes
terragrunt apply

# Show outputs
terragrunt output

# Destroy everything
terragrunt destroy
```

## Benefits of Using Terragrunt

### 1. **Simplified Commands**
Instead of remembering complex Terraform commands, use simple ones:
- `terragrunt plan` instead of `terraform plan`
- `terragrunt apply` instead of `terraform apply`

### 2. **Automatic Provider Configuration**
Terragrunt automatically generates provider configurations, so you don't need to maintain them in your Terraform code.

### 3. **Remote State Management**
Built-in remote state configuration with local backend for development.

### 4. **DRY Configuration**
Common variables and settings are defined once and reused across environments.

### 5. **Better Error Handling**
Automatic retries for transient errors and better error messages.

## Configuration Files

### Root `terragrunt.hcl`
Contains global configurations that apply to all environments:
- Remote state backend configuration
- Common tags and inputs

### Environment `terraform/terragrunt.hcl`
Contains environment-specific configurations:
- Terraform source location
- Environment-specific inputs
- Provider configurations

## Environment Management

To add a new environment (e.g., production):

1. Create a new directory: `mkdir terraform-prod`
2. Copy `terraform/terragrunt.hcl` to `terraform-prod/`
3. Modify the inputs in the new `terragrunt.hcl` for production settings
4. Update the backend configuration for production (consider using S3)

## Remote State

Currently configured to use local backend for development. For production:

1. Update the backend in `terragrunt.hcl`:
```hcl
remote_state {
  backend = "s3"
  config = {
    bucket = "your-terraform-state-bucket"
    key    = "healthcare-app/${path_relative_to_include()}/terraform.tfstate"
    region = "us-east-1"
  }
}
```

2. Create the S3 bucket and DynamoDB table for state locking.

## Troubleshooting

### Common Issues

1. **"terragrunt: command not found"**
   - Install Terragrunt using the instructions above

2. **Provider version conflicts**
   - Terragrunt generates provider configurations automatically
   - Remove any manual provider blocks from your Terraform code

3. **State file issues**
   - Use `terragrunt force-unlock LOCK_ID` if state is locked
   - Check the state file location in the backend configuration

### Getting Help

- Terragrunt Documentation: https://terragrunt.gruntwork.io/
- Terraform Documentation: https://www.terraform.io/docs
- Use `./terragrunt-commands.sh help` for available commands

## Migration from Pure Terraform

Your existing Terraform code works unchanged with Terragrunt. The main changes:
- Removed `terraform {}` and `provider {}` blocks from `main.tf`
- Added `terragrunt.hcl` files for configuration
- Use `terragrunt` instead of `terraform` commands

## Next Steps

1. Test the setup with `./terragrunt-commands.sh plan`
2. Apply changes with `./terragrunt-commands.sh apply`
3. Consider setting up CI/CD to use Terragrunt commands
4. Add more environments as needed

Happy Infrastructuring!
