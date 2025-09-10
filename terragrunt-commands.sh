#!/bin/bash
# Terragrunt Commands Helper Script
# This script provides common Terragrunt commands for the Healthcare DevOps project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if terragrunt is installed
check_terragrunt() {
    if ! command -v terragrunt &> /dev/null; then
        print_error "Terragrunt is not installed. Please install it first:"
        echo "  brew install terragrunt  # macOS with Homebrew"
        echo "  # or download from: https://terragrunt.gruntwork.io/docs/getting-started/install/"
        exit 1
    fi
}

# Navigate to terraform directory
cd_to_terraform() {
    if [ ! -d "terraform" ]; then
        print_error "terraform directory not found"
        exit 1
    fi
    cd terraform
}

# Main commands
case "${1:-help}" in
    "plan")
        check_terragrunt
        cd_to_terraform
        print_info "Running terragrunt plan..."
        terragrunt plan
        ;;

    "apply")
        check_terragrunt
        cd_to_terraform
        print_warning "This will apply changes to your infrastructure. Continue? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            print_info "Running terragrunt apply..."
            terragrunt apply
            print_success "Apply completed!"
        else
            print_info "Apply cancelled."
        fi
        ;;

    "destroy")
        check_terragrunt
        cd_to_terraform
        print_warning "This will DESTROY your infrastructure. Are you sure? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            print_info "Running terragrunt destroy..."
            terragrunt destroy
            print_success "Destroy completed!"
        else
            print_info "Destroy cancelled."
        fi
        ;;

    "validate")
        check_terragrunt
        cd_to_terraform
        print_info "Running terragrunt validate..."
        terragrunt validate
        print_success "Validation completed!"
        ;;

    "fmt")
        check_terragrunt
        cd_to_terraform
        print_info "Running terragrunt fmt..."
        terragrunt fmt --recursive
        print_success "Formatting completed!"
        ;;

    "init")
        check_terragrunt
        cd_to_terraform
        print_info "Running terragrunt init..."
        terragrunt init
        print_success "Init completed!"
        ;;

    "output")
        check_terragrunt
        cd_to_terraform
        print_info "Running terragrunt output..."
        terragrunt output
        ;;

    "state")
        check_terragrunt
        cd_to_terraform
        if [ -z "$2" ]; then
            print_error "Please specify a state subcommand (list, show, etc.)"
            exit 1
        fi
        print_info "Running terragrunt state $2..."
        terragrunt state "$2" "${@:3}"
        ;;

    "clean")
        print_info "Cleaning Terragrunt cache..."
        find . -name ".terragrunt-cache" -type d -exec rm -rf {} + 2>/dev/null || true
        print_success "Cache cleaned!"
        ;;

    "help"|*)
        echo "Terragrunt Commands Helper for Healthcare DevOps"
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  plan          Show what changes will be made"
        echo "  apply         Apply the changes"
        echo "  destroy       Destroy all resources"
        echo "  validate      Validate the configuration"
        echo "  fmt           Format the Terraform files"
        echo "  init          Initialize Terragrunt"
        echo "  output        Show outputs"
        echo "  state <cmd>   Run terraform state commands"
        echo "  clean         Clean Terragrunt cache"
        echo "  help          Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 plan"
        echo "  $0 apply"
        echo "  $0 state list"
        echo "  $0 clean"
        ;;
esac
