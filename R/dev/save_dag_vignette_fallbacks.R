# R/dev/save_dag_vignette_fallbacks.R
# Save pre-computed target DATA (not widgets) as RDS for pkgdown vignette fallback.
# Widgets contain system-specific paths and aren't portable.
# Run interactively AFTER tar_make() builds these targets:
#   source("R/dev/save_dag_vignette_fallbacks.R")

library(targets)

out_dir <- here::here("inst/extdata/vignettes")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# --- dag_layer_validation: extract data frame from DT widget ---
val <- tryCatch(targets::tar_read(dag_layer_validation), error = function(e) NULL)
if (!is.null(val)) {
  data <- if (inherits(val, "datatables")) val$x$data else val
  path <- file.path(out_dir, "dag_layer_validation.rds")
  saveRDS(data, path, compress = "xz")
  cli::cli_alert_success("Saved dag_layer_validation data ({nrow(data)} rows) -> {.file {path}}")
}

# --- vig_pipeline_dag: extract nodes/edges from visNetwork widget ---
val <- tryCatch(targets::tar_read(vig_pipeline_dag), error = function(e) NULL)
if (!is.null(val)) {
  data <- if (inherits(val, "visNetwork")) {
    list(nodes = val$x$nodes, edges = val$x$edges, main = val$x$main)
  } else {
    val
  }
  path <- file.path(out_dir, "vig_pipeline_dag.rds")
  saveRDS(data, path, compress = "xz")
  n_nodes <- if (is.data.frame(data$nodes)) nrow(data$nodes) else "?"
  cli::cli_alert_success("Saved vig_pipeline_dag data ({n_nodes} nodes) -> {.file {path}}")
}

# --- vig_git_changelog: extract data frame from DT widget ---
val <- tryCatch(targets::tar_read(vig_git_changelog), error = function(e) NULL)
if (!is.null(val)) {
  data <- if (inherits(val, "datatables")) val$x$data else val
  path <- file.path(out_dir, "vig_git_changelog.rds")
  saveRDS(data, path, compress = "xz")
  cli::cli_alert_success("Saved vig_git_changelog data ({nrow(data)} rows) -> {.file {path}}")
}

cli::cli_alert_info("Done. Commit the RDS files in {.file {out_dir}}")
