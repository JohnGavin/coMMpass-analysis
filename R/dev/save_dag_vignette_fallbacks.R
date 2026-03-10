# R/dev/save_dag_vignette_fallbacks.R
# Save pre-computed targets as RDS for pkgdown vignette fallback.
# Run interactively AFTER tar_make() builds these targets:
#   source("R/dev/save_dag_vignette_fallbacks.R")

library(targets)

targets_to_save <- c(
  "vig_pipeline_dag",
  "dag_layer_validation",
  "vig_git_changelog"
)

out_dir <- here::here("inst/extdata/vignettes")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

for (nm in targets_to_save) {
  val <- tryCatch(
    targets::tar_read_raw(nm),
    error = function(e) {
      cli::cli_alert_danger("Failed to read target {.val {nm}}: {e$message}")
      NULL
    }
  )
  if (is.null(val)) next

  path <- file.path(out_dir, paste0(nm, ".rds"))
  saveRDS(val, path, compress = "xz")
  sz <- round(file.size(path) / 1024, 1)
  cli::cli_alert_success("Saved {.val {nm}} -> {.file {path}} ({sz} KB)")
}

cli::cli_alert_info("Done. Commit the RDS files in {.file {out_dir}}")
