# R/tar_plans/plan_gene_correlations.R
# Gene-gene correlation analysis targets

plan_gene_correlations <- list(

  # Correlate top DE genes with each other (batch)
  tar_target(
    gene_correlations,
    {
      if (is.null(vst_counts) || is.null(consensus_de_genes)) return(NULL)
      vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")

      # Top 10 consensus DE genes
      top_genes <- if (is.data.frame(consensus_de_genes)) {
        head(consensus_de_genes$gene, 10)
      } else if (is.character(consensus_de_genes)) {
        head(consensus_de_genes, 10)
      } else {
        return(NULL)
      }

      available <- intersect(top_genes, rownames(vst_mat))
      if (length(available) < 2) return(NULL)

      # Correlate first gene vs rest as an example
      correlate_genes_batch(
        vst_mat,
        target_gene = available[1],
        candidate_genes = available[-1],
        method = "pearson"
      )
    }
  )
)
