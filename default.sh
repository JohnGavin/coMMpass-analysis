#!/bin/bash
# =============================================================================
# CoMMpass Analysis - Nix Environment Setup Script
# =============================================================================
#
# PURPOSE: Builds and activates a reproducible Nix environment for
# CoMMpass (MMRF Multiple Myeloma) data analysis with:
# - Persistent garbage collection (GC) root to prevent package deletion
# - AWS S3 access for CoMMpass open data
# - Bioconductor packages for genomics analysis
#
# USAGE:
#   chmod +x default.sh
#   ./default.sh
#
# Or with caffeinate to prevent sleep during long builds:
#   caffeinate -i ./default.sh
#
# =============================================================================

set -e  # Exit on error

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_PATH="$SCRIPT_DIR"
GC_ROOT_PATH="$PROJECT_PATH/nix-shell-root"
NIX_FILE="$PROJECT_PATH/default.nix"
R_FILE="$PROJECT_PATH/default.R"

echo "=== CoMMpass Analysis Nix Environment Setup ==="
echo "Project path: $PROJECT_PATH"

# Normalize HOME to avoid literal $HOME paths
sanitize_home() {
    local invalid_home=0
    if [ -z "$HOME" ]; then
        invalid_home=1
    else
        case "$HOME" in
            *'$'*) invalid_home=1 ;;
            /*) ;;
            *) invalid_home=1 ;;
        esac
    fi

    if [ "$invalid_home" -ne 0 ] && [ -n "$USER" ] && [ -d "/Users/$USER" ]; then
        export HOME="/Users/$USER"
    fi
}

sanitize_home

# Export environment variables BEFORE any Nix operations
export NIXPKGS_ALLOW_BROKEN=1
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
export NIXPKGS_ALLOW_UNFREE=1
export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/cert.pem}"
export CURL_CA_BUNDLE="${CURL_CA_BUNDLE:-/etc/ssl/cert.pem}"

echo -e "\n=== STEP 1: Generate default.nix from default.R (if needed) ==="

# Determine if default.nix needs regeneration
NEED_REGEN=false

# Check 1: default.nix doesn't exist
if [ ! -f "$NIX_FILE" ]; then
    echo "default.nix does not exist."
    NEED_REGEN=true
# Check 2: default.nix exists but is empty
elif [ ! -s "$NIX_FILE" ]; then
    echo "default.nix exists but is empty."
    NEED_REGEN=true
# Check 3: default.R is newer than default.nix
elif [ "$R_FILE" -nt "$NIX_FILE" ]; then
    echo "default.R has been modified since default.nix was generated."
    NEED_REGEN=true
# Check 4: packages.R is newer than default.nix
elif [ "$PROJECT_PATH/R/dev/nix/packages.R" -nt "$NIX_FILE" ]; then
    echo "packages.R has been modified since default.nix was generated."
    NEED_REGEN=true
# Check 5: default.nix has invalid Nix syntax
elif ! nix-instantiate --parse "$NIX_FILE" > /dev/null 2>&1; then
    echo "default.nix has invalid Nix syntax."
    NEED_REGEN=true
else
    echo "default.nix is up to date."
fi

if [ "$NEED_REGEN" = true ]; then
    echo "Regenerating default.nix from default.R..."
    nix-shell \
        --pure \
        --keep PATH \
        --keep TMPDIR \
        --keep GITHUB_PAT \
        --keep SSL_CERT_FILE \
        --keep CURL_CA_BUNDLE \
        --keep NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM \
        --expr "$(curl -sl https://raw.githubusercontent.com/b-rodrigues/rix/master/inst/extdata/default.nix)" \
        --command "cd \"$PROJECT_PATH\" && \
            Rscript \
            --vanilla \
            \"$R_FILE\"" \
        --cores 4 \
        --quiet

    # Verify regeneration succeeded
    if [ ! -s "$NIX_FILE" ]; then
        echo "ERROR: default.nix regeneration failed (file is empty or missing)."
        exit 1
    fi
    echo "Successfully generated default.nix"
fi

echo -e "\n=== STEP 2: Build shell and create persistent GC root ==="

# Use cachix for faster builds if available
if command -v cachix &> /dev/null; then
    echo "Using cachix for rstats-on-nix..."
    cachix use rstats-on-nix 2>/dev/null || true
fi

echo "Starting nix-build '$NIX_FILE' ..."
echo "This may take a while for first build (Bioconductor packages)..."

time nix-build "$NIX_FILE" \
    -A shell \
    -o "$GC_ROOT_PATH" \
    --cores 8 \
    --quiet

if [ $? -ne 0 ]; then
    echo "ERROR: nix-build failed."
    exit 1
fi

if [ ! -L "$GC_ROOT_PATH" ]; then
    echo "ERROR: Failed to build the Nix shell or create GC root at $GC_ROOT_PATH"
    exit 1
fi

STORE_PATH=$(readlink -f "$GC_ROOT_PATH")
echo "SUCCESS: Persistent GC Root created"
echo "  Symlink: $GC_ROOT_PATH"
echo "  Points to: $STORE_PATH"
echo "  To allow garbage collection later, run: rm $GC_ROOT_PATH"

echo -e "\n=== STEP 3: Verify GC root is registered ==="
if nix-store --gc --print-roots | grep -q "$GC_ROOT_PATH"; then
    echo "GC root is properly registered with Nix"
else
    echo "WARNING: GC root may not be properly registered"
fi

echo -e "\n=== STEP 4: Enter Interactive Nix Shell ==="

# Resolve the GC Root Symlink to the actual Nix Store Path
if [ ! -L "$GC_ROOT_PATH" ]; then
    echo "ERROR: GC Root symlink not found at $GC_ROOT_PATH."
    exit 1
fi

NIX_STORE_PATH=$(readlink "$GC_ROOT_PATH")

# Prepare the environment file
export TMPDIR="/tmp"
ENV_SCRIPT="$TMPDIR/nix-env-$(date +%s).sh"
tail -n +5 "$NIX_STORE_PATH" > "$ENV_SCRIPT"

# Source the environment
echo "Activating Nix environment..."
USER_HOME="$HOME"
USER_ACTUAL_SHELL="$SHELL"
USER_PATH="$PATH"  # Save user PATH before Nix overwrites it (includes nvm, homebrew, etc.)

source "$ENV_SCRIPT"
export IN_NIX_SHELL=impure

# Restore HOME and user PATH (includes nvm, homebrew, claude CLI, etc.)
export HOME="$USER_HOME"
export PATH="$PATH:$USER_PATH"

rm -f "$ENV_SCRIPT"

# Run the shell hook
if [ -n "$shellHook" ]; then
    eval "$shellHook"
fi

# Re-export critical variables
export NIXPKGS_ALLOW_BROKEN=1
export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
export NIXPKGS_ALLOW_UNFREE=1
export GITHUB_PAT="$GITHUB_PAT"
export RIX_NIX_SHELL_ROOT="$GC_ROOT_PATH"

echo -e "\n=============================================="
echo "CoMMpass Analysis Environment Ready"
echo "=============================================="
echo ""
echo "Quick start:"
echo "  R                                    # Start R"
echo "  aws s3 ls --no-sign-request \\       # List CoMMpass S3 bucket"
echo "    s3://gdc-mmrf-commpass-phs000748-2-open/"
echo ""
echo "In R:"
echo "  library(TCGAbiolinks)"
echo "  query <- GDCquery(project='MMRF-COMMPASS', ...)"
echo ""

# Reset TMPDIR before shell
unset TMPDIR

# Launch interactive shell
if [[ "$USER_ACTUAL_SHELL" == *"zsh"* ]]; then
    NIX_ZDOTDIR="$HOME/.nix-shell-zdotdir"
    mkdir -p "$NIX_ZDOTDIR"
    export NIX_SHELL_PATH_SAVED="$PATH"

    cat > "$NIX_ZDOTDIR/.zshenv" <<'ZSHENV'
if [ -n "$NIX_SHELL_PATH_SAVED" ]; then
    export PATH="$NIX_SHELL_PATH_SAVED"
fi
export IN_NIX_SHELL=impure
ZSHENV

    cat > "$NIX_ZDOTDIR/.zshrc" <<'ZSHRC'
[ -f ~/.zshrc ] && source ~/.zshrc
if [ -n "$NIX_SHELL_PATH_SAVED" ]; then
    export PATH="$NIX_SHELL_PATH_SAVED"
fi
export IN_NIX_SHELL=impure
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char
ZSHRC
    export ZDOTDIR="$NIX_ZDOTDIR"
    exec $USER_ACTUAL_SHELL -i
elif [[ "$USER_ACTUAL_SHELL" == *"bash"* ]]; then
    exec $USER_ACTUAL_SHELL -i
else
    exec $SHELL -i
fi

echo -e "\n=== Exited CoMMpass Nix shell ==="
echo "GC root still active at: $GC_ROOT_PATH"
