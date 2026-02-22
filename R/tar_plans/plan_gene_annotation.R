# R/tar_plans/plan_gene_annotation.R
# Gene annotation and enrichment visualization targets

plan_gene_annotation <- list(
  # Gene annotation mapping (Ensembl -> symbol + Entrez)
  tar_target(
    gene_annotation,
    {
      # Get all unique gene IDs from DE results
      all_genes <- character(0)
      if (!is.null(deseq2_results$results_table)) {
        all_genes <- c(all_genes, rownames(deseq2_results$results_table))
      }
      all_genes <- unique(sub("\\.\\d+$", "", all_genes))
      annotate_genes(all_genes)
    }
  ),

  # Annotated DE results (with gene symbols)
  tar_target(
    de_results_annotated,
    {
      tbl <- deseq2_results$results_table
      if (is.null(tbl) || nrow(tbl) == 0) return(data.frame())
      # Use shrunken results if available
      if (!is.null(deseq2_results$results_shrunk)) {
        tbl <- deseq2_results$results_shrunk
      }
      annotate_de_results(tbl, gene_annotation)
    }
  ),

  # Pre-computed enrichment dot plot data (from GSEA Hallmark)
  tar_target(
    enrichment_dotplot_data,
    {
      if (is.null(gsea_hallmark) || gsea_hallmark$n_gene_sets == 0) {
        return(data.frame())
      }
      gsea_hallmark$top_gene_sets
    }
  ),

  # Pre-computed enrichment bar plot data (from ORA)
  tar_target(
    enrichment_barplot_data,
    {
      if (is.null(ora_hallmark) || is.null(ora_hallmark$results) ||
          nrow(ora_hallmark$results) == 0) {
        return(data.frame())
      }
      ora_hallmark$results
    }
  )
)
