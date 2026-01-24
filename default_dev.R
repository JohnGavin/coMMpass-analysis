library(rix)
source("R/dev/nix/packages.R")

r_pkgs <- c(cran_packages, "duckdb", "dbplyr", "mirai", "nanonext", "usethis", "gert", "gh", "pkgdown", "styler", "air", "spelling") |> unique() |> sort()
bioc_pkgs <- bioc_packages
gh_pkgs <- list()

system_pkgs <- c(system_packages, "locale", "direnv", "jq", "curlMinimal", "curl", "nano", "duckdb", "tree", "bc", "htop", "btop", "cacert", "gh", "git", "gnupg", "toybox", "gettext", "pandoc", "less", "unzip", "libiconv", "gcc", "libgcc", "clang") |> unique() |> sort()

shell_hook <- "export R_MAKEVARS_USER=/dev/null\nprintf 'CoMMpass environment ready.\n'"

message("Generating default_dev.nix...")

rix::rix(
  r_ver = "4.5.2",  # Use stable R version
  project_path = ".",
  overwrite = TRUE,
  r_pkgs = c(r_pkgs, bioc_pkgs),
  system_pkgs = system_pkgs,
  git_pkgs = gh_pkgs,
  ide = "none",
  shell_hook = shell_hook
)

if (file.exists("default.nix")) {
  file.rename("default.nix", "default_dev.nix")
  message("Created default_dev.nix")
}
