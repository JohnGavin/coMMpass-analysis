# R/dev/create_msigdb_data.R
# One-time dev script: generate local MSigDB gene set parquet files
#
# PURPOSE: The msigdbr package has a broken sha256 in rstats-on-nix (upstream
# bug). This script creates pre-converted gene set parquets so the pipeline can
# run without msigdbr at runtime.
#
# USAGE: Install msigdbr to a temp library, then run:
#   tmp_lib <- tempfile(); dir.create(tmp_lib)
#   R CMD INSTALL --library=tmp_lib <msigdbr tarball>
#   Rscript R/dev/create_msigdb_data.R
#
# OUTPUT:
#   inst/extdata/msigdb/hallmark_ensembl.parquet  (50 pathways, ~42 KB)
#   inst/extdata/msigdb/kegg_ensembl.parquet      (658 pathways, ~43 KB)

if (!requireNamespace("msigdbr", quietly = TRUE)) {
  stop(
    "msigdbr is not available. Install to a temp library:\n",
    "  R CMD INSTALL --library=/tmp/msigdbr_lib msigdbr_*.tar.gz\n",
    "Then re-run with: Rscript -e 'library(msigdbr, lib.loc=\"/tmp/msigdbr_lib\")' R/dev/create_msigdb_data.R"
  )
}

if (!requireNamespace("arrow", quietly = TRUE)) {
  stop("Package 'arrow' is required for parquet output")
}

out_dir <- "inst/extdata/msigdb"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

convert_collection <- function(category, subcategory = NULL, filename) {
  args <- list(species = "Homo sapiens", category = category)
  if (!is.null(subcategory)) args$subcategory <- subcategory
  df <- do.call(msigdbr::msigdbr, args)

  gene_sets <- split(df$ensembl_gene, df$gs_name)
  gene_sets <- lapply(gene_sets, function(x) {
    unique(x[!is.na(x) & nchar(x) > 0])
  })
  gene_sets <- gene_sets[vapply(gene_sets, length, integer(1)) > 0]

  # Long-format data frame for parquet storage
  pq_df <- data.frame(
    gs_name = rep(names(gene_sets), vapply(gene_sets, length, integer(1))),
    ensembl_gene = unlist(gene_sets, use.names = FALSE),
    stringsAsFactors = FALSE
  )

  out_path <- file.path(out_dir, filename)
  arrow::write_parquet(pq_df, out_path)
  message(
    sprintf("Saved %d gene sets (%d rows) to %s (%.1f KB)",
            length(gene_sets), nrow(pq_df), out_path, file.size(out_path) / 1024)
  )
}

message("Fetching MSigDB Hallmark gene sets...")
convert_collection("H", NULL, "hallmark_ensembl.parquet")

message("Fetching MSigDB KEGG gene sets...")
convert_collection("C2", "CP:KEGG_MEDICUS", "kegg_ensembl.parquet")

message("Done. Commit the parquet files to inst/extdata/msigdb/")
