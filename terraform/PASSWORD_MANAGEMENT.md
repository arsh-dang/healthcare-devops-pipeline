# Password Management for HD-grade Deployments

## Overview
This Terraform configuration supports multiple approaches to MongoDB password management, suitable for different deployment scenarios.

## Approaches

### 1. Variable-based Password (Recommended for Production)
```hcl
# In terraform.tfvars
mongodb_root_password = "YourSecurePassword123!"
```

**Pros:**
- Predictable and manageable
- Easy to share with team members
- Consistent across deployments
- Can be stored in secure credential management systems

**Cons:**
- Requires manual password management
- Password visible in state files (use `.tfvars` files outside version control)

### 2. Auto-generated Password (Development/Staging)
```hcl
# Leave variable empty for auto-generation
mongodb_root_password = ""
```

**Pros:**
- No manual password management
- Different passwords per environment
- Terraform-native approach

**Cons:**
- Non-deterministic (changes on each run)
- Harder to recover if lost
- May cause connectivity issues if password changes unexpectedly

## HD-grade Recommendations

### For Production Environments:
1. **Use variable-based passwords** with secure storage
2. **Store tfvars files** outside version control (e.g., in secure storage)
3. **Use environment-specific passwords** for isolation
4. **Implement password rotation** policies
5. **Consider external secret management** (AWS Secrets Manager, HashiCorp Vault)

### Security Best Practices:
- Use strong passwords (12+ characters, mixed case, numbers, symbols)
- Rotate passwords regularly
- Store credentials securely (not in Git)
- Use different passwords per environment
- Implement least-privilege access

### Deployment Examples:

#### Development:
```bash
terraform apply
# Uses auto-generated password
```

#### Staging:
```bash
export TF_VAR_mongodb_root_password="StagingSecurePass123!"
terraform apply
```

#### Production:
```bash
# Use .tfvars file
terraform apply -var-file=production.tfvars
```

## Migration Guide

### From Random to Variable-based:
1. Set `mongodb_root_password` variable in your `.tfvars` file
2. Run `terraform plan` to see changes
3. Apply with `terraform apply`
4. Update application configurations with new password
5. Remove old random password from state if needed

### State Management:
- Random passwords are stored in Terraform state
- Variable-based passwords are not stored in state (only reference)
- Consider state encryption for sensitive data
