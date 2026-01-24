#!/usr/bin/env bash
# ==============================================================================
# default_dev.sh - Persistent Nix Development Shell for CoMMpass Analysis
# ==============================================================================
# This script creates and enters a Nix shell with persistent GC root
# to prevent garbage collection and speed up subsequent runs
# ==============================================================================

set -euo pipefail

# Configuration
NIX_FILE="default_dev.nix"
GC_ROOT_NAME="nix-shell-root-commpass"
GC_ROOT_PATH="./$GC_ROOT_NAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
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

# Header
echo "=============================================="
echo "🔬 CoMMpass Analysis Nix Development Shell"
echo "=============================================="

# Check if Nix file exists
if [ ! -f "$NIX_FILE" ]; then
    print_error "$NIX_FILE not found!"
    print_info "Run 'Rscript default_dev.R' first to generate it."
    exit 1
fi

# Check if we're already in a Nix shell
if [ -n "${IN_NIX_SHELL:-}" ]; then
    print_warning "Already in a Nix shell. Exiting current shell first..."
    exit 1
fi

# Build or update the environment
print_info "Building Nix environment from $NIX_FILE..."
echo ""

# Create or update GC root
if [ ! -e "$GC_ROOT_PATH" ]; then
    print_info "First run detected - creating persistent GC root..."
    print_warning "This will take 10-20 minutes to download all packages..."
    echo ""

    # Build and create GC root
    nix-build "$NIX_FILE" -o "$GC_ROOT_PATH" --show-trace 2>&1 | while IFS= read -r line; do
        # Filter verbose output but show important messages
        if [[ "$line" =~ downloading|building|unpacking|error|warning ]]; then
            echo "$line"
        elif [[ "$line" =~ "%" ]]; then
            # Show progress
            echo -ne "\r$line"
        fi
    done

    echo ""
    print_success "GC root created at $GC_ROOT_PATH"
    print_info "Future runs will be much faster (~5 seconds)"
else
    print_info "Using existing GC root at $GC_ROOT_PATH"
    print_info "Checking for updates..."

    # Quick rebuild to check for changes
    if nix-build "$NIX_FILE" -o "$GC_ROOT_PATH.tmp" --dry-run 2>&1 | grep -q "will be built"; then
        print_warning "Updates detected - rebuilding environment..."
        nix-build "$NIX_FILE" -o "$GC_ROOT_PATH.tmp" --show-trace
        mv "$GC_ROOT_PATH.tmp" "$GC_ROOT_PATH"
        print_success "Environment updated successfully"
    else
        print_success "Environment is up to date"
    fi
fi

echo ""
echo "=============================================="
echo "📊 Package Inventory:"
echo "- 57 CRAN packages"
echo "- 27 Bioconductor packages"
echo "- 10 system dependencies"
echo "=============================================="
echo ""

# Enter the shell
print_success "Entering Nix shell..."
echo ""
echo "🚀 Ready for CoMMpass analysis!"
echo "Type 'exit' to leave the Nix environment"
echo "=============================================="

# Use the GC root to enter the shell quickly
exec nix-shell "$GC_ROOT_PATH" --command "export PS1='[nix-commpass] \$ '; return"
