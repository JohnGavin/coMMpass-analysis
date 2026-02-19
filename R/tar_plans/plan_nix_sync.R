# plan_nix_sync.R
# Drift detection: DESCRIPTION deps vs default.nix rpkgs
#
# Targets:
#   nix_desc_file       - tracks DESCRIPTION as file dependency
#   nix_desc_deps       - extracts deps via get_description_deps()
#   nix_sync_check      - compares DESCRIPTION deps vs default.nix, warns on drift

plan_nix_sync <- list(
  targets::tar_target(
    nix_desc_file,
    "DESCRIPTION",
    format = "file"
  ),

  targets::tar_target(
    nix_desc_deps,
    get_description_deps(nix_desc_file)
  ),

  targets::tar_target(
    nix_sync_check,
    {
      nix_path <- "default.nix"
      if (!file.exists(nix_path)) {
        cli::cli_warn(c(
          "!" = "default.nix not found -- skipping drift check.",
          "i" = "Run {.code Rscript default.R} to generate it."
        ))
        return(list(
          synced = NA, missing_from_nix = character(),
          timestamp = Sys.time()
        ))
      }
      nix_content <- readLines(nix_path, warn = FALSE)
      # Extract R package names from default.nix rpkgs list
      rpkg_lines <- grep("r-[a-zA-Z]", nix_content, value = TRUE)
      nix_pkgs <- gsub(".*r-([a-zA-Z0-9_.]+).*", "\\1", rpkg_lines)
      # Normalize: nix uses dots where R uses dots
      nix_pkgs <- unique(nix_pkgs[nzchar(nix_pkgs)])

      # Normalize DESCRIPTION deps for comparison
      desc_normalized <- tolower(gsub("\\.", "", nix_desc_deps))
      nix_normalized <- tolower(gsub("\\.", "", nix_pkgs))

      missing <- nix_desc_deps[!desc_normalized %in% nix_normalized]

      if (length(missing) > 0) {
        cli::cli_warn(c(
          "!" = "DESCRIPTION -> Nix drift detected!",
          "i" = "Packages in DESCRIPTION but not in default.nix:",
          " " = "{.pkg {missing}}",
          "i" = "Run {.code Rscript default.R} to regenerate."
        ))
      } else {
        cli::cli_alert_success("DESCRIPTION and default.nix are in sync.")
      }

      list(
        synced = length(missing) == 0,
        missing_from_nix = missing,
        desc_count = length(nix_desc_deps),
        nix_count = length(nix_pkgs),
        timestamp = Sys.time()
      )
    }
  )
)
