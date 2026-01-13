# =============================================================================
# CoMMpass Multiple Myeloma Analysis - Nix Environment Configuration
# =============================================================================
#
# This file generates default_dev.nix using the rix package for reproducible
# analysis of MMRF CoMMpass (Clinical Outcomes in MM to Personal Assessment
# of Genetic Profile) study data.
#
# USAGE:
#   ./default.sh    # Generates default_dev.nix and enters nix-shell
#
# DOCUMENTATION:
#   - Package list: R/dev/nix/packages.R
#   - Analysis plan: PLAN_CoMMpass_Analysis.md
#
# =============================================================================

library(rix)

# Source package definitions from packages.R
source("R/dev/nix/packages.R")

# =============================================================================
# CRAN Packages - CoMMpass Analysis
# =============================================================================
# Uses definitions from packages.R plus additional dev packages

r_pkgs <- c(
  cran_packages,  # From packages.R

  # --- Additional Development Packages ---
  "duckdb",             # SQL on files (JSON/CSV/Parquet)
  "dbplyr",             # dplyr backend for databases
  "mirai",              # Async evaluation
  "nanonext",           # Low-level async sockets
  "usethis",            # Package development helpers
  "gert",               # Git operations
  "gh",                 # GitHub API
  "pkgdown",            # Package documentation site
  "styler",             # Code formatting
  "air",                # Air formatter
  "spelling",           # Spell checking
  "rix"                 # For nix-shell --pure operations
) |>
  unique() |>
  sort()

# Spot check for critical packages
pkgs_test <- c("usethis", "devtools", "gh", "gert", "logger", "dplyr",
               "duckdb", "targets", "survival", "survminer", "Seurat",
               "aws.s3", "testthat")
pkgs_missing <- pkgs_test[!(pkgs_test %in% r_pkgs)]
if (length(pkgs_missing)) {
  cli::cli_alert_warning(paste("Missing critical packages:", paste(pkgs_missing, collapse = ", ")))
}

# =============================================================================
# Bioconductor Packages
# =============================================================================
# Uses definitions from packages.R

bioc_pkgs <- bioc_packages  # From packages.R

# =============================================================================
# GitHub Packages
# =============================================================================
# Uses definitions from packages.R

gh_pkgs <- git_packages  # From packages.R

# =============================================================================
# System Packages (Nix)
# =============================================================================
# Combines definitions from packages.R with additional tools

Sys.setenv("NIXPKGS_ALLOW_UNFREE" = 1)

system_pkgs <- c(
  system_packages,        # From packages.R (jags, hdf5, gsl, etc.)

  # --- Additional CLI Tools ---
  "locale", "direnv", "jq",
  "curlMinimal",
  "curl",
  "nano",
  "duckdb", "tree",
  "awscli2",              # AWS CLI for S3 access to CoMMpass data
  "bc",                   # Calculator
  "htop", "btop",
  "cacert",               # CA certs / trusted TLS/SSL root certs
  "gh", "git",
  "gnupg",
  "toybox",               # coreutils for nix-shell --pure
  "gettext",              # Translation tools
  "quarto", "pandoc",
  "texliveBasic",         # For vignettes
  "less",                 # Pager
  "unzip",
  "libiconv",
  "gcc", "libgcc",
  "clang"
) |>
  unique() |>
  sort()

# =============================================================================
# Shell Hook
# =============================================================================

shell_hook <- r"(
# =============================================================================
# CoMMpass Analysis Environment - Shell Hook
# =============================================================================

valid_home=1
case $HOME in
  ''|*'$'*) valid_home=0 ;;
  /*) ;;
  *) valid_home=0 ;;
esac

user_ok=0
case $USER in
  ''|*'$'*) user_ok=0 ;;
  *) if [ -d /Users/$USER ]; then user_ok=1; fi ;;
esac

if [ $valid_home -ne 1 ] && [ $user_ok -eq 1 ]; then
  HOME=/Users/$USER
  export HOME
  valid_home=1
fi

if [ $valid_home -ne 1 ]; then
  printf '%s\n' 'Skipping environment setup due to invalid HOME.'
else
  # Disable user Makevars to prevent Homebrew path conflicts
  export R_MAKEVARS_USER=/dev/null

  # Set up AWS credentials location (if using AWS for CoMMpass data)
  export AWS_SHARED_CREDENTIALS_FILE=$HOME/.aws/credentials
  export AWS_CONFIG_FILE=$HOME/.aws/config

  printf '%s\n' '=== CoMMpass Analysis Environment ==='
  printf '%s\n' 'Data access options:'
  printf '%s\n' '  1. AWS S3: aws s3 ls --no-sign-request s3://gdc-mmrf-commpass-phs000748-2-open/'
  printf '%s\n' '  2. GDC API: TCGAbiolinks::GDCquery(project=MMRF-COMMPASS)'
  printf '%s\n' '  3. MMRF-RG: Register at research.themmrf.org'
  printf '%s\n' ''
fi

unset CI
printf '%s\n' 'CoMMpass environment ready.'
)"

# =============================================================================
# Generate Nix Environment
# =============================================================================

cli::cli_alert_info("Generating default_dev.nix...")

(latest <- "2024-12-14")

rix::rix(
  date = latest,
  project_path = ".",
  overwrite = TRUE,
  r_pkgs = c(r_pkgs, bioc_pkgs),
  system_pkgs = system_pkgs,
  git_pkgs = gh_pkgs,
  ide = "none",
  shell_hook = shell_hook
)

# Rename to default_dev.nix to avoid confusion with other projects
if (file.exists("default.nix")) {
  file.rename("default.nix", "default_dev.nix")
  cli::cli_alert_success("Created default_dev.nix")
} else {
  cli::cli_alert_danger("Failed to create default.nix")
}

cli::cli_alert_info("R script finished.")
cli::cli_alert_info("Run: nix-shell default_dev.nix")
