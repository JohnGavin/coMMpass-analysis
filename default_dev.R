# Generate comprehensive Nix environment for CoMMpass analysis
library(rix)
source("R/dev/nix/packages.R")

# Combine all packages
r_pkgs <- c(
  cran_packages,
  # Additional dev tools
  "duckdb", "dbplyr", "usethis", "gert", "gh",
  "pkgdown", "styler", "spelling"
) |> unique() |> sort()

bioc_pkgs <- bioc_packages |> unique() |> sort()

# GitHub packages (will be handled separately if needed)
gh_pkgs <- list()  # Start without GitHub packages for stability

# System packages - comprehensive list for all dependencies
system_pkgs <- c(
  system_packages,
  # Additional system tools
  "locale", "direnv", "jq", "curlMinimal", "curl",
  "nano", "duckdb", "tree", "bc", "htop", "btop",
  "cacert", "gh", "git", "gnupg", "toybox", "gettext",
  "pandoc", "less", "unzip", "libiconv", "gcc",
  "libgcc", "clang"
) |> unique() |> sort()

# Shell hook for environment initialization
shell_hook <- '
export R_MAKEVARS_USER=/dev/null
export HDF5_USE_FILE_LOCKING=FALSE
export OPENBLAS_NUM_THREADS=1
printf "🔬 CoMMpass Multiple Myeloma Analysis Environment Ready\n"
printf "📊 Packages loaded: %d CRAN + %d Bioconductor\n" \
  "$(echo ${#r_pkgs[@]})" "$(echo ${#bioc_pkgs[@]})"
'

message("==============================================")
message("Generating comprehensive Nix environment...")
message("==============================================")
message("CRAN packages: ", length(r_pkgs))
message("Bioconductor packages: ", length(bioc_pkgs))
message("System packages: ", length(system_pkgs))
message("==============================================")

# Generate the Nix configuration
rix::rix(
  r_ver = "4.5.2",  # Use latest stable R version
  project_path = ".",
  overwrite = TRUE,
  r_pkgs = c(r_pkgs, bioc_pkgs),
  system_pkgs = system_pkgs,
  git_pkgs = gh_pkgs,
  ide = "none",
  shell_hook = shell_hook
)

# Rename to default_dev.nix
if (file.exists("default.nix")) {
  file.rename("default.nix", "default_dev.nix")
  message("✅ Created default_dev.nix")

  # Also export package summary
  export_package_lists()
}

message("==============================================")
message("Next steps:")
message("1. Run: chmod +x default_dev.sh")
message("2. Run: ./default_dev.sh to enter Nix environment")
message("3. The first run will download packages (~10-20 min)")
message("4. Subsequent runs will be fast (~5 seconds)")
message("==============================================")