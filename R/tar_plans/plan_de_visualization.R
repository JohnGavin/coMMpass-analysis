# R/tar_plans/plan_de_visualization.R
# Pre-computed DE visualization data targets
# These produce data consumed by the differential-expression vignette

plan_de_visualization <- list(
  # VST-transformed expression for PCA and heatmaps
  tar_target(
    vst_counts,
    run_vst(filtered_data, blind = TRUE)
  ),

  # PCA from VST data with clinical metadata
  tar_target(
    pca_data,
    {
      if (is.null(vst_counts)) {
        list(coords = data.frame(), var_explained = numeric(0),
             n_genes_used = 0L)
      } else {
        vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")
        meta <- as.data.frame(SummarizedExperiment::colData(vst_counts))
        compute_pca(vst_mat, n_top = 500L, metadata = meta)
      }
    }
  ),

  # Pre-formatted volcano plot data (from DESeq2 results)
  tar_target(
    volcano_plot_data,
    {
      tbl <- deseq2_results$results_table
      if (is.null(tbl) || nrow(tbl) == 0) return(data.frame())
      # Use shrunken results if available
      if (!is.null(deseq2_results$results_shrunk)) {
        tbl <- deseq2_results$results_shrunk
      }
      tbl$gene <- rownames(tbl)
      tbl
    }
  ),

  # Pre-formatted MA plot data
  tar_target(
    ma_plot_data,
    {
      tbl <- deseq2_results$results_table
      if (is.null(tbl) || nrow(tbl) == 0) return(data.frame())
      tbl$gene <- rownames(tbl)
      tbl
    }
  ),

  # Top DE genes expression matrix for heatmap
  tar_target(
    top_de_heatmap_data,
    {
      tbl <- deseq2_results$results_table
      if (is.null(tbl) || nrow(tbl) == 0 || is.null(vst_counts)) {
        return(list(expr_matrix = NULL, de_results = NULL))
      }
      vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")
      list(
        expr_matrix = vst_mat,
        de_results = tbl
      )
    }
  ),

  # Method comparison summary table
  tar_target(
    de_method_summary,
    summarize_de_methods(
      list(
        DESeq2 = deseq2_results,
        edgeR = edger_results,
        limma = limma_results
      ),
      padj_threshold = 0.05,
      lfc_threshold = 1
    )
  )
)
