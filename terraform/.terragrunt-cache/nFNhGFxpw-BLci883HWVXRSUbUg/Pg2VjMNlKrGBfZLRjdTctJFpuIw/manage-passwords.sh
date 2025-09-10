#!/bin/bash
# Password Management Helper Script
# Usage: ./manage-passwords.sh [generate|show|rotate]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

generate_password() {
    local length=${1:-32}
    # Generate a secure password with mixed characters
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-$length
}

show_current_password() {
    log_info "Showing current MongoDB password from Terraform state..."
    cd "$TERRAFORM_DIR"
    
    if [ ! -f ".terraform/terraform.tfstate" ]; then
        log_error "Terraform state not found. Run 'terraform init && terraform apply' first."
        exit 1
    fi
    
    # Extract password from state (this is a simplified approach)
    terraform output -json mongodb_password 2>/dev/null || {
        log_error "Could not retrieve password from Terraform output"
        log_info "Try running: terraform output mongodb_password"
        exit 1
    }
}

rotate_password() {
    log_warn "Password rotation requires careful planning!"
    log_info "Steps to rotate MongoDB password:"
    echo "1. Generate new password"
    echo "2. Update terraform.tfvars with new password"
    echo "3. Run: terraform apply"
    echo "4. Update any external systems using the old password"
    echo "5. Verify application connectivity"
    echo ""
    
    read -p "Do you want to generate a new password? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        NEW_PASSWORD=$(generate_password)
        log_info "Generated new password: $NEW_PASSWORD"
        log_warn "Save this password securely before proceeding!"
        echo ""
        log_info "Add to terraform.tfvars:"
        echo "mongodb_root_password = \"$NEW_PASSWORD\""
    fi
}

case "${1:-help}" in
    "generate")
        log_info "Generating secure password..."
        generate_password "${2:-32}"
        ;;
    "show")
        show_current_password
        ;;
    "rotate")
        rotate_password
        ;;
    "help"|*)
        echo "Password Management Helper"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  generate [length]  Generate a new secure password (default: 32 chars)"
        echo "  show               Show current password from Terraform state"
        echo "  rotate             Guide through password rotation process"
        echo "  help               Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 generate        # Generate 32-char password"
        echo "  $0 generate 64     # Generate 64-char password"
        echo "  $0 show            # Show current password"
        echo "  $0 rotate          # Start password rotation"
        ;;
esac
