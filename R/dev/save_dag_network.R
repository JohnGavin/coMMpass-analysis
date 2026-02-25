# R/dev/save_dag_network.R
# Pre-compute pipeline DAG network data for Shinylive embedding.
# Run interactively (NOT inside tar_make):
#   source("R/dev/save_dag_network.R")

library(targets)
library(jsonlite)

net <- targets::tar_network(targets_only = TRUE)
meta <- tryCatch(
  targets::tar_meta(fields = c("seconds", "bytes", "warnings", "errors")),
  error = function(e) {
    cli::cli_alert_warning("tar_meta() failed: {e$message}")
    NULL
  }
)

out <- list(
  nodes = net$vertices,
  edges = net$edges,
  meta = if (!is.null(meta)) meta else data.frame()
)

out_path <- here::here("inst/shinylive/data/pipeline_network.json")
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
jsonlite::write_json(out, out_path, pretty = TRUE, auto_unbox = TRUE)
cli::cli_alert_success("Saved DAG network to {out_path}")
cli::cli_alert_info("Nodes: {nrow(out$nodes)}, Edges: {nrow(out$edges)}")
