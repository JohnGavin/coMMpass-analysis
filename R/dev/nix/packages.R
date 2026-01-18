# Simplified Package Definitions for initial Data Acquisition
# Full list preserved in PLAN_CoMMpass_Analysis.md

cran_packages <- c(
  "dplyr", "tidyr", "ggplot2", "readr", "purrr", "tibble", "stringr", "forcats", # tidyverse core
  "logger", "here", "fs", "glue", "tictoc",
  "aws.s3", "aws.signature",
  "devtools", "usethis", "testthat", "remotes",
  "targets", "tarchetypes"
)

bioc_packages <- c(
  "TCGAbiolinks", "GenomicDataCommons", "SummarizedExperiment"
)

git_packages <- list()

system_packages <- c(
  "curl", "openssl", "libxml2", "glpk", "zlib"
)

generate_nix_env <- function(
    project_path = here::here(),
    r_version = "4.4.1",
    ide = "none"
) {
  rix::rix(
    r_ver = r_version,
    r_pkgs = c(cran_packages, bioc_packages),
    system_pkgs = system_packages,
    ide = ide,
    project_path = project_path,
    overwrite = TRUE
  )
}